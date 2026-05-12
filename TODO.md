# 6 天行动计划 — 电源线侧信道提案

**起始**:2026-05-12(Day 1)
**提交**:2026-05-17(Day 6 结束)

每天都标注了源文档锚点 — 不偏离 EM Eye 论文 + 功能需求书这两个源。

---

## Day 1(2026-05-12)— 调研 + 6 个核心决策 + 系统框图

**目标**:当天结束时,有一份 1 页的决策表 + 一张手绘框图。**不写正文**。

### 任务清单

- [ ] 重读 EM Eye 论文,只看以下章节(其他对前端无关):
  - [ ] §III(Threat Model)— 攻击场景、设备链路
  - [ ] §V(Eavesdropping System Design)— 重建管线
  - [ ] §VI-A(Experimental Setup)— **关键:fs = 8 MHz, Table II 频点表**
  - [ ] Appendix F(BPF interference filtering)
  - [ ] Appendix H(Eavesdropping Equipment list)— **关键:USRP B210 / FST-RFAMP06 / LPDA 三件套**
- [ ] 把关键论文参数写进 `references/emeye_paper_notes.md`:
  - [ ] USRP B210:70 MHz – 6 GHz, 56 MHz BW, 12-bit, $2100
  - [ ] LNA:FST-RFAMP06,DC – 3.5 GHz, 40 dB, $207
  - [ ] 天线:LPDA, 700 – 4900 MHz, 15 dBi, $15
  - [ ] 采样率:fs = 8 MSPS 所有实验
  - [ ] 频点表:Table II 12 台 COTS,155 MHz – 1.74 GHz
  - [ ] 重建:幅度解调 + Tf/Tr 帧对齐 + 多频段融合 + pix2pix
- [ ] 重读功能需求书,标出:
  - [ ] 形态/尺寸约束(150×80×50mm,两种形态)
  - [ ] 4 个 Function(耦合 / 模拟前端 / 采集 / 传输)
  - [ ] 6 个交付章节
- [ ] 文献快扫(每个搜 10–15 分钟):
  - [ ] "power-line conducted EM emanations TEMPEST"
  - [ ] "broadband ferrite current transformer 1 GHz"
  - [ ] "Hayashi conducted emission display eavesdropping"
- [ ] 锁定 6 个核心决策,写成 1 页决策表:
  1. **形态**:便携集成式(Route A)— 插头式(Route B)作为 Phase 2
  2. **耦合**:宽带 CT(Fair-Rite 铁氧体 + 多匝绕组)主 + 电容耦合辅
  3. **保护链**:GDT + MOV + 共模扼流 + TVS + 隔直 + LC HPF(截止 ≥1 MHz)
  4. **LNA**:PGA-103+ 级联 ZX60-P103LN+ → 40 dB(对标 FST-RFAMP06)
  5. **SDR + 主控**:ADALM-Pluto SOM(Zynq xc7z010, AD9363)+ Raspberry Pi CM4 8GB
  6. **传输**:v1 原始 IQ over WiFi 6;v2 板上解调 over WiFi 4 / BT
- [ ] 手绘系统框图(7 模块)— 拍照存到 `figures/day1_block_diagram.jpg`
- [ ] `git commit -m "day1: 调研笔记 + 决策表 + 框图"`

### 自检
- 每个决策都能锚回论文或需求书?如有"我觉得"成分,要么找依据,要么标"未决"。

---

## Day 2(2026-05-13)— 写 Ch1 + Ch2(关键章节)

**目标**:Ch1(1 页)+ Ch2(2–3 页)一稿完成在 `docs/proposal_draft.md`。

### 任务清单

- [ ] **Ch1 — 形态 + 框图**(1 页)
  - [ ] 论证选 Route A 的理由(风险更低,做出来再迭代到插头式)
  - [ ] 插入 Figure 1(系统框图,Day 1 的手绘图)
  - [ ] 说明尺寸预算 150 × 80 × 50 mm
  - [ ] 锚点:需求书"设备形态要求"

- [ ] **Ch2 — 耦合与提取**(2–3 页,最被审视的章节)
  - [ ] §2.1 物理机制:CM 电流沿电源线传导,MIPI byte-clock 谐波辐射
    - 锚点:EM Eye §III "cable acts as unintentional transmission antenna"
    - 论证:同一原理适用于电源线
  - [ ] §2.2 耦合方式权衡表(CT vs 电容 vs LISN)
  - [ ] §2.3 选定架构(CT 主 + 电容辅)
  - [ ] §2.4 保护 + 隔离链(逐元件)
  - [ ] §2.5 已知风险(>500 MHz 磁芯,损耗未知)
  - [ ] 插入 Figure 2(耦合 + 保护原理图)
- [ ] `git commit -m "day2: ch1 + ch2 一稿"`

### 自检
- Ch2 至少 2 处直接引用 EM Eye 论文
- 耦合表 3 个候选 + 具体理由

---

## Day 3(2026-05-14)— 写 Ch3 + Ch4

**目标**:Ch3(2 页)+ Ch4(2 页)一稿完成。

### 任务清单

- [ ] **Ch3 — 模拟前端**(2 页)
  - [ ] §3.1 架构:总增益 40 dB,NF < 3 dB,100M–1G 平坦
    - 锚点:EM Eye Appendix H(FST-RFAMP06)+ 需求书 Function 2(30–40 dB)
  - [ ] §3.2 链路预算表(Table 2,数字自洽)
  - [ ] §3.3 可选 BPF 组
    - 锚点:EM Eye Appendix F 指出 BPF 是改进方向
  - [ ] §3.4 PCB 叠层 + 屏蔽
  - [ ] 插入 Figure 3(LNA 原理图)
- [ ] **Ch4 — 采集 + 无线**(2 页)
  - [ ] §4.1 SDR:ADALM-Pluto
    - 锚点:需求书 Function 3(100M–1G, >10 MSPS)— Pluto 70M–6G, 支持 30 MSPS
    - **着重写候选人 OFDM+LDPC Pluto 经验** — 这是差异化关键
  - [ ] §4.2 采样策略:fs = 8–20 MSPS, 锁 MIPI byte-clock 谐波
    - 锚点:EM Eye Table II 频点表
  - [ ] §4.3 传输决策表(原始 IQ vs 板上重建)
    - 锚点:需求书 Function 4 原文"若无线传输带宽不足..."
    - 选:v1 原始 IQ, v2 板上加速
  - [ ] §4.4 无线:WiFi 6 (RTL8852BE)
  - [ ] §4.5 主控:Raspberry Pi CM4
  - [ ] §4.6 Sidebar — 板上加速路线图(差异化亮点)
  - [ ] 插入 Figure 4(数字子系统框图)
- [ ] `git commit -m "day3: ch3 + ch4 一稿"`

### 自检
- 链路预算数字自洽
- IQ vs 板上重建决策同时锚 Function 4 原文 + 论文 §V

---

## Day 4(2026-05-15)— 写 Ch5 + Ch6 + 风险 + Annex

**目标**:正文 6 章 + 风险段 + Annex 全部一稿完成。

### 任务清单

- [ ] **Ch5 — BOM**(1–2 页)
  - [ ] 完整 Table 4(每模块:主选 / 替代 / 理由)
  - [ ] 快速核对元件可获性(Pluto / CM4 / RTL8852BE / Fair-Rite / PGA-103+ 等)— DigiKey/Mouser 搜一下,不可获的标 ⚠️
- [ ] **Ch6 — 成本估算**(1 页)
  - [ ] BOM 小计:~ ¥4350
  - [ ] NRE:~ ¥5300
  - [ ] 工时:1 RA × 6 个月
  - [ ] 分阶段:Phase 0(3 周)→ Phase 1(3 个月)→ Phase 2(2 个月)
- [ ] **§7 风险与未决问题**(½ 页)
  - [ ] 电源线传导损耗未知
  - [ ] >500 MHz 磁芯不确定
  - [ ] COTS 设备差异
  - [ ] 法规:EMC Class B + IEC 61010
  - [ ] Pluto 供应
- [ ] **Annex A — 候选人相关经验**(1 页)
  - [ ] Pluto OFDM+LDPC,BER = 0
  - [ ] XCZU3EG PL CNN,87.94% / 675 ms,github.com/stongry/FPGA-ZYNQ
  - [ ] RK3568 Ubuntu + RKNN
  - [ ] EC800M 语音 AI
  - [ ] Smart-home Slint 62.97 fps
- [ ] `git commit -m "day4: ch5+ch6 + 风险 + annex 一稿"`

### 自检
- BOM 数字在 Ch5 和 Ch6 之间一致
- Annex 每个项目都有一行**量化结果**

---

## Day 5(2026-05-16)— 封面 + 摘要 + 加分 Sidebar + 内审

**目标**:完成前置内容 + 2 个亮点 Sidebar + 第一次完整通读。

### 任务清单

- [ ] **封面页**(½ 页)— 标题、候选人、日期、目标实验室
- [ ] **Executive Summary**(½ 页)— 一段话 + 4 个 bullet
- [ ] **Sidebar 1**(Ch4 内):**Board-Side Acceleration Roadmap**(已部分起草,精修)
  - 重点:利用 Pluto 内置 Zynq-7010 PL,实现 |I+jQ| + 30 Hz 自相关,把传输从 192 Mbps IQ 降到 30 Mbps 解调流
  - 强调候选人具备该平台直接 HDL 经验
- [ ] **Sidebar 2**(Ch2 或 Ch4 内):**OFDM 同步与 EM Eye Tf/Tr 估计的工程类比**
  - 引用候选人 OFDM 项目中 cp_remove / cp_insert / subcarrier_map 等 sample-offset bug 的 debug 经验
  - 论证同种 autocorrelation + offset-correction 方法可直接迁移到 EM 信号帧对齐
- [ ] **可选 Sidebar 3**:频点自学习算法(扫频 + 30 Hz 自相关检测未知摄像头谐波)— 篇幅允许才加
- [ ] **第一次完整通读** — typo / 紧凑性 / claim 链
- [ ] **核对所有引用**:
  - EM Eye 论文(Long et al., NDSS 2024)正确引用
  - 至少 2 篇 TEMPEST 经典(van Eck 1985, Kuhn 2002, Hayashi)
- [ ] **核对所有图表编号 + 文中引用**
- [ ] **可选**:微信给闫浩然学长(WX-YANHaoran)发 1 个具体技术问题
  - 建议问题:"想请教学长,你们做电源线传导泄漏验证时用的是 LISN 还是夹式 CT?在 100M-1G 频段有典型衰减数据吗?"
  - 这本身就是积极信号
- [ ] `git commit -m "day5: 封面 + 摘要 + sidebar + 内审"`

### 自检
- 不含 Annex 篇幅 7–10 页;含 Annex ≤15 页
- 每章至少 1 张图或 1 个表

---

## Day 6(2026-05-17)— 精修 + 导出 PDF + 提交

**目标**:PDF 到手,邮件发出。

### 任务清单

- [ ] 第二次完整通读(focus on flow,非 typo)
- [ ] 调整长短失衡章节
- [ ] 格式核对(标题层级、寡行、字号统一)
- [ ] 导出 PDF
  - 文件名:`PowerLineSideChannel_Proposal_[姓名]_2026-05.pdf`
- [ ] git tag `v1.0-submission`
- [ ] 起草邮件回复 Yan(CC 闫浩然如适用):
  - 3 句正文,例如:
    > Dear Prof. Long,
    >
    > Attached is the design proposal in response to the problem description for the power-line side-channel acquisition device. I have organized the design around the 6-chapter structure specified in the document, with additional sections on risks and relevant prior experience. A private GitHub repo for ongoing tracking is available at github.com/stongry/powerline-emeye-proposal if useful for review.
    >
    > I would be glad to discuss any aspect of the proposal in more detail. Thank you for the opportunity to apply.
  - 附 PDF
- [ ] 最终发送前检查:
  - [ ] PDF 能打开,所有图表正常渲染
  - [ ] 无残留批注 / 修订
  - [ ] PDF 元数据作者信息正确(File → Properties)
  - [ ] 邮件语气专业、简洁、自信不自负
  - [ ] 仓库目前是 private,确认 Yan/闫浩然问起来时能加他们权限
- [ ] 发送
- [ ] `git commit -m "day6: submission v1.0"`

---

## 每日时间预算

每天预计 4–6 小时专注工作。如果某天超期,把溢出推到次日,**不要跳过当天自检**。

| Day | 焦点 | 输出 | 小时 |
|---|---|---|---|
| 1 | 调研 + 决策 + 框图 | 决策表 + 框图 | 4–5 |
| 2 | Ch1 + Ch2(关键) | ~3 页 | 5–6 |
| 3 | Ch3 + Ch4 | ~4 页 | 5–6 |
| 4 | Ch5 + Ch6 + 风险 + Annex | ~3 页 | 4–5 |
| 5 | 前置 + Sidebar + 内审 | 精修 + 亮点 | 4–5 |
| 6 | 精修 + PDF + 提交 | 提交 | 3–4 |

---

## 红线(任何一条都会让提案掉到普通候选人池)

1. ❌ 通篇罗列器件,缺技术判断
2. ❌ 不引用 EM Eye 论文具体细节(只笼统说"扩展该论文")
3. ❌ 假装什么都搞得定,不标风险
4. ❌ 忽略需求书原文措辞,自创要求
5. ❌ 不提候选人 Pluto OFDM 经验(这是最大杠杆)
6. ❌ 最终交付超过 15 页(PI 时间宝贵)
