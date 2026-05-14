# Phase 2 草稿：PS Linux TCP Forwarder

**状态**: 规划文档，Phase 2 第一周工作计划。C 骨架代码见 `phase2_tcp_forwarder.c`，功能正确但未在目标板上编译验证。

---

## 1. 功能概述

在 Zynq PS (ARM Cortex-A9, Linux 4.14 或更新) 上运行的用户态进程，功能：

1. 通过 Linux AXI-DMA 驱动（`/dev/dma-proxy` 或 `/dev/uio0`）控制 S2MM 传输
2. 将 emeye_accel_top 输出帧（32-bit packed，AXI-Stream → DMA → DDR）读取到用户态缓冲
3. 通过 TCP socket 推送到 Host PC（`simulation/network_demo.py`）
4. 使用 double-buffer（ping-pong）避免 DMA 写和 socket 发送相互阻塞

---

## 2. 协议格式（与 network_demo.py 兼容）

每个 32-bit word 打包格式（与现有仿真 demo 完全一致）：

```
bit[31]    : ch_id       (0=RX1, 1=RX2)
bit[30:15] : frame_idx   (16-bit 帧序号，循环计数)
bit[14]    : frame_start (1=本帧第一个样本)
bit[11:0]  : magnitude   (12-bit 幅度值)
```

字节序：小端（ARM native），Host PC 的 `network_demo.py` 解析时需要 `struct.unpack('<I', ...)`.

---

## 3. 编译方法

### 3.1 交叉编译（在 x86 主机上编译）

```bash
# 安装交叉工具链（Ubuntu/Debian）
sudo apt install gcc-arm-linux-gnueabihf

# 静态编译，避免依赖目标板 libc 版本
arm-linux-gnueabihf-gcc -O2 -static \
    -Wall -Wextra \
    -o tcp_forwarder \
    phase2_tcp_forwarder.c

# 验证目标架构
file tcp_forwarder
# 预期输出: ELF 32-bit LSB executable, ARM, EABI5, statically linked
```

### 3.2 在板上本地编译（如果 rootfs 有 gcc）

```bash
# LDSDR rootfs 可能是精简版，可能没有 gcc
# 如果有 Buildroot toolchain 或 PetaLinux SDK:
gcc -O2 -o tcp_forwarder phase2_tcp_forwarder.c

# PetaLinux SDK 交叉编译
source /opt/petalinux/2022.2/environment-setup-cortexa9t2hf-neon-poky-linux-gnueabi
$CC -O2 -o tcp_forwarder phase2_tcp_forwarder.c
```

---

## 4. 部署方法

### 4.1 通过 SCP（网络可达时）

```bash
# 假设 LDSDR 板子 IP 是 192.168.1.10，root 登录
scp tcp_forwarder root@192.168.1.10:/tmp/
ssh root@192.168.1.10 "chmod +x /tmp/tcp_forwarder"
```

### 4.2 塞进 SD 卡 rootfs（无网络情况）

```bash
# 挂载 SD 卡 rootfs 分区（通常是第二分区）
sudo mount /dev/sdb2 /mnt/rootfs
sudo cp tcp_forwarder /mnt/rootfs/usr/bin/
sudo umount /mnt/rootfs
```

### 4.3 塞进 PetaLinux initramfs

```
# 在 PetaLinux 工程里，把编译好的 tcp_forwarder 加到 rootfs:
# project-spec/configs/rootfs_config 里追加
CONFIG_tcp-forwarder=y
# 或直接复制到 project-spec/meta-user/recipes-apps/tcp-forwarder/
```

---

## 5. 启动命令

```bash
# 基本启动（监听 5555 端口，DMA buffer 共 8 MB）
./tcp_forwarder --port 5555 --buf-mb 8

# 可选参数（骨架代码里实现了简单 getopt 解析）:
./tcp_forwarder \
    --port 5555        \  # TCP 监听端口（Host PC 连这个）
    --buf-mb 8         \  # DMA ring buffer 总大小（MB）
    --uio-dev /dev/uio0\  # AXI-DMA UIO 设备节点 [待验证: 节点名]
    --dma-addr 0x1C000000 # DMA 物理基地址（从设备树读，见下文）[待验证]
```

---

## 6. 设备树要求

`axi_dma_0` 需要在 Linux 设备树里有对应节点，否则驱动无法加载。

### 6.1 `system.dtsi` 中新增节点（概念，需按实际地址填写）

```dts
/* [待验证] 地址范围需要与 Vivado BD 地址分配一致 */
axi_dma_0: dma@40400000 {
    compatible = "xlnx,axi-dma-1.00.a";
    #dma-cells = <1>;
    reg = <0x40400000 0x10000>;     /* AXI-Lite 控制寄存器地址 [待验证] */
    xlnx,addrwidth = <32>;
    interrupt-parent = <&intc>;
    interrupts = <0 29 4>;          /* IRQ 号 [待验证]: 需查 PS IRQ_F2P 映射 */
    xlnx,include-sg = <0>;          /* 关闭 Scatter-Gather */
    dma-channel@40400030 {          /* S2MM channel */
        compatible = "xlnx,axi-dma-s2mm-channel";
        xlnx,datawidth = <32>;
        xlnx,device-id = <0>;
    };
};

/* DMA buffer 预留内存区（物理地址 0x1C000000，大小 16 MB）*/
/* [待验证] 地址需不与其他外设或内核保留区冲突 */
reserved-memory {
    #address-cells = <1>;
    #size-cells = <1>;
    ranges;
    dma_reserved: buffer@1C000000 {
        no-map;
        reg = <0x1C000000 0x01000000>;  /* 16 MB */
    };
};
```

### 6.2 查找实际地址的方法

```bash
# 上板后，Linux 启动后：
cat /proc/device-tree/axi_dma_0/reg | hexdump -C
# 或者
cat /sys/class/uio/uio0/maps/map0/addr
cat /sys/class/uio/uio0/maps/map0/size
```

---

## 7. UIO 驱动与 DMA proxy 选择

### 方案 A: Xilinx dma-proxy 驱动（推荐）

Xilinx 提供了 `dma-proxy` 用户态驱动骨架（GitHub: Xilinx/linux-xlnx，`drivers/staging/xilinx-dmatest/`），通过 `/dev/dma_proxy_rx` 做 `ioctl(FINISH_XFER)` 触发 S2MM 传输。

这是最接近生产可用的方案，避免手写寄存器操作。

```bash
# 加载驱动
modprobe dma-proxy
ls /dev/dma_proxy_rx  # 应该出现
```

### 方案 B: UIO + 直接寄存器操作（骨架代码用此方案）

直接通过 `/dev/uio0` mmap AXI-DMA 控制寄存器，手写 S2MM 启动序列。寄存器定义来自 PG021 AXI-DMA v7.1。

`phase2_tcp_forwarder.c` 用的是方案 B，理由：不依赖 dma-proxy 驱动是否在目标 rootfs 里。

---

## 8. 性能预期

| 参数 | 数值 | 说明 |
|------|------|------|
| emeye_accel 输出数据率（双通道，8 MSPS，dec=1000） | 8000 samples/s × 2 ch × 4 bytes = **64 KB/s** | 已经过 CIC 抽取，帧率很低 |
| 未抽取时（直通 magnitude）| 8 MSPS × 4 bytes = **32 MB/s** | 峰值，需要有 FIFO 缓冲 |
| 千兆以太网理论带宽 | ~117 MB/s（扣除 TCP/IP 开销约 100 MB/s） | |
| 余量（正常模式 dec=1000）| 100 MB/s / 64 KB/s ≈ **1500x** | 完全不是瓶颈 |
| 余量（直通模式）| 100 MB/s / 32 MB/s ≈ **3x** | 仍有余量，但需要 ring buffer |

**结论**: 正常抽取模式下以太网完全够用。即使是压力测试（双通道 8 MSPS 不抽取），3x 余量配合 ring buffer 也能稳定传输。

---

## 9. 与 Host PC 客户端的对接

### 9.1 `simulation/network_demo.py` 协议对接

Host PC 端：

```python
import socket, struct, numpy as np

HOST = "192.168.1.10"  # LDSDR 板子 IP
PORT = 5555

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    while True:
        raw = s.recv(4096)
        if not raw:
            break
        words = struct.unpack(f"<{len(raw)//4}I", raw)
        for w in words:
            ch_id      = (w >> 31) & 0x1
            frame_idx  = (w >> 15) & 0xFFFF
            frame_start= (w >> 14) & 0x1
            mag        = w & 0xFFF
            # 处理...
```

### 9.2 字节序注意事项

- ARM Cortex-A9 是小端（little-endian）
- AXI-DMA 写到 DDR 的数据是小端字节序
- Python `struct.unpack('<I', ...)` 的 `<` 表示小端，与目标一致

---

## 10. 已知问题和 Phase 2 待验证项

1. **`[待验证]` UIO 设备节点名**: 实际板子上可能是 `/dev/uio0`、`/dev/uio1` 等，取决于设备树里有多少 UIO 设备。需要 `ls /sys/class/uio/` 查看。

2. **`[待验证]` DMA 物理基地址**: 骨架代码里用的 `0x1C000000` 是占位符，必须与 Vivado BD 地址分配一致。Phase 2 综合完成后查 `xsa` 文件或 `system.hdf` 里的地址映射。

3. **`[待验证]` S2MM 复位序列**: PG021 规定 S2MM 启动前要先写 DMACR[2]=1 做软复位，等 DMACR[2] 归 0，再写 DMACR[0]=1 启动。骨架代码里有对应操作，但未在实际 IP 上验证时序是否足够。

4. **`[待验证]` FIFO 满时的反压行为**: 如果 PS 来不及处理（网络临时断开），axis_data_fifo 会满，m_axis_tready 拉低。emeye_accel_top 的 m_axis 端口需要能正确处理背压（tready=0 时保持 tvalid 和 tdata），否则帧数据会丢失。检查 `emeye_accel_top.v` 的 m_axis 输出逻辑是否有 skid buffer。

5. **`[待验证]` 大页/CMA 内存**: 某些 PetaLinux 配置要求 DMA buffer 在 CMA 区，否则会因为 MMU 缺页失败。如果 `mmap` 返回 `ENOMEM`，需要在启动参数加 `cma=64M`。

---

## 11. 参考资料

- Xilinx AXI-DMA PG021 v7.1：https://www.xilinx.com/support/documents/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf
- Xilinx UIO 用户态 I/O：https://www.kernel.org/doc/html/latest/driver-api/uio-howto.html
- Xilinx dma-proxy 驱动示例：https://github.com/Xilinx/linux-xlnx/tree/master/drivers/staging/xilinx-dmatest
- TCP_NODELAY 说明：`man 7 tcp`，`man 2 setsockopt`
- network_demo.py：`../../simulation/network_demo.py`（本项目）
