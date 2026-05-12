# 完整资源 + BOM 复盘

**用途**:支撑提案 Ch5(器件选型)和 Ch6(成本估算)的底层数据。

**分类原则**:
- 🟢 **候选人现有**(Bring-Your-Own)— 不需要采购
- 🔵 **实验室公共资源**(假设可借用)— 写进 NRE 但不算 BOM
- 🟡 **被雇佣后 Phase 0 采购**(项目启动后 Week 1)
- 🟠 **Phase 1 工程化采购**(Week 4-16)
- 🔴 **Phase 2 集成采购**(Week 17-24)

---

## 一、候选人现有资产 🟢(Bring-Your-Own)

这部分写进提案 Annex A,作为"候选人差异化优势"。

| 资产 | 状态 | 用途 |
|---|---|---|
| **ERA-4SM+ × 2 级联 LNA 模块** | 自研已完成,可立即用 | 模拟前端 Phase 0 主放大器(总增益 ~29 dB) |
| **ADALM-Pluto SDR** | 已拥有,OFDM+LDPC 项目验证 | Phase 0-3 数字采集核心 |
| **Pluto Zynq-7010 完整 HDL 开发链** | Vivado + Buildroot 已通,BER=0 板级 | Phase 2 板上加速基础 |
| **XCZU3EG HLS CNN 开发经验** | github.com/stongry/FPGA-ZYNQ | Phase 2 板上 pix2pix 加速备用方案 |
| **Vivado 2024.2 + Vivado HLS + Buildroot** | 长期使用 | 减少 Phase 2 开发学习曲线 |
| **嵌入式 Linux 开发环境** | RK3568 Ubuntu + EC800M | CM4 主控开发直接上手 |
| **Python + PyTorch + GNURadio** | 通用 | 算法/重建管线开发 |
| **个人计算工作站** | 已有 | 训练 pix2pix GAN(可远程到实验室服务器) |

**估值**(若从零购置):约 ¥15,000-20,000 等值资产 + 数千小时开发经验。

---

## 二、实验室公共资源 🔵(假设可借)

写进 Ch6 §"资源前提" 章节,说明这些是合理的实验室基础设施。

| 设备 | 用途 | 是否关键 | 备注 |
|---|---|---|---|
| **频谱分析仪** (9 kHz – 3 GHz+) | 监测电源线 RF 谱、目标信号搜索 | ⭐⭐⭐ 关键 | Keysight N9000B 或 R&S FPL1000 类 |
| **矢量网络分析仪** (DC – 3 GHz) | 测 CT/BPF/匹配网络 S 参数 | ⭐⭐⭐ 关键 | NanoVNA-V2 业余级也可 |
| **示波器** (≥ 1 GHz BW) | 时域调试、Pluto IQ 输出验证 | ⭐⭐ 重要 | 实验室通用 |
| **任意波形发生器** (DC – 1 GHz) | 生成测试激励、校准 | ⭐⭐ 重要 | 也可用第二台 Pluto 替代 |
| **电源** (双路可编程,± 30V) | 板调试 | ⭐⭐ 重要 | 实验室通用 |
| **隔离变压器** (1:1, 220V/220V, 500VA) | 安全调试市电耦合 | ⭐⭐⭐ 关键(安全) | 必须有,否则触电风险 |
| **LISN** (Line Impedance Stabilization Network) | EMC 标准方法的电源线传导测量 | ⭐⭐⭐ Phase 0 关键 | 论文级实验需要,Tekbox TBL5016-1 ~¥8k |
| **温箱**(可选) | 长期可靠性 | ⭐ Phase 2 | 非必需 |
| **EMC 暗室**(可选) | 远场对照实验 | ⭐ Phase 2 | 非必需 |
| **GPU 服务器** (NVIDIA RTX 30/40 系列) | 训练 pix2pix GAN | ⭐⭐ Phase 2 | 可远程,候选人本地也有 |

**关键判断**:**LISN 和隔离变压器是 Phase 0 的硬性前提**,如果实验室没有,需要采购。其他设备可灵活替代。

---

## 三、Phase 0 启动采购清单 🟡(被雇佣后 Week 1)

**预算上限**:¥10,000(项目启动费,要 PI 批准)

| 项 | 型号 | 用途 | 单价 | 数量 | 小计 |
|---|---|---|---|---|---|
| **宽带电流探头** | Tekbox TBCP2-1000 (100 kHz – 1 GHz) | 电源线传导信号探测 | ¥4500 | 1 | 4500 |
| **Raspberry Pi 4B 套件** | 4GB RAM + 32GB SD + 电源 | Phase 0 受害设备(对齐论文 RPi 摄像头) | ¥500 | 2 | 1000 |
| **Raspberry Pi Camera Module v1.3** | OV5647 sensor | EM Eye 论文同款摄像头 | ¥80 | 2 | 160 |
| **SMA 同轴线和接头** | 3 米 RG-316, SMA 公母转接 | 信号链 | ¥30 | 10 | 300 |
| **隔离变压器** (如实验室无) | 1:1, 220V/220V, 1kVA | 安全 | ¥1200 | 1 | 1200 |
| **LISN**(如实验室无) | Tekbox TBL5016-1 | EMC 风格电源线测量 | ¥8000 | 1 | 0/8000 |
| **目标 COTS 摄像头**(选 3-4 台) | 论文 Table II 子集,如 Wyze Cam Pan 2、Xiaomi Dafang、小米米家 | 多设备验证 | ¥200-500/台 | 4 | 1200 |
| **杂项**(电阻/电容/磁芯样品/小工具) | 阻抗匹配元件、Fair-Rite 磁芯试样 | 验证用 | ¥500 | — | 500 |
| **Phase 0 合计**(实验室有 LISN) | | | | | **~¥8,860** |
| **Phase 0 合计**(实验室无 LISN) | | | | | **~¥16,860** |

### Phase 0 输出
- 电源线传导泄漏可观测性的 Go/No-Go 判断
- 100 MHz – 1 GHz 范围内的电源线传导损耗实测曲线
- 论文 Table II 12 台设备中,至少 4 台在电源线上可观测的频点列表

---

## 四、Phase 1 工程化采购 🟠(Week 4-16)

**预算上限**:¥15,000(BOM + NRE)

### Phase 1 BOM(单台便携集成原型)

| 模块 | 主选元件 | 单价 | 备注 |
|---|---|---|---|
| **耦合 CT** | Fair-Rite 2643000201 ×2 复合磁芯 | 60 | 自研宽带 CT |
| | Teflon 同轴线 RG-178 | 20 | 绕组 |
| | SMA 母座 PCB 直焊 | 10 | 输出 |
| **保护链** | Bourns 2026-23-SM (GDT) | 15 | 一级保护 |
| | Littelfuse V275LA20A (MOV) | 3 | 二级保护 |
| | TDK X1Y2 安全电容 1nF/2kV ×4 | 32 | 隔直 |
| | Würth 744232222 (共模扼流) | 25 | 共模抑制 |
| | Würth 7447745022 (功率电感 2.2μH) ×2 | 20 | LC HPF |
| | NP0 10nF ×2 | 6 | LC HPF |
| | SMAJ12CA (TVS) | 2 | 后级保护 |
| **滤波 Stage 1**(HPF 30MHz) | LC 高通(L=470nH ×3, C=47pF ×2) | 15 | 必选 |
| **LNA** | 沿用候选人 ERA-4SM+ × 2 | 0 | 现成 |
| | 加 PGA-103+ 第三级(可选,补足增益) | 100 | 总 50 dB |
| **滤波 Stage 2**(BPF 组,可选) | Murata SAW ×4 + Peregrine PE42423 | 350 | 看 Phase 0 决定 |
| **SDR** | ADALM-Pluto SOM(沿用) | 0 | 现成 |
| **主控** | Raspberry Pi CM4 Lite 8GB WiFi | 800 | 含载板 |
| | CM4 IO Board(开发用) | 200 | 调试 |
| **无线** | 内置 WiFi 6(CM4 自带) | 0 | |
| **电源** | Mean Well IRM-10-5(隔离 AC-DC) | 80 | |
| | TI TPS7A47(模拟 LDO)×2 | 40 | |
| | TI TPS54320(数字开关) | 30 | |
| **PCB** | 4 层 6×8cm 模拟前端板 | 600 | 含贴片 |
| | 4 层 8×10cm 数字主板 | 800 | 含贴片 |
| **结构** | 3D 打印 ABS 外壳 + 装配件 | 300 | 150×80×50mm |
| **接插件** | 工业电源插头 + 透传插座 + USB-C 调试口 | 100 | |
| **杂项**(钢架、屏蔽罩、紧固) | | 100 | |
| **单台 Phase 1 BOM 合计** | | | **~¥3,706 (不含 Stage 2 BPF) / ~¥4,056 (含)** |

### Phase 1 NRE

| 项 | 成本 |
|---|---|
| PCB 打样(2 次迭代,每次小批量 5 块) | 1500 |
| 3D 外壳打样(2 次迭代) | 800 |
| 调试/测试耗材(锡膏、酒精、清洗剂、防静电包装等) | 300 |
| **Phase 1 NRE 合计** | **~¥2,600** |

---

## 五、Phase 2 集成与板上加速采购 🔴(Week 17-24)

| 项 | 单价 | 数量 | 小计 |
|---|---|---|---|
| 第二代集成 PCB(6 层,优化版) | 2500 | 1 | 2500 |
| CNC 铝合金外壳(替代 3D 打印) | 800 | 1 | 800 |
| 备用 Pluto SOM(开发并行) | 1500 | 1 | 1500 |
| 备用 CM4 模组 | 800 | 1 | 800 |
| 频谱仪扩展头/混频器(如需高频对照) | 1000 | — | 1000 |
| **Phase 2 NRE/采购合计** | | | **~¥6,600** |

---

## 六、人力成本 / 工时估算

按 1 名 RA 全职 6 个月:

| Phase | 时长 | 主要工作 |
|---|---|---|
| **Phase 0** | 3 周 | 可行性实验、SNR 基线建立、Go/No-Go 决策 |
| **Phase 1** | 12 周 | 模拟前端 + 数字采集集成、便携原型出板 |
| **Phase 2** | 8 周 | 板上加速、多设备验证、终版报告 |
| **Phase 3**(可选) | 4+ 周 | 安全测试、法规合规、向插头适配形态演进 |

---

## 七、总预算 + 时间表(写进提案 Ch6)

### 总预算汇总

| 类别 | 金额(CNY) | 备注 |
|---|---|---|
| 🟢 候选人 Bring-Your-Own 资产 | (估值 ¥15-20k,不计预算) | 显著降低项目启动成本 |
| 🟡 Phase 0 采购(假设实验室有 LISN) | 8,860 | 验证可行性 |
| 🟡 Phase 0 采购(假设实验室无 LISN) | 16,860 | LISN 是大头 |
| 🟠 Phase 1 BOM(单台原型) | 3,706 – 4,056 | 视 Stage 2 BPF 选择 |
| 🟠 Phase 1 NRE(PCB/外壳/耗材) | 2,600 | |
| 🔴 Phase 2 采购(集成 + 备份) | 6,600 | |
| **总预算**(标准情况) | **~¥22,000** | 不含 RA 工资 |
| **总预算**(实验室无 LISN) | **~¥30,000** | 不含 RA 工资 |
| **加 RA 工资**(6 个月,按 2k/月津贴) | +12,000 | |
| **项目总成本** | **~¥34,000 – 42,000** | |

### 时间表

```
Week 1-3   Phase 0  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ (可行性 + Go/No-Go)
Week 4-7   Phase 1  ━━━━━━ 模拟前端 + 耦合 CT 自研
Week 8-11               ━━━━━━ Pluto + CM4 集成 + WiFi 联通
Week 12-15                          ━━━━━━ PCB 打样 + 调试 + 整机集成
Week 16                                   ━ Phase 1 评审
Week 17-20  Phase 2 ━━━━━━━━ Pluto FPGA 板上加速(候选人 OFDM 经验复用)
Week 21-24                       ━━━━━━━━ 多设备验证 + 终版报告
```

---

## 八、风险驱动的预算保留

写进 Ch7 风险段:

| 风险 | 触发条件 | 应急预算 | 应对 |
|---|---|---|---|
| 电源线传导损耗过大 | Phase 0 测出目标 SNR < 0 dB | ¥3,000 | 升级 LNA 到 50 dB(加第三级) |
| 自研 CT 带宽不够 | Phase 1 实测 -3dB <500 MHz | ¥4,500 | 改用 Tekbox 商用探头作为最终方案 |
| Pluto SOM 供应受限 | 缺货 | ¥3,000 | 改用 LimeSDR Mini 2.0 |
| BPF 必须加但样品贵 | SAW 滤波器超预算 | ¥2,000 | 改用 LC 离散 BPF(性能略差,可接受) |
| **风险预备金** | | **~¥10,000** | 占总预算 ~30% |

---

## 九、给 PI 的"预算说服力"措辞建议

写在提案 Ch6 最后:

> "Total proposed budget is approximately ¥22,000–30,000 over a 6-month engagement, **significantly below the typical hardware-side-channel research project budget** (often exceeding $10,000 for SDR + LNA + test equipment alone). This is achieved primarily by leveraging:
> (1) The candidate's existing hardware assets — ADALM-Pluto SDR, custom-built ERA-4SM+ ×2 LNA module, complete Vivado/HLS development environment;
> (2) A phased procurement model that defers expensive components (LISN, professional spectrum analyzer) to lab-provided resources or rental;
> (3) An explicit Go/No-Go gate at the end of Phase 0 (Week 3) that allows the project to be terminated with < ¥10,000 spent if power-line conducted leakage proves infeasible."

这一段对 PI 来说是"good engineering judgment"信号 — 你不仅会做技术,还会管预算和风险。
