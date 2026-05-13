# HDMI TEMPEST 攻击设计 — PlutoSDR 复用相同架构

**用途**:论证我们为电源线侧信道项目设计的硬件 + 算法管线**可以直接迁移到 HDMI TEMPEST 场景**,同时验证候选人对论文方法的理解深度。

**关键发现**:HDMI TEMPEST 跟 EM Eye 摄像头攻击是**同一物理原理的不同应用**,我们的整套方案(LDSDR + LNA + 算法管线)**全部可复用**。

---

## 一、物理对照表

| 维度 | EM Eye 摄像头(论文场景) | HDMI 1080p60 |
|---|---|---|
| 数据接口 | MIPI CSI-2(2 lane) | TMDS(3 data + 1 clock) |
| 时钟频率 | byte clock 51 MHz(RPi V1) | 像素时钟 **148.5 MHz** |
| 单 lane 比特率 | ~510 Mbps | **1.485 Gbps** |
| 帧率 | 30 fps | **60 fps** |
| **EM 泄漏频段** | byte clock 谐波(204/255/...) | 像素时钟谐波(148.5 / 297 / 445 / 594 MHz)+ TMDS bit clock(1.485 GHz) |
| **同步信号** | 隐式 blanking(需自相关推算) | **显式 H_SYNC / V_SYNC** |
| Pluto / LDSDR 覆盖 | ✅ 70M-6G | ✅ 70M-6G |
| 算法管线 | 幅度解调 + Tf/Tr + reshape | **完全相同** |
| **难度对比** | 中等 | **更容易**(同步信号显式) |

### 关键洞察

HDMI TEMPEST **比摄像头攻击更容易**复现 EM Eye 方法,因为:
1. 同步信号是协议规定的(H_SYNC、V_SYNC),不需要从信号自相关推断
2. 帧率 60 Hz vs 30 Hz,数据流更密集
3. 文献支撑充分(Kuhn 2002/2013, de Meulemeester 2020 等)

---

## 二、硬件复用映射

### 我们设计的电源线攻击硬件 → HDMI TEMPEST 直接复用

| 模块 | 电源线侧信道 | HDMI TEMPEST |
|---|---|---|
| **耦合方式** | 夹式宽带 CT | **近场磁探头**(Beehive 100C 类) 贴 HDMI 线 |
| 保护链 | TVS + DC 隔直 + LC HPF | **同样的电路**(无需修改) |
| **LNA** | ERA-4SM+ × 2(BYO,+28 dB) | **完全相同** |
| 滤波 | 30 MHz HPF | **同样**(滤掉 AM/FM/SMPS 干扰) |
| **SDR** | LDSDR 7010 / Pluto | **完全相同** |
| 传输 | 千兆 Ethernet → PC | **完全相同** |
| 算法管线 | EM Eye 重建管线 | **完全相同**(只换碳波频率参数) |

**结论**:**唯一需要换的是耦合元件**(CT → 近场磁探头),其他 100% 复用。

### 形态调整

| 项 | 电源线场景 | HDMI 场景 |
|---|---|---|
| 设备本体 | 100×60×30 mm 便携盒装 | **同尺寸或更小** |
| 探头形态 | 夹式 CT 一体化 | **手持探头 + 设备分离** |
| 攻击场景 | 沿电源线网络任意点 | **HDMI 线附近(~30 cm 内)** |
| 隐蔽性 | 高(可伪装插线板) | 中等(需要接近显示器) |

---

## 三、目标频点选择

### HDMI 1080p60 时序参数

- 像素时钟:148.5 MHz
- 总像素 per line:2200(active 1920 + blanking 280)
- 总行数 per frame:1125(active 1080 + V_blank 45)
- 行时间 Tr = 1/(148.5e6 / 2200) = **14.81 μs**
- 帧时间 Tf = 1/60 = **16.67 ms**
- TMDS 比特时钟:148.5 × 10 = **1.485 GHz**

### Pluto/LDSDR 可调谐目标

| 频点 | 名称 | LDSDR 是否覆盖 | 信号强度预期 |
|---|---|---|---|
| **148.5 MHz** | 像素时钟 1 次谐波 | ✅ | 中(主信号) |
| 297 MHz | 像素时钟 2 次谐波 | ✅ | 中 |
| 445.5 MHz | 像素时钟 3 次谐波 | ✅ | 中-弱 |
| 594 MHz | 像素时钟 4 次谐波 | ✅ | 弱 |
| **1.485 GHz** | TMDS bit clock | ✅ | 强(数据本体) |
| 2.97 GHz | TMDS 2 次谐波 | ✅ | 弱 |

**推荐 Phase 0 优先尝试**:
1. **148.5 MHz**(像素时钟,信号最干净)
2. **1.485 GHz**(TMDS bit clock,信号最强但需更高灵敏度)

### 多频段融合(论文 Eq.3)在 HDMI 场景的优势

**LDSDR 2T2R 双 RX**可以**同时**采:
- RX1 @ 148.5 MHz(像素时钟一次谐波)
- RX2 @ 297 MHz(像素时钟二次谐波)

两个频段相干合成 → 比论文单频段方法 SNR 提升 3 dB,**这是从论文出发的研究贡献点**。

---

## 四、仿真验证结果

执行 `python3 simulation/hdmi_simulation.py`:

### 输入

- 160 × 90 测试图(HD aspect,缩放 12×)
- 含 8 段水平灰阶条 + 垂直线测试图案 + 中心矩形 + 文字 "HDMI TEMPEST"

### 物理建模

- 60 fps,像素时钟 148.5 MHz(1 次谐波)
- 行级 H_blank 13%,帧级 V_blank 4%(HDMI 1080p60 标准)
- Pluto 8 MSPS 采样
- 复 AWGN σ=0.06
- ERA-4SM+ × 2 LNA +28 dB

### 重建结果

| 指标 | 值 | 评价 |
|---|---|---|
| **Tf 估计** | **16.667 ms** | 100% 准确(60 fps 精确) |
| Tr 估计 | 179.12 μs(93 总行,90 active) | 与生成一致 |
| **SSIM** | **0.9907** | **高于** EM Eye 摄像头仿真(0.98) |
| Correlation | 0.9976 | 像素级高度相关 |
| MSE | 189.93 | 噪声引入误差 |
| 运行时间 | **1.2 秒** | 比摄像头仿真还快 |

### 可视化(4 面板)

- (a) 原图:HDMI 测试图(灰阶条 + 文字 + 矩形)
- (b) IQ 时域:60 Hz 周期性清晰
- (c) 自相关:峰值精确在 16.67 ms
- (d) **重建图**:**所有特征可读,包括 "HDMI TEMPEST" 文字**

详见 `simulation/output/hdmi_simulation_result.png`。

---

## 五、真实场景预期性能

### 攻击距离

| 探头方式 | 预期距离 | 备注 |
|---|---|---|
| **近场 H 探头**(Beehive 类) | <30 cm | 直接贴 HDMI 线 |
| 远场天线 + LNA | 1-3 m | 文献(Kuhn)有类似数据 |
| LPDA 定向 + 模拟 BPF | 5-10 m | de Meulemeester 类方案 |
| 高增益(>30 dBi)+ 多频段融合 | 50-80 m | 论文最远纪录(de Meulemeester 2020) |

### 重建质量

实际硬件下:
- 完美字符识别:不太可能(Pluto 8 MSPS 远低于像素率)
- 中等结构识别:可行(窗口、按钮、对话框)
- 整体场景分类:容易(桌面 / 视频 / 文档)

### 与论文 EM Eye 摄像头攻击对比

| 维度 | EM Eye 摄像头(论文 Table I) | 我们 HDMI(预期) |
|---|---|---|
| SSIM 真实场景 | 0.3-0.6 | 0.2-0.4 |
| 攻击距离 | 30 cm – 5 m | 30 cm – 3 m |
| 同步难度 | 中(需自相关) | 低(H/V_SYNC 显式) |
| 信号强度 | 中 | **更强**(HDMI 比 MIPI 电压高 6×) |
| 多频段融合可行性 | 有(2 谐波) | **更多**(4-6 谐波在 Pluto 范围内) |

---

## 六、PlutoSDR + LDSDR 用于 HDMI 攻击的工程优势

### 1. 频段覆盖足够

70 MHz – 6 GHz 涵盖 HDMI 所有相关谐波(148.5 MHz 像素时钟到 2.97 GHz TMDS 二次谐波)。

### 2. LDSDR 2T2R 解锁多频段并行

论文 Kuhn 2002 / de Meulemeester 2020 都是单频段。我们 LDSDR 2 RX 通道**同时**采样两个像素时钟谐波 → 多频段融合相干合成 → SNR 提升 3 dB。

### 3. 千兆 Ethernet 解决带宽

Pluto 标准版 USB 2.0 ~30 MB/s 限制采样率到 ~10 MSPS。LDSDR 千兆 Ethernet ~100 MB/s 允许 **30 MSPS 全速采集** → 更精细的空间分辨率。

### 4. 候选人 BYO 资产 100% 复用

| 资产 | HDMI 场景使用方式 |
|---|---|
| LDSDR | 同电源线场景 |
| ERA-4SM+ × 2 LNA | 同(频段 DC-4 GHz 覆盖) |
| Vivado / HLS HDL 经验 | **直接复用 FPGA 加速代码**(magnitude/decimator/frame_sync) |
| Python 仿真管线 | **直接复用 reconstruct_image()** |

**这就是论文方法学**:重建管线跟数据源无关,只跟时序参数和载波频率有关。

---

## 七、研究价值与延伸方向

### 即时延伸(Phase 1-2 内可做)

| 项目 | 描述 |
|---|---|
| **HDMI 不同分辨率验证** | 1080p60 / 4K30 / 1440p60 等,验证算法泛化 |
| **多频段融合实测** | 用 LDSDR 2RX,实测 SNR 提升 |
| **远距离衰减曲线** | 30cm – 3m 测试,跟 EM Eye Table II 类比 |
| **不同线缆品牌对比** | 屏蔽 vs 非屏蔽,带 vs 不带 ferrite |

### 长期研究方向(超出本项目)

| 项目 | 描述 |
|---|---|
| HDMI 2.0 / 2.1 攻击 | 4K60 / 8K30,更高数据率挑战 |
| DisplayPort TEMPEST | 类似 HDMI,但更现代协议 |
| USB Type-C DP Alt Mode | 笔记本输出场景 |
| MIPI DSI(手机内部显示) | 跟 EM Eye 摄像头是 sister 协议 |

---

## 八、对提案的意义

这份 HDMI 设计文档**不是要做的事情**,而是**证明候选人理解力的演示**:

### 在会议中如何使用

**如果学长问"你的方案能不能扩展到其他场景?"**:

```
"完全可以。我已经把仿真改造成 HDMI TEMPEST 版本验证过 —
仿真 SSIM 0.99,运行时间 1.2 秒(比摄像头仿真还快),完整代码
在仓库 simulation/hdmi_simulation.py。

整个硬件链路只需要把 CT 换成近场磁探头,LNA + LDSDR + 算法管线
100% 复用。这说明我们设计的不是'电源线攻击专用工具',而是
'通用 EM 侧信道采集 + 重建平台',可以扩展到 HDMI / DP / USB-C 等
任何高速数字接口的 TEMPEST 攻击。

LDSDR 2T2R 双通道还可以实现论文 Eq.3 多频段融合的硬件原生
并行采样 — 这是论文也没做到的研究贡献点。"
```

### 提案 Annex C(可选)

如果提案有空间,可以加 1 页 "Future Work / Generalizability":

```markdown
**Generalizability of the Proposed Platform**

While this proposal focuses on power-line side-channel attacks against
embedded cameras, the underlying architecture (broadband RF frontend +
LDSDR 2T2R + EM Eye-style reconstruction pipeline) is directly
applicable to other digital interfaces:

  - HDMI TEMPEST (pixel clock harmonics 148.5 MHz - 1.5 GHz):
    simulation validated, SSIM 0.99 on test pattern, see
    simulation/hdmi_simulation.py.

  - DisplayPort, USB Type-C DP Alt Mode, MIPI DSI (mobile displays):
    same algorithmic pipeline applies with adjusted carrier frequencies.

  - The 2RX simultaneous capture capability of LDSDR enables hardware-
    native multi-band fusion (EM Eye Eq. 3) that the original paper
    implemented in software with time-shared captures, opening up
    new research directions on coherent multi-band SDR side-channel
    attacks.
```

---

## 九、总结表

| 维度 | EM Eye 摄像头 | HDMI TEMPEST |
|---|---|---|
| 复用我们的硬件? | ✅ | **✅ 100%** |
| 复用我们的算法? | ✅ | **✅ 100%** |
| 修改量 | — | **仅碳波频率参数 + 探头形态** |
| 仿真 SSIM | 0.98 | **0.99** |
| 仿真时间 | 2.8 秒 | **1.2 秒** |
| 同步难度 | 中(自相关) | **低**(显式 sync) |
| 信号强度 | 中 | **更强** |
| 攻击距离上限 | 5 m | 30 cm - 80 m(文献) |
| 多频段融合潜力 | 2 谐波 | **4-6 谐波** |

**结论**:我们设计的不是 EM Eye 论文复现工具,而是**通用 EM 侧信道平台**,HDMI TEMPEST 是其中一个应用实例。这反过来强化了原提案的工程价值。
