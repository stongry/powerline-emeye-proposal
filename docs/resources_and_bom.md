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

**架构调整**:**Phase 0 采购商用宽带 CT(Tekbox TBCP2-1000)作为主探头**,自研 CT 从 Phase 0 主路径降级为 Phase 2 学术探索方向(见 coupling_refined_analysis.md)。

**预算上限**:¥10,000

| 项 | 型号 | 用途 | 单价 | 数量 | 小计 |
|---|---|---|---|---|---|
| **商用宽带 CT(主探头)** | Tekbox TBCP2-1000(100kHz-1GHz,转移阻抗 5Ω) | 电源线传导信号采集 | ¥4,500 | 1 | 4,500 |
| **Raspberry Pi 4B 套件** | 4GB RAM + 32GB SD + 电源 | Phase 0 受害设备(对齐论文 RPi 摄像头) | ¥500 | 2 | 1,000 |
| **Raspberry Pi Camera Module v1.3** | OV5647 sensor | EM Eye 论文同款摄像头 | ¥80 | 2 | 160 |
| **SMA 同轴线和接头** | 3 米 RG-316, SMA 公母转接 | 信号链 | ¥30 | 10 | 300 |
| **隔离变压器** (如实验室无) | 1:1, 220V/220V, 1kVA | 安全 | ¥1,200 | 1 | 1,200 |
| **Fair-Rite 磁芯样品集**(Phase 2 自研用,可选) | #43 + #61 + #75 等 | 自研 CT 学术探索 | ¥50/件 | 6 | 300 |
| **目标 COTS 摄像头**(选 3-4 台) | 论文 Table II 子集,如 Wyze Cam Pan 2、Xiaomi Dafang、小米米家 | 多设备验证 | ¥200-500/台 | 4 | 1,200 |
| **杂项**(电阻/电容/小工具/连接器) | 调试用 | | ¥500 | — | 500 |
| **Phase 0 合计** | | | | | **~¥9,160** |

### Phase 0 探测策略(Tekbox 商用 CT 主路)

**主路 — Tekbox TBCP2-1000 + 实验室公共仪器**:
- 商用宽带 CT 直接夹电源线,100 kHz – 1 GHz 平坦响应
- 配合实验室频谱仪 + VNA 完成 Phase 0 验证
- 优点:测量标准化(NIST 可追溯)、Phase 0 第 1 周即可启动
- 成本:¥4,500(项目经费,非候选人自费)

**实验室公共资源**(辅助):
- LISN(如有,可用作对照)
- 频谱仪(必备)
- VNA(必备,用于前端板调试)
- 隔离变压器(安全)

**Phase 2 自研 CT 学术探索**(非 Phase 0 主路):
- coupling_refined_analysis.md 中的复合磁芯 CT 设计保留作为研究方向
- 目标:做出比 Tekbox 100 mm 更紧凑(目标 20 mm)的小型化版本
- 与 Tekbox 做对照实验,作为论文工程贡献章节

### Phase 0 输出(预期)
- 电源线传导泄漏可观测性的 Go/No-Go 判断(覆盖 100 MHz – 1 GHz 全频段,因 Tekbox 覆盖完整)
- EM Eye Table II 12 个设备的电源线泄漏频点实测
- 与论文空气场景的信号强度对比
- Phase 1 是否需要 Stage 2 SAW BPF 的判定

---

## 四、Phase 1 工程化采购 🟠(Week 4-16)

**预算上限**:¥15,000(BOM + NRE)

### Phase 1 BOM(方案 A: LDSDR + Ethernet 直连 PC,单台)

| 模块 | 主选元件 | 单价 | 备注 |
|---|---|---|---|
| **耦合 CT** | Fair-Rite 2675102002(#75 nano) | 35 | 低中频段主导 |
| | Fair-Rite 2643000201(#43 NiZn) | 25 | 中高频段主导 |
| | RG-178 同轴内导体作绕组 | 30 | 5-7 匝单层 |
| | SMA 母座 PCB 直焊 | 15 | 输出 |
| | 0805 50Ω 薄膜电阻 | 5 | 端接 |
| **信号侧保护**(简化版) | Bourns CDSOT23-T05LC(低 C TVS) | 8 | ESD/瞬态,C<1pF |
| | Murata GRM18 NP0 1nF/100V ×2 | 6 | DC 隔直 |
| **滤波 Stage 1**(HPF 30MHz,必选) | Murata 150pF/56pF NP0 各 1 | 4 | LC HPF |
| | Coilcraft 0603HP 150nH/330nH 各 1 | 12 | LC HPF |
| **LNA** | 沿用候选人 ERA-4SM+ × 2(BYO) | 0 | 实测 +28 dB,扩 IIP3 用 |
| | Phase 1 加 PGA-103+ 第三级(可选) | 100 | 仅在 Phase 0 测出 SNR 不够时启用 |
| **滤波 Stage 2**(BPF 组,可选) | Murata SAW ×4 + Peregrine PE42423 | 350 | **降级:AD9361 内部 DDC 已替代基础功能** |
| **SDR** | LDSDR 7010 rev2.1(BYO,候选人手头) | 0 | AD9363+Zynq+千兆 Ethernet+2T2R |
| **~~主控 CM4 删除(方案 A)~~** | ~~Raspberry Pi CM4~~ | ~~~1000~~ | **删除,LDSDR Ethernet 直连 PC** |
| **无线**(由 PC 笔记本承担) | 无独立硬件 | 0 | PC/笔记本自带 WiFi |
| **电源**(USB 供电,无 AC-DC) | USB-C 接口 + ESD 保护 | 30 | 唯一供电入口(LDSDR USB 5V) |
| | TI TPS7A47(LNA 模拟 LDO) | 20 | LNA 净化电源 |
| **PCB** | 4 层 80×60mm 模拟前端板 | 400 | 含贴片,Rogers RO4350B 顶层 |
| | ~~4 层 80×60mm 数字载板~~ | 0 | **删除(LDSDR 直接出 Ethernet)** |
| **结构** | 3D 打印 ABS 外壳 + 装配件 | 150 | 80×60×25 mm 可行(更紧凑) |
| **接插件** | SMA + Ethernet 母座 + USB-C + 屏蔽 | 60 | |
| **网线** | CAT6 1m | 10 | LDSDR → PC |
| **单台 Phase 1 BOM 合计** | | | **~¥820(基线,纯前端板)** |

**与改动前对比**:
- ¥2,470 → ¥820,**净省 ¥1,650**
- 主要砍掉:CM4 模组 + IO Board(¥1,000)、独立数字载板 PCB(¥500)、Stage 2 BPF(¥350,降级为可选)
- 增加:网线 ¥10(可忽略)

**核心简化原因**:LDSDR 本身就是完整的 SDR + Zynq 平台,直接通过千兆 Ethernet 出数据到 PC,不需要额外主控板。

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

### 总预算汇总(方案 A + Tekbox 商用 CT)

| 类别 | 金额(CNY) | 备注 |
|---|---|---|
| 🟢 候选人 Bring-Your-Own 资产 | (估值 ¥10-15k,不计预算) | LDSDR + ERA-4SM+×2 + Vivado/HLS 工具链 |
| 🟡 Phase 0 采购 | 9,160 | 含 Tekbox TBCP2-1000 ¥4,500(商用主探头) |
| 🟠 Phase 1 BOM(单台原型) | 820 – 1,170 | LDSDR + 前端板(无 CM4) |
| 🟠 Phase 1 NRE(PCB/外壳/耗材) | 1,800 | PCB 打样 1500 + 外壳 300 |
| 🔴 Phase 2 采购(集成 + 备份 + 自研 CT 探索) | 5,000 | LDSDR 备机 + 自研 CT 磁芯材料 |
| **总预算**(方案 A + Tekbox) | **~¥16,000** | 不含 RA 工资 |
| **加 RA 工资**(6 个月,按 2k/月津贴) | +12,000 | |
| **项目总成本** | **~¥28,000** | |

**对比演进**:
- 初版方案(AC 供电 + CM4 + 全保护链 + 商用探头):¥30,000
- USB 供电改进后:¥29,000
- 方案 A(LDSDR + Ethernet)+ 假设自研 CT:¥23,600
- **方案 A + 商用 CT 现实版**:**¥28,000**(诚实工程,可执行)

**为什么诚实承认买商用 CT 反而是加分项**:
- ✅ Phase 0 第 1 周即可启动,不浪费 2-3 周在磁芯到货 + 绕组工艺
- ✅ NIST 校准证书 → 测量数据可发论文
- ✅ 与论文方法可对照(Tekbox 类似 LISN 等价物,EMC 标准方法)
- ✅ 自研 CT 转为 Phase 2 学术探索方向(论文工程贡献章节)
- ✅ 工程节制信号:不卷不可控的轮子,优先用标准件

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
| 电源线传导损耗过大 | Phase 0 测出目标 SNR < 0 dB | ¥3,000 | 升级 LNA 到 50 dB(加第三级)|
| 自研 CT 带宽不够 | 实测 -3dB < 300 MHz | ¥1,500 | 改用更多种磁芯组合迭代,或借实验室商用探头 |
| Pluto SOM 供应受限 | 缺货 | ¥3,000 | 改用 LimeSDR Mini 2.0 |
| BPF 必须加但样品贵 | SAW 滤波器超预算 | ¥2,000 | 改用 LC 离散 BPF(性能略差,可接受) |
| **风险预备金** | | **~¥9,500** | 占总预算 ~50%(预算紧需大风险池) |

---

## 九、给 PI 的"预算说服力"措辞建议

写在提案 Ch6 最后:

> "Total proposed budget is approximately ¥22,000–30,000 over a 6-month engagement, **significantly below the typical hardware-side-channel research project budget** (often exceeding $10,000 for SDR + LNA + test equipment alone). This is achieved primarily by leveraging:
> (1) The candidate's existing hardware assets — ADALM-Pluto SDR, custom-built ERA-4SM+ ×2 LNA module, complete Vivado/HLS development environment;
> (2) A phased procurement model that defers expensive components (LISN, professional spectrum analyzer) to lab-provided resources or rental;
> (3) An explicit Go/No-Go gate at the end of Phase 0 (Week 3) that allows the project to be terminated with < ¥10,000 spent if power-line conducted leakage proves infeasible."

这一段对 PI 来说是"good engineering judgment"信号 — 你不仅会做技术,还会管预算和风险。
