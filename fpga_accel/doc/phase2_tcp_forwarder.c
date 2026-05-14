/*
 * phase2_tcp_forwarder.c
 *
 * Zynq PS Linux 用户态进程：从 AXI-DMA S2MM 读取 emeye_accel 幅度帧，
 * 通过 TCP socket 发到 Host PC。
 *
 * 目标平台: Zynq-7010 (xc7z010clg400-2), Linux 4.14+, ARM Cortex-A9
 *
 * 编译:
 *   arm-linux-gnueabihf-gcc -O2 -static -Wall -o tcp_forwarder phase2_tcp_forwarder.c
 *
 * 运行:
 *   ./tcp_forwarder --port 5555 --buf-mb 8 --uio-dev /dev/uio0 \
 *                  --dma-addr 0x1C000000
 *
 * [待验证] UIO 设备路径、DMA 物理地址必须按实际 Vivado BD 地址分配修改。
 * 寄存器偏移来自 Xilinx PG021 AXI-DMA v7.1 (Table 2-6, S2MM 通道寄存器)。
 *
 * 协议格式 (32-bit little-endian, 与 simulation/network_demo.py 兼容):
 *   bit[31]    : ch_id        (0=RX1, 1=RX2)
 *   bit[30:15] : frame_idx    (16-bit 帧序号)
 *   bit[14]    : frame_start  (1=本帧第一个样本)
 *   bit[11:0]  : magnitude    (12-bit 幅度)
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <fcntl.h>
#include <getopt.h>

#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/types.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

/* ─────────────────────────────────────────────────────────────────
 * AXI-DMA 寄存器偏移 (PG021 Table 2-6, S2MM 通道)
 * 基地址通过 --dma-addr 参数传入（对应 UIO map0 基址）
 * ──────────────────────────────────────────────────────────────── */
#define S2MM_DMACR   0x30   /* S2MM DMA Control Register            */
#define S2MM_DMASR   0x34   /* S2MM DMA Status Register             */
#define S2MM_DA      0x48   /* S2MM Destination Address (低 32-bit) */
#define S2MM_LENGTH  0x58   /* S2MM Buffer Length (写入触发传输)    */

/* DMACR bit 定义 (PG021 Table 2-7) */
#define DMACR_RS        (1 << 0)   /* Run/Stop: 1=Run                    */
#define DMACR_RESET     (1 << 2)   /* Soft Reset (写 1 触发, 自动清零)   */
#define DMACR_IOC_IRQ_EN (1 << 12) /* 使能 IOC (传输完成) 中断           */

/* DMASR bit 定义 (PG021 Table 2-8) */
#define DMASR_HALTED    (1 << 0)   /* 1=DMA 已停止                       */
#define DMASR_IDLE      (1 << 1)   /* 1=S2MM 空闲 (无传输进行中)         */
#define DMASR_IOC_IRQ   (1 << 12)  /* 传输完成中断标志 (写 1 清除)       */
#define DMASR_ERR_IRQ   (1 << 14)  /* 错误中断标志                       */

/* ─────────────────────────────────────────────────────────────────
 * Ring buffer 参数
 * ──────────────────────────────────────────────────────────────── */
#define DEFAULT_BUF_MB   8                          /* 默认 ring buffer 总大小 */
#define HALF_WORDS(mb)   (((mb) * 1024 * 1024) / 2 / 4)  /* 每半 buffer 的 word 数 */

/* ─────────────────────────────────────────────────────────────────
 * 全局状态
 * ──────────────────────────────────────────────────────────────── */
static volatile int g_running = 1;

static int        g_uio_fd   = -1;
static int        g_listen_fd = -1;
static int        g_client_fd = -1;
static void      *g_reg_base  = MAP_FAILED;   /* UIO map0: DMA 控制寄存器 */
static uint32_t  *g_dma_buf   = MAP_FAILED;   /* UIO map1: DMA 数据缓冲区 [待验证] */
static size_t     g_buf_bytes = 0;

/* ─────────────────────────────────────────────────────────────────
 * 辅助函数
 * ──────────────────────────────────────────────────────────────── */

static inline void reg_write(uint32_t offset, uint32_t val) {
    volatile uint32_t *p = (volatile uint32_t *)((uint8_t *)g_reg_base + offset);
    *p = val;
}

static inline uint32_t reg_read(uint32_t offset) {
    volatile uint32_t *p = (volatile uint32_t *)((uint8_t *)g_reg_base + offset);
    return *p;
}

/* 轮询等待 DMASR 的 mask 位变成期望值，超时返回 -1 */
static int dma_wait_status(uint32_t mask, uint32_t expected, int timeout_ms) {
    int elapsed = 0;
    while (elapsed < timeout_ms) {
        uint32_t sr = reg_read(S2MM_DMASR);
        if ((sr & mask) == expected)
            return 0;
        usleep(1000);
        elapsed++;
    }
    return -1;  /* 超时 */
}

/* S2MM 软复位 (PG021 §2.3: 写 DMACR[2]=1, 等待归零) */
static int dma_s2mm_reset(void) {
    reg_write(S2MM_DMACR, DMACR_RESET);
    /* 最多等 100 ms */
    for (int i = 0; i < 100; i++) {
        if (!(reg_read(S2MM_DMACR) & DMACR_RESET))
            return 0;
        usleep(1000);
    }
    fprintf(stderr, "[dma] S2MM reset timeout\n");
    return -1;
}

/* 启动一次 S2MM 传输：把数据从 AXI-Stream 写到物理地址 phys_addr，长度 len_bytes */
static void dma_s2mm_start(uint32_t phys_addr, uint32_t len_bytes) {
    /* 1. Run */
    reg_write(S2MM_DMACR, DMACR_RS | DMACR_IOC_IRQ_EN);
    /* 2. 目标地址 */
    reg_write(S2MM_DA, phys_addr);
    /* 3. 写 LENGTH 触发传输 (PG021: 写 LENGTH 后 DMA 开始搬数据) */
    reg_write(S2MM_LENGTH, len_bytes);
}

/* 等待 S2MM 传输完成 (轮询 IOC_IRQ 位)，完成后清中断标志 */
static int dma_s2mm_wait_done(int timeout_ms) {
    if (dma_wait_status(DMASR_IOC_IRQ, DMASR_IOC_IRQ, timeout_ms) < 0) {
        fprintf(stderr, "[dma] S2MM wait timeout, DMASR=0x%08x\n",
                reg_read(S2MM_DMASR));
        return -1;
    }
    /* 清 IOC 标志 (写 1 清零，PG021 §2.3) */
    reg_write(S2MM_DMASR, DMASR_IOC_IRQ);
    return 0;
}

static void signal_handler(int sig) {
    (void)sig;
    g_running = 0;
}

static void cleanup(void) {
    if (g_client_fd >= 0) { close(g_client_fd); g_client_fd = -1; }
    if (g_listen_fd >= 0) { close(g_listen_fd); g_listen_fd = -1; }
    if (g_reg_base  != MAP_FAILED) {
        munmap(g_reg_base, 4096);
        g_reg_base = MAP_FAILED;
    }
    if (g_dma_buf != MAP_FAILED) {
        munmap(g_dma_buf, g_buf_bytes);
        g_dma_buf = MAP_FAILED;
    }
    if (g_uio_fd >= 0) { close(g_uio_fd); g_uio_fd = -1; }
    printf("[tcp_forwarder] 清理完成，退出\n");
}

static void usage(const char *prog) {
    fprintf(stderr,
        "用法: %s [选项]\n"
        "  --port      <端口号>   TCP 监听端口 (默认 5555)\n"
        "  --buf-mb    <MB>       DMA ring buffer 大小，MB (默认 8)\n"
        "  --uio-dev   <路径>     UIO 设备节点 (默认 /dev/uio0)\n"
        "  --dma-addr  <十六进制> DMA buffer 物理基地址 (默认 0x1C000000)\n"
        "  --help                 显示此帮助\n"
        "\n"
        "[待验证] --uio-dev 和 --dma-addr 必须按实际板子设备树修改\n",
        prog);
}

/* ─────────────────────────────────────────────────────────────────
 * main
 * ──────────────────────────────────────────────────────────────── */
int main(int argc, char *argv[]) {
    /* ── 参数解析 ── */
    int         port      = 5555;
    int         buf_mb    = DEFAULT_BUF_MB;
    const char *uio_dev   = "/dev/uio0";
    uint32_t    dma_phys  = 0x1C000000;  /* [待验证] 占位符 */

    static struct option long_opts[] = {
        {"port",     required_argument, 0, 'p'},
        {"buf-mb",   required_argument, 0, 'b'},
        {"uio-dev",  required_argument, 0, 'u'},
        {"dma-addr", required_argument, 0, 'd'},
        {"help",     no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };
    int opt;
    while ((opt = getopt_long(argc, argv, "p:b:u:d:h", long_opts, NULL)) != -1) {
        switch (opt) {
        case 'p': port    = atoi(optarg);             break;
        case 'b': buf_mb  = atoi(optarg);             break;
        case 'u': uio_dev = optarg;                   break;
        case 'd': dma_phys = (uint32_t)strtoul(optarg, NULL, 0); break;
        case 'h': usage(argv[0]); return 0;
        default:  usage(argv[0]); return 1;
        }
    }

    /* ── 信号处理 ── */
    signal(SIGINT,  signal_handler);
    signal(SIGTERM, signal_handler);
    signal(SIGPIPE, SIG_IGN);  /* 防止客户端断开时 SIGPIPE 杀进程 */

    printf("[tcp_forwarder] 启动: port=%d buf=%dMB uio=%s dma_phys=0x%08x\n",
           port, buf_mb, uio_dev, dma_phys);

    /* ── 打开 UIO 设备 ── */
    g_uio_fd = open(uio_dev, O_RDWR);
    if (g_uio_fd < 0) {
        perror("[uio] open failed");
        fprintf(stderr, "      请确认设备树里 axi_dma_0 节点存在，驱动已加载\n");
        return 1;
    }

    /*
     * mmap map0: AXI-DMA 控制寄存器
     * UIO map0 对应 axi_dma 的 AXI-Lite 控制口 (4KB)
     * 偏移规则: /sys/class/uio/uio0/maps/map0/offset
     * PG021 §2.4: 控制寄存器基地址偏移 0x30 开始 (S2MM 通道)
     */
    g_reg_base = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                      MAP_SHARED, g_uio_fd, 0 * getpagesize());
    if (g_reg_base == MAP_FAILED) {
        perror("[uio] mmap control regs failed");
        cleanup();
        return 1;
    }

    /*
     * mmap map1: DMA 数据 buffer (物理地址 dma_phys，预留内存)
     * [待验证] UIO 是否有 map1 取决于设备树里是否给 DMA buffer 加了 uio-pdrv-genirq 节点
     * 备选方案: 用 /dev/mem + mmap(dma_phys) (需要 CONFIG_DEVMEM=y)
     *           或 Xilinx CMA 驱动 /dev/xdevcfg
     */
    g_buf_bytes = (size_t)buf_mb * 1024 * 1024;
    g_dma_buf = mmap(NULL, g_buf_bytes, PROT_READ | PROT_WRITE,
                     MAP_SHARED, g_uio_fd, 1 * getpagesize());
    if (g_dma_buf == MAP_FAILED) {
        /*
         * fallback: 尝试 /dev/mem 直接映射
         * [待验证] 生产环境应换成 dma-proxy 驱动，更安全
         */
        fprintf(stderr, "[uio] map1 失败，尝试 /dev/mem fallback...\n");
        int mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem_fd < 0) {
            perror("[mem] open /dev/mem failed");
            cleanup();
            return 1;
        }
        g_dma_buf = mmap(NULL, g_buf_bytes, PROT_READ | PROT_WRITE,
                         MAP_SHARED, mem_fd, (off_t)dma_phys);
        close(mem_fd);
        if (g_dma_buf == MAP_FAILED) {
            perror("[mem] mmap dma buffer failed");
            cleanup();
            return 1;
        }
    }

    /* ── DMA 初始化：软复位 ── */
    printf("[dma] S2MM 软复位...\n");
    if (dma_s2mm_reset() < 0) {
        cleanup();
        return 1;
    }
    printf("[dma] S2MM 就绪, DMASR=0x%08x\n", reg_read(S2MM_DMASR));

    /* ── TCP 监听 socket ── */
    g_listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (g_listen_fd < 0) { perror("socket"); cleanup(); return 1; }

    int reuse = 1;
    setsockopt(g_listen_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    struct sockaddr_in srv_addr = {
        .sin_family      = AF_INET,
        .sin_port        = htons((uint16_t)port),
        .sin_addr.s_addr = INADDR_ANY,
    };
    if (bind(g_listen_fd, (struct sockaddr *)&srv_addr, sizeof(srv_addr)) < 0) {
        perror("bind"); cleanup(); return 1;
    }
    listen(g_listen_fd, 1);
    printf("[tcp] 等待客户端连接 port=%d ...\n", port);

    /* ── 主循环（每次接受一个客户端连接） ── */
    while (g_running) {
        struct sockaddr_in cli_addr;
        socklen_t cli_len = sizeof(cli_addr);
        g_client_fd = accept(g_listen_fd, (struct sockaddr *)&cli_addr, &cli_len);
        if (g_client_fd < 0) {
            if (!g_running) break;
            perror("accept");
            continue;
        }
        printf("[tcp] 客户端连接: %s:%d\n",
               inet_ntoa(cli_addr.sin_addr), ntohs(cli_addr.sin_port));

        /* TCP 调优 */
        int flag = 1;
        /* TCP_NODELAY: 禁用 Nagle 算法，减少小包延迟 */
        setsockopt(g_client_fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));
        /* SO_SNDBUF: 发送缓冲区调大到 4 MB，防止 ethernet 阻塞时 DMA 积压 */
        int sndbuf = 4 * 1024 * 1024;
        setsockopt(g_client_fd, SOL_SOCKET, SO_SNDBUF, &sndbuf, sizeof(sndbuf));

        /*
         * Double-buffer (ping-pong) 策略:
         *   g_dma_buf[0 .. half-1]     = 缓冲区 A (前半)
         *   g_dma_buf[half .. end-1]   = 缓冲区 B (后半)
         *
         * 循环:
         *   1. DMA 写缓冲区 A  (在后台填充)
         *   2. 同时 socket 发送上一轮填好的缓冲区 B
         *   3. 等 DMA A 完成
         *   4. 交换 A/B，继续
         *
         * [待验证] DMA 实际能否做到"写 A 的同时发 B"取决于 AXI-DMA 是否支持
         * 双 BD (Buffer Descriptor)。在 simple 模式 (无 SG) 下，每次传输必须
         * 等完成后才能启动下一次，因此下面用顺序模式（发完再 DMA）作为保守实现。
         * 性能足够时（dec=1000 模式只有 64 KB/s）不需要真正并发。
         */

        size_t half_bytes = g_buf_bytes / 2;
        uint32_t phys_a   = dma_phys;
        uint32_t phys_b   = dma_phys + (uint32_t)half_bytes;
        uint8_t *virt_a   = (uint8_t *)g_dma_buf;
        uint8_t *virt_b   = (uint8_t *)g_dma_buf + half_bytes;

        uint32_t *active_phys = &phys_a;
        uint8_t  *active_virt = virt_a;

        /* 启动第一次 DMA 到缓冲区 A */
        dma_s2mm_start(*active_phys, (uint32_t)half_bytes);

        int connected = 1;
        while (g_running && connected) {
            /* 等 DMA 完成（当前缓冲区填满） */
            if (dma_s2mm_wait_done(5000) < 0) {
                fprintf(stderr, "[dma] 传输超时，检查 FIFO/emeye_accel 输出\n");
                break;
            }

            /* 立即启动下一次 DMA 到另一半 buffer（异步填充）*/
            uint8_t  *send_virt  = active_virt;
            size_t    send_bytes = half_bytes;

            /* 切换到另一半 */
            if (active_phys == &phys_a) {
                active_phys = &phys_b;
                active_virt = virt_b;
            } else {
                active_phys = &phys_a;
                active_virt = virt_a;
            }
            dma_s2mm_start(*active_phys, (uint32_t)half_bytes);

            /* 把刚填好的那半 buffer 发到 TCP */
            size_t sent = 0;
            while (sent < send_bytes && g_running) {
                ssize_t n = send(g_client_fd,
                                 send_virt + sent,
                                 send_bytes - sent,
                                 MSG_NOSIGNAL);
                if (n <= 0) {
                    if (errno == EINTR) continue;
                    if (errno != EPIPE)
                        perror("[tcp] send failed");
                    connected = 0;
                    break;
                }
                sent += (size_t)n;
            }
        }

        printf("[tcp] 客户端断开\n");
        close(g_client_fd);
        g_client_fd = -1;

        /* 重置 DMA，准备下一个客户端 */
        dma_s2mm_reset();
    }

    cleanup();
    return 0;
}
