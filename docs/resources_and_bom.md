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

**明确约束**:**不采购任何商用 RF 电流探头**(候选人决定)。Phase 0 探测设备依赖实验室公共资源,或自研最小 CT。

**预算上限**:¥5,000

| 项 | 型号 | 用途 | 单价 | 数量 | 小计 |
|---|---|---|---|---|---|
| **Raspberry Pi 4B 套件** | 4GB RAM + 32GB SD + 电源 | Phase 0 受害设备(对齐论文 RPi 摄像头) | ¥500 | 2 | 1000 |
| **Raspberry Pi Camera Module v1.3** | OV5647 sensor | EM Eye 论文同款摄像头 | ¥80 | 2 | 160 |
| **SMA 同轴线和接头** | 3 米 RG-316, SMA 公母转接 | 信号链 | ¥30 | 10 | 300 |
| **隔离变压器** (如实验室无) | 1:1, 220V/220V, 1kVA | 安全 | ¥1200 | 1 | 1200 |
| **Fair-Rite 磁芯样品集**(自研最小 CT 用) | #43 + #61 + #67 + #75 各 2-3 件 | 自研 CT 试验 | ¥50/件 | 10 | 500 |
| **Teflon 细线 + SMA 母座 PCB**(自研 CT 用) | RG-178 内导体 + SMA 母 | 自研 CT 试验 | ¥30 | 5 | 150 |
| **目标 COTS 摄像头**(选 3-4 台) | 论文 Table II 子集,如 Wyze Cam Pan 2、Xiaomi Dafang、小米米家 | 多设备验证 | ¥200-500/台 | 4 | 1200 |
| **杂项**(电阻/电容/小工具/连接器) | 调试用 | | ¥500 | — | 500 |
| **Phase 0 合计** | | | | | **~¥5,010** |

### Phase 0 探测策略(无商用探头)

**Path A — 实验室公共资源**(首选):
- 使用实验室已有的 LISN(线性阻抗稳定网络)+ 频谱仪做电源线传导扫描
- 使用实验室宽带电流探头(如有)
- 优点:测量标准化、可信度高
- 风险:实验室未必有所需设备

**Path B — 自研最小 CT**(Path A 不可行时):
- 选 Fair-Rite #43 磁芯,5-7 匝 Teflon 线绕组,50Ω 端接 SMA 输出
- 性能预期:1 MHz – 300 MHz 有用(EM Eye Table II 中多数家用摄像头在此范围内)
- BOM:<¥100
- 开发时间:1-2 天
- 局限:>500 MHz 性能差,无法验证 Pixel 1 (1649 MHz)、Dafang 高频谐波等

### Phase 0 输出(预期)
- 电源线传导泄漏可观测性的 Go/No-Go 判断
- 在自研 CT 可达频率范围内(<300 MHz)的传导损耗实测
- 论文 Table II 12 台设备中,至少 2-3 台在电源线上可观测的频点列表
- Phase 1 是否需要升级耦合方案的判定

---

## 四、Phase 1 工程化采购 🟠(Week 4-16)

**预算上限**:¥15,000(BOM + NRE)

### Phase 1 BOM(USB 供电便携式,单台)

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
| **LNA** | 沿用候选人 ERA-4SM+ × 2 | 0 | BYO,实测 +28 dB |
| | Phase 1 加 PGA-103+ 第三级 | 100 | 总 ~50 dB |
| **滤波 Stage 2**(BPF 组,可选) | Murata SAW ×4 + Peregrine PE42423 | 350 | Phase 0 实测后决定 |
| **SDR** | ADALM-Pluto SOM(沿用) | 0 | BYO |
| **主控** | Raspberry Pi CM4 Lite 8GB WiFi | 800 | 含载板 |
| | CM4 IO Board(开发用) | 200 | 调试 |
| **无线** | 内置 WiFi 6(CM4 自带) | 0 | |
| **电源**(USB 供电,无 AC-DC) | USB-C 接口 + ESD 保护 | 30 | 唯一供电入口 |
| | TI TPS7A47(LNA 模拟 LDO) | 20 | LNA 净化电源 |
| | (~~Mean Well IRM-10-5 删除~~) | 0 | Phase 2 才需要 |
| **PCB** | 4 层 80×60mm 模拟前端板 | 400 | 含贴片,Rogers RO4350B 顶层 |
| | 4 层 80×60mm 数字载板 | 500 | 含贴片 |
| **结构** | 3D 打印 ABS 外壳 + 装配件 | 200 | 100×60×30 mm 可行 |
| **接插件** | SMA + USB-C + 屏蔽罩 + 紧固 | 80 | |
| **单台 Phase 1 BOM 合计** | | | **~¥2,470(不含 Stage 2 BPF) / ~¥2,820(含)** |

**与改动前对比**:省 ~¥1,236(原 ¥3,706 → 新 ¥2,470)。主要砍掉了 AC-DC 模块、市电保护链(GDT/MOV/共模扼流/X1Y2 高压电容)、AC 输入腔体的成本。

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

### 总预算汇总(USB 供电架构后)

| 类别 | 金额(CNY) | 备注 |
|---|---|---|
| 🟢 候选人 Bring-Your-Own 资产 | (估值 ¥10-15k,不计预算) | LNA + Pluto + 工具链 |
| 🟡 Phase 0 采购 | 5,010 | 不买商用探头,自研最小 CT |
| 🟠 Phase 1 BOM(单台原型) | 2,470 – 2,820 | 砍掉 AC-DC 链,USB 供电 |
| 🟠 Phase 1 NRE(PCB/外壳/耗材) | 2,600 | |
| 🔴 Phase 2 采购(集成 + 备份) | 6,600 | |
| **总预算**(Phase 1 USB 架构) | **~¥17,000** | 不含 RA 工资 |
| **加 RA 工资**(6 个月,按 2k/月津贴) | +12,000 | |
| **项目总成本** | **~¥29,000** | |

**对比改动前**:总预算节省 ~¥1,300,但更重要的是:
- ✅ 设备零接触市电 → 安规简化(无 IEC 61010 负担)
- ✅ 形态自由度大幅提升 → 100×60×30 mm 可行
- ✅ 现场部署能力 → 充电宝/笔记本/PoE-USB 都能供电
- ✅ Phase 0 隔离变压器需求消失

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
