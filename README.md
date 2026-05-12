# 电源线侧信道采集设备 — 设计提案

**用途**:Yan Long 教授实验室(NDSS 2024 EM Eye 论文作者,密歇根大学)RA 岗位申请提案。

**截止**:2026-05-12 起 6 天,目标 2026-05-17 提交。

**当前阶段**:计划与起草。

---

## 这个仓库是干嘛的

工作仓库,用于起草、迭代、最终交付一份**电源线侧信道小型化采集设备**的设计提案文档。该项目是把 EM Eye 攻击(Long et al., NDSS 2024)从空气电磁辐射延伸到电源线传导泄漏。

最终交付物是单份 PDF,严格按照功能需求文档指定的 6 章结构撰写。

## 仓库结构

```
.
├── README.md                          # 本文件 — 快速状态 + 检查清单
├── OUTLINE.md                         # 完整提案大纲(6 章 + 风险 + Annex)
├── TODO.md                            # 6 天行动计划 + 复选框
├── docs/
│   └── proposal_draft.md              # 提案正文草稿(逐日填充)
├── references/
│   └── emeye_paper_notes.md           # EM Eye 论文压缩笔记
└── figures/                           # 系统框图、链路预算图等
```

## 快速状态

- [ ] Day 1 (05-12) — 调研 + 6 个核心决策 + 框图
- [ ] Day 2 (05-13) — 写 Ch1 形态 + Ch2 耦合(关键章节)
- [ ] Day 3 (05-14) — 写 Ch3 模拟前端 + Ch4 采集/传输
- [ ] Day 4 (05-15) — 写 Ch5 BOM + Ch6 成本 + 风险 + Annex
- [ ] Day 5 (05-16) — 封面 + 摘要 + 加分 Sidebar + 内审
- [ ] Day 6 (05-17) — 精修 + 导出 PDF + 邮件提交

## 候选人相关经验(写进 Annex)

| 项目 | 硬件平台 | 关键结果 |
|---|---|---|
| OFDM+LDPC PlutoSDR 收发机 | Zynq xc7z010 (Pluto) | BER = 0 板级验证,完整 HDL |
| XCZU3EG PL CNN 部署 | Zynq UltraScale+ | 87.94% / 675ms 端到端 LPR |
| RK3568/RK3588 Ubuntu + RKNN | Rockchip + NPU | 嵌入式 Linux + 边缘 AI |
| EC800M 语音 AI | Quectel 通信模块 | 完整无线集成 |
| Smart-home Slint UI | RK3588 面板 | 62.97fps(面板上限) |

这些经验**正好覆盖了本项目的全部技术栈**(Pluto HDL、FPGA 加速、嵌入式 Linux、无线集成、系统整合),是这份提案最大的差异化优势。

## 怎么用这个仓库

1. 打开 `OUTLINE.md` 看完整提案结构
2. 打开 `TODO.md` 看当天该做什么
3. 把内容写进 `docs/proposal_draft.md`,逐章推进
4. 每天至少 commit 一次,进度可被检索
5. Day 6 导出 PDF,作为邮件附件提交

## 最终提交检查清单

- [ ] 篇幅 7–10 页(最多 15 页含 Annex)
- [ ] 系统框图
- [ ] 链路预算表
- [ ] BOM 表
- [ ] 成本估算(BOM + NRE + 工时)
- [ ] 正确引用 EM Eye 论文(Long et al., NDSS 2024)
- [ ] 引用 2–3 篇 TEMPEST 经典工作
- [ ] 风险/未知段落(诚实标注)
- [ ] 候选人经验 Annex(1 页)
- [ ] PDF 文件名:`PowerLineSideChannel_Proposal_[姓名]_2026-05.pdf`

## 关键工作约束

1. **严格贴合两份源文档**:EM Eye 论文 + 功能需求书。每一处技术 claim 都要能追溯到其中一份。
2. **中文工作 / 英文交付**:仓库内 README/OUTLINE/TODO 用中文方便自己,**最终提案 PDF 用英文**(因为 Yan Long 在 U Michigan,邮件本身也是英文)。
3. **诚实优先于全能**:不会的明确说不会,提议 Phase 0 实测,这对 PI 是加分项。
