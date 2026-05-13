# 仿真实现盘点 + 会议话术

**用途**:今晚会议中诚实说明仿真做到了什么、没做什么。**话术不当 → 露馅扣分;话术得当 → 工程节制加分**。

---

## 仿真的真实状态:三层区分

### ✅ 真正实现的(算法可运行,数学正确)

| 功能 | 代码位置 | 状态 |
|---|---|---|
| 幅度解调 `|I + jQ|` | `reconstruct_image()` Step 1 | ✅ 完整,论文 Eq. 2 |
| 归一化自相关 Tf 估计 | `estimate_tf()` | ✅ 粗精两级 + 样本数归一化 |
| 行周期 Tr 推算 | Step 4 | ✅ Tr = Tf / H_expected |
| 1D → 2D reshape | Step 5 | ✅ 按估算 Tr_samples 重排 |
| 像素时间槽降采样 | Step 6 | ✅ 块平均到目标宽度 |
| 直方图均衡 | Step 7 | ✅ 0-255 归一化 |
| 质量评估 | `compute_metrics()` | ✅ SSIM + Correlation + MSE |
| 4 面板可视化 | `visualize_pipeline()` | ✅ matplotlib |

**这一部分是真东西**,跟硬件无关,Phase 0 真实数据到货后直接复用。

---

### 🟡 仿真桩(函数存在但没做真实事)

| 功能 | 代码实际做了什么 | 现实中应该是什么 |
|---|---|---|
| `simulate_em_leakage()` | **生成假 IQ 数据**:每像素分配时间槽,amplitude=像素值 | 真 SDR 通过 libiio 流式捕获 |
| `simulate_wireless_transmission()` | 只打印带宽估算,返回 IQ 副本 | TCP/UDP socket over Gigabit Ethernet |
| LNA 增益 | 标量乘法 `iq *= 10^(28/20)` | 真实 CT → LNA → AD9363 链 |
| 噪声模型 | 复 AWGN, σ=0.06 | 真实有 AM/FM/SMPS 结构化干扰 |
| 频率配置 | 硬编码 204 MHz, 8 MSPS | LDSDR iio 命令配置 |

---

### ❌ 完全没实现的(论文有但代码没)

| 论文/计划功能 | 没实现原因 |
|---|---|
| 多频段融合(EM Eye Eq. 3) | 需要 2 RX 通道并行,Phase 1+ |
| pix2pix GAN 图像翻译 | 需要训练数据集,Phase 2 |
| 极性反转校正 | 需要双天线对照 |
| 真实 GNURadio flowgraph | 需要实物 LDSDR |
| libiio 集成 | 需要硬件 |
| TCP socket 网络 | 需要 LDSDR PS Linux |
| FPGA HDL 板上加速 | Phase 2 工程路线 |
| Stage 1 HPF 数字实现 | 仿真直接生成基带,不需要 |
| 频点扫描 / 自动锁定 | 仿真给定频点 |
| 实时流处理 | 批量处理 |
| 多帧平均 | 当前取第 1 帧 |

---

## 实测仿真结果(可现场演示)

输入:160×80 合成测试图(渐变 + 同心方框 + 文字 + 亮点)
输出:

| 指标 | 值 | 评价 |
|---|---|---|
| Tf 估计 | **33.333 ms** | 100% 准确 |
| Tr 估计 | 416.62 us | 与生成参数完全匹配 |
| **SSIM** | **0.9800** | 几乎完美重建 |
| Correlation | 0.9982 | 像素级高度相关 |
| MSE | 449 | 仅噪声引入误差 |
| 总运行时间 | **2.8 秒** | 端到端可现场演示 |

---

## 会议话术

### ✅ 可以说的(经得起追问)

```
1. "我用 Python 实现了 EM Eye 论文的完整重建管线 — 幅度解调、自相关 
   Tf 估计、2D 重建、直方图归一化、SSIM 评估。"

2. "端到端跑通,合成测试图 SSIM 0.98,运行时间 2.8 秒。"

3. "算法跟硬件无关,Phase 0 拿到 LDSDR + Tekbox 后,只需把仿真里的 
   IQ 源替换成真实采集,后面管线不动。"

4. "EM Eye Eq.3 多频段融合 和 pix2pix GAN 这两块论文 SOTA 我没做,
   留 Phase 1-2 工程化时引入。"

5. "Phase 2 板上加速我已经开始写 FPGA HDL(基于我的 LDSDR OFDM+LDPC
   项目经验)。"
```

### ❌ 不能说的(会露馅)

```
1. ❌ "我做了 SDR 真实采集" 
   → 真相:IQ 是合成的,没碰过硬件

2. ❌ "我跑过真实硬件"
   → 真相:LDSDR 没动过

3. ❌ "我验证了链路预算"
   → 真相:只验证了算法,没验证物理层

4. ❌ "我做了 GNURadio flowgraph"
   → 真相:纯 Python

5. ❌ "我证明了 SNR 35dB 够用"
   → 真相:SNR 是基于假设算的,实物未测
```

### 🟡 模糊话术(可用但要谨慎)

| 表述 | 评级 | 备注 |
|---|---|---|
| "Simulation models the EM leakage from MIPI byte-clock harmonics" | ✅ OK | 准确,主动说是 simulation |
| "I've implemented the EM Eye reconstruction pipeline" | ✅ OK | 确实实现了 |
| "I've simulated the SDR acquisition" | ⚠️ 边界 | 字面 OK,但听起来像做了硬件 |
| "I've validated the design" | ❌ 避免 | 听起来像物理层也验证了 |
| "I've tested the link budget" | ❌ 避免 | 同上 |
| "The algorithm is verified" | ✅ OK | 算法确实验证了 |

---

## 会议典型场景应对

### 场景 1:学长问"你的算法管线靠不靠谱"

```
"我已经在 Python 上跑了完整端到端仿真,合成图测试 SSIM 0.98,
运行时间 2.8 秒。仓库 simulation/ 里有代码,我可以发您看。
不过这是合成 IQ 数据,真实物理层验证要 Phase 0 第 2 周才能做。"
```

### 场景 2:学长问"实物到货之前你能做什么"

```
"算法部分已经跑通,Phase 0 第 1 周拿到设备后,我只需要把仿真里的 
simulate_em_leakage() 替换成 LDSDR 实际捕获,后面管线完全一样,
不用改代码。"

"另外 Phase 2 的 FPGA 板上加速我已经开始写 HDL 骨架,基于我之前的
OFDM+LDPC LDSDR 项目经验,大概 3 个月可以完成。"
```

### 场景 3:学长想看 demo

```
你: 屏幕共享,在终端运行:
    cd simulation && python3 emeye_simulation.py
    
2.8 秒后弹出 4 面板可视化,直接展示。

如果学长追问"这是真硬件吗?":
"不是,这是 Python 仿真,IQ 数据是按论文信号模型合成的。
真实硬件 Phase 0 第 1 周开始接入。"
```

### 场景 4:学长追问"你怎么知道 +28 dB LNA 增益对的"

```
"+28 dB 是我用 VNA E5061B 实测的,在 100 MHz 处 -2 dB(扣除 30 dB 
pad)。仓库 figures/lna_era4sm_x2_gain.PNG 是当时的截图。

但其他链路参数(NF、IP3、AD9363 内部 NF 等)都是数据手册值,没自己
测过。Phase 0 第 1 周要逐项实测。"
```

### 场景 5:学长追问"为什么 SSIM 0.98 这么好"

```
"因为合成图比真实摄像头图像简单很多 — 没有真实场景的复杂纹理,
噪声也是纯 AWGN 没有结构化干扰。论文真实摄像头 SSIM 大概 0.3-0.6
区间(Table I)。

我的 SSIM 0.98 主要证明算法管线正确,不证明真实场景效果一样好。
真实场景下我估计 SSIM 在 0.2-0.5 区间,需要 Phase 1 引入多频段融合
+ pix2pix GAN 才能提到论文 SOTA 水平。"
```

---

## 总结心法

**诚实优先于光鲜**:
- 主动说"这是仿真,IQ 是合成的"
- 主动说"物理层我没测"
- 主动说"多频段融合和 GAN 我没做,Phase 1-2 引入"

**给数字优于给形容词**:
- 不要说"效果很好",说 "SSIM 0.98"
- 不要说"运行很快",说 "2.8 秒"
- 不要说"带宽足够",说 "192 Mbps,Ethernet 800 Mbps 留余量"

**标边界优于假装全能**:
- "算法部分跑通" vs "整个系统跑通" — 差异巨大
- "Phase 0 实测" vs "已经验证" — 差异巨大

会议中重复这些原则,**Yan 团队会信任你的工程节制**。
