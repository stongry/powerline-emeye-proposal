# Day 1 — 6 个核心决策 + 系统框图

**日期**:2026-05-12
**输出**:这一页文件就是 Day 1 的所有产出,Day 2 起每章的写作以这里的决策为基准。

---

## 决策 1:形态

**选定:Route A 便携集成式**(150 × 80 × 50 mm 盒装,带外置电源线探头)

| 选项 | 优点 | 缺点 | 评分 |
|---|---|---|---|
| **Route A 便携集成式** | 风险低,Pluto+CM4 现成,EMC 自干扰好控制 | 不够隐蔽 | ⭐⭐⭐⭐⭐ v1 |
| Route B 插头适配式 | 隐蔽性好,接近最终形态 | 空间紧、EMC 难,安规复杂 | Phase 2 演进 |

**理由**:先做出来证明可行,再演进形态。Yan 团队看重务实工程思维。

---

## 决策 2:耦合方式

**选定:宽带 CT 主路 + 电容耦合辅路**

| 方式 | 频响 | 隔离 | 体积 | 安全 | 角色 |
|---|---|---|---|---|---|
| 宽带 CT(铁氧体磁芯) | 1M–1G(>500M 衰减) | 电气完全隔离 | 紧凑 25–40mm | 高 | ✅ **主路** |
| 电容耦合(HV 陶瓷电容) | DC–GHz | 电容失效有触电风险 | 极小 | 中 | ✅ **辅路** |
| 微型 LISN | 限定窄带 | 自带 | >200mm | 标准 | ❌ 否决 |

**关键参数**:
- 磁芯:Fair-Rite #43 (0.05–250 MHz) + #61 (20 MHz–1 GHz) 复合,或单一宽带磁芯 Fair-Rite 2643000201
- 绕组:5–10 匝,单层均匀,减少自谐振
- 辅路电容:2kV / 1nF 高压陶瓷,补足 >500 MHz 段

---

## 决策 3:保护与隔离链

**链路**(市电侧 → 内部侧):

```
[市电火/零] → GDT → MOV → 共模扼流圈 → TVS阵列 → DC隔直 → LC高通 → [耦合CT]
                                                          ↓
                                                  fc ≥ 1 MHz, 50Hz 抑制 >80dB
```

| 元件 | 型号 | 参数 |
|---|---|---|
| GDT(气体放电管) | Bourns 2026-23-SM | 230V 击穿 |
| MOV(压敏电阻) | Littelfuse V275LA20A | 275 VAC |
| 共模扼流圈 | Würth 744232222 | >100 MHz 阻抗 >1 kΩ |
| TVS 阵列 | SMAJ12A | 12V 钳位,快速响应 |
| 隔直电容 | 2kV / 1nF 高压陶瓷 | 工频隔离 |
| LC HPF | L=10uH + C=10nF | fc ≈ 1.6 MHz |

---

## 决策 4:LNA

**选定:PGA-103+ × 2 级联,总增益 38–40 dB**

| 选项 | 增益 | NF | 带宽 | 价格 | 决定 |
|---|---|---|---|---|---|
| 论文同款 Foresight FST-RFAMP06 | 40 dB | ~3 dB | DC–3.5 GHz | $207 | 国内不好买,作为论文对标 |
| **Mini-Circuits PGA-103+ × 2** | 38 dB | <1 dB | 50 MHz–4 GHz | ~$50/级 | ✅ **选定** |
| PSA4-5043+ + PGA-103+ | 42 dB | 0.7 dB | 50 MHz–4 GHz | ~$80 | 高端备选 |

**配套**:
- 级间 π 型衰减器(0/3/6 dB 可调)
- 单独铜罩屏蔽腔体
- Rogers RO4350B 微带线(>500 MHz 段)

---

## 决策 5:SDR + 主控

**SDR 选定:ADALM-Pluto SOM**(AD9363 + Zynq xc7z010)

| 选项 | 频段 | BW | 位数 | 价格 | 决定 |
|---|---|---|---|---|---|
| **ADALM-Pluto SOM** | 70M–6G(解锁) | 56 MHz | 12-bit | ~$150 | ✅ **选定** |
| LimeSDR Mini 2.0 | 10M–3.5G | 30.72 MHz | 12-bit | ~$400 | 备选 |
| HackRF One | 1M–6G | 20 MHz | 8-bit | ~$300 | ❌ 动态范围不够 |
| RTL-SDR v4 | 500k–1.7G | 2.4 MHz | 8-bit | ~$40 | ❌ 8-bit + 单通道 |

**关键差异化**:**候选人有 Pluto Zynq-7010 完整 HDL 实战经验**(OFDM+LDPC 收发机,BER=0 板级验证)→ 具备 Phase 2 修改 Pluto 内部 FPGA 固件做 |I+jQ| 解调 + 帧同步的能力,这是大多数 RA 候选人做不到的。

**主控选定:Raspberry Pi CM4 Lite 8GB + WiFi6**

| 候选 | ARM 核 | RAM | WiFi | 决定 |
|---|---|---|---|---|
| **Raspberry Pi CM4 8GB Lite WiFi** | Cortex-A72 × 4 | 8 GB | 内置 802.11ac/n | ✅ **选定** |
| NVIDIA Jetson Nano 4GB | Cortex-A57 × 4 | 4 GB | 外置 | 备选(GPU 加速时可用) |
| RK3568 + RKNN | Cortex-A55 × 4 | 4-8 GB | 外置 | 候选人最熟,但生态弱于 CM4 |

---

## 决策 6:无线传输 + 处理

**选定:v1 原始 IQ over WiFi 6**(板上幅度解调 v2 作为路线图)

带宽估算:
- v1 原始 IQ:8 MSPS × 2(I+Q) × 12 bit = **192 Mbps**,WiFi 6 实测 200+ Mbps,**可行**
- v2 板上 |I+jQ| 解调流:8 MSPS × 8 bit = **64 Mbps**,WiFi 4 实测 30 Mbps 不够,需要至少 WiFi 5
- v3 板上完整重建,传图像:30 fps × 200 × 1000 × 1 byte = **48 Mbps**,WiFi 4 都够

| 方案 | 无线 BW | 上位机算力 | 算法灵活性 | 延迟 | 阶段 |
|---|---|---|---|---|---|
| WiFi 6 原始 IQ | 192 Mbps | 高 | 最大 | 高 | ✅ **v1** |
| 板上幅度解调 + Tf/Tr 帧同步,传降速流 | 64 Mbps | 中 | 设计时锁定 | 低 | **v2 路线图** |
| 板上完整 pix2pix 重建 | <10 Mbps | 低 | 设计时锁定 | 低 | v3 未来工作 |

**v2 实现路径**(写进提案 Sidebar):
- 利用 Pluto 内置 Zynq-7010 PL(Programmable Logic)实现:
  - 模块 A:|I+jQ| 整数幅度计算(CORDIC 或近似 max+min/4)
  - 模块 B:30 Hz 周期信号自相关,粗估 Tf
  - 模块 C:输出 8-bit 解调流(192 → 64 Mbps,压缩 3×)
- 主控 CM4 接管:精细 Tf/Tr 估计、行裁剪、多频段融合、pix2pix 推理
- **候选人有 Pluto + Zynq HDL 经验**,可在 Phase 2(3 个月内)完成

---

## 决策 7:滤波策略 — HPF 必选 + BPF 待定

**选定:两阶段滤波 — Stage 1 无源 HPF 必选,Stage 2 可切换 BPF 组待 Phase 0 SNR 实测决定**

### 背景

EM Eye 论文(Appendix F)指出 BPF 是"可改进项"但主实验不用。论文是空气耦合,我们是电源线耦合,**电源线场景的干扰图景显著更恶劣**:AM 广播、FM 广播、室内开关电源 EMI 都直接传导。

### Stage 1(基线,永远在线)

**LC 4 阶高通滤波器 fc=30 MHz**

| 参数 | 值 |
|---|---|
| 拓扑 | 4 阶 Chebyshev LC HPF |
| 截止频率 | 30 MHz |
| 通带插损 | <1 dB |
| 阻带衰减 | >30 dB @ 10 MHz, >60 dB @ 1 MHz |
| 元件 | L=470 nH × 3, C=47 pF × 2 |
| BOM 成本 | ~¥15 |

**作用**:
- 滤掉 AM 广播 (530-1700 kHz)
- 滤掉 FM 广播 (88-108 MHz 部分能量)
- 滤掉室内 SMPS 传导 EMI(<30 MHz)
- 不影响任何 EM Eye Table II 目标频点(全 ≥155 MHz)

### Stage 2(增强项,Phase 1 实测后决定是否上)

**4 段 SAW BPF 通过 SP4T RF 开关切换**

| 频段 | 中心 | 带宽 | 覆盖 Table II 目标 |
|---|---|---|---|
| Band-1 | 200 MHz | 150-250 | RPi V1 (204), Xiaodu (204) |
| Band-2 | 450 MHz | 350-550 | Pixel 3 (515), 360 (450), Dafang (322 边缘) |
| Band-3 | 900 MHz | 800-1000 | WyzeCam (890), Dafang (890) |
| Band-4 | 1500 MHz | 1300-1700 | Pixel 1 (1649), 行车记录仪 (1015/1261/1470) |

**每段 SAW 性能要求**:
- 通带插损 ≤ 3 dB
- 阻带抑制 ≥ 40 dB(距中心 ±100% 处)
- VSWR ≤ 1.5:1
- 群延迟波动 ≤ 50 ns

**RF 开关**:Peregrine PE42423 或 ADRF5040,隔离 >50 dB,响应 <1 μs

**Stage 2 BOM 成本**:~¥350

### 决策依据

| 维度 | 不加 BPF | 仅 HPF | HPF + 可切换 BPF |
|---|---|---|---|
| LNA 饱和风险 | 高(电源线带强干扰) | 中 | 低 |
| SNR 改进 | baseline | +5 dB | +10-15 dB |
| BOM 成本 | ¥0 | ¥15 | ¥350 |
| 开发时间 | 0 | +0.5 周 | +2 周 |
| 推荐阶段 | ❌ | ✅ **Phase 0** | 🟡 Phase 1 看实测 |

### Phase 0 决策门

**触发上 Stage 2 BPF 的条件**(写进提案 §6 Phase 0 Go/No-Go 标准):

如果 Phase 0 实测发现以下任一情况,Phase 1 必须加 Stage 2:
1. LNA 输出端在 100 MHz – 1 GHz 测得带外干扰功率 > -30 dBm(LNA 接近饱和)
2. 目标频点 SNR < 10 dB(论文同等条件应有 ~30 dB)
3. 重建图像有明显条纹干扰(EM Eye Fig. 19 所示的显示器/广播干扰特征)

---

## 系统总框图

(完整 ASCII 草稿见 README.md 同步版,Day 2 转 draw.io 后作为 Figure 1)

```
墙插 → [耦合+保护] → [可选BPF] → [LNA 40dB] → [Pluto SDR] → [CM4] → [WiFi6] → PC
       Fair-Rite CT  SAW×3+开关  PGA-103+×2   AD9363+Zynq  ARM-A72   802.11ax
       GDT/MOV/TVS                                          GNURadio
```

7 个核心模块 + 独立电源域 = 8 模块。

---

## 文献调研产出(占位,Day 1 末填充)

详见 `references/related_work.md`。三组关键词:
1. 电源线传导侧信道(power-line conducted EM TEMPEST)
2. 宽带 CT 设计(broadband ferrite CT 1 GHz)
3. 已有 TEMPEST 经典(Kuhn / Hayashi / de Meulemeester)

---

## Day 1 自检

- [x] 重读 EM Eye §III/§V/§VI-A/Appendix F/H 完成
- [x] 论文笔记 `references/emeye_paper_notes.md` 已建立
- [x] 重读功能需求书,标出 4 Function + 6 章节
- [x] 6 个决策全部锁定,每个都有论文/需求书锚点
- [x] 系统框图 ASCII 完成,Day 2 转图
- [ ] 文献调研 3 组关键词(留 Day 1 下半天执行)
- [ ] Git commit

---

## 候选人现有资产清单(Bring-Your-Own)

**前提**:本提案为求职申请,候选人**不在被雇佣前自费购置实验设备**。提案的工程可信度建立在:论文阅读 + 推理严密 + 候选人现有资产 + 候选人过往项目。

| 资产 | 状态 | 在本项目中的作用 |
|---|---|---|
| **ERA-4SM+ × 2 LNA 级联模块** | 自研已完成,可立即投入 | Phase 0 模拟前端(对标论文 FST-RFAMP06,差 10 dB 增益,够用) |
| **ADALM-Pluto SDR** | 已拥有,做过 OFDM+LDPC 完整开发 | Phase 0 数字采集 + Phase 2 板上加速基础 |
| **Pluto Zynq-7010 HDL 开发链** | Vivado + Buildroot Linux 已通,BER=0 验证 | Phase 2 自研 PL 加速模块的开发基础 |
| **XCZU3EG HLS CNN 开发经验** | github.com/stongry/FPGA-ZYNQ,87.94%/675ms | Phase 2 板上 pix2pix 替代/优化的能力背书 |
| **Vivado / HLS / Buildroot 工具链** | 长期使用 | 减少新人学习曲线 |
| **嵌入式 Linux + Python + GNURadio** | RK3568 Ubuntu 移植 + EC800M 等项目 | CM4 主控开发直接上手 |

### Phase 0 仍需采购/借用清单(写进提案 §6 NRE 部分)

被雇佣后 Week 1 内需采购或借用的:

| 设备 | 用途 | 备注 |
|---|---|---|
| Tekbox TBCP2-1000 宽带电流探头(100kHz-1GHz) | Phase 0 电源线传导验证 | 实验室如已有可直接借用 |
| Raspberry Pi 3B+ / 4B + RPi Camera V1 | Phase 0 受害设备(对齐论文) | 总成本 < ¥500 |
| 频谱仪 / 矢网(VNA) | 模拟前端调试 + CT 设计验证 | 实验室通用设备 |
| 隔离 AC 220V 工作台插座 | 安全调试电源线耦合 | 实验室通用 |

**关键决策**:**Phase 0 用商用 Tekbox 探头**,不自研 CT。等 Phase 0 验证电源线传导有可观信号后,Phase 1 再自研便携 CT。

---

## Day 2 启动条件

✅ 所有决策已锁定,Day 2 可直接进入"写 Ch1 + Ch2"流程。
✅ 候选人资产清单已建立,Annex A 撰写有素材。
✅ Phase 0 改为"小批量采购+借用",不再涉及候选人自费实验。
