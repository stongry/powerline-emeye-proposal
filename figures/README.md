# Figures 目录

提案中使用的所有图表 / 测量数据 / 框图源文件。

## 现有文件(候选人 BYO 实测数据)

### `lna_era4sm_x2_gain.PNG` ✅ 已确认
- **设备**:E5061B Network Analyzer
- **测量**:S21 Log Mag, 5.6 MHz – 3 GHz, IFBW 30 kHz
- **DUT**:候选人自研 ERA-4SM+ × 2 级联 LNA(**通电状态**)+ 30 dB 输出衰减器(保护 VNA)
- **Marker @ 100 MHz**:−2.05 dB(显示值)→ 扣除 30 dB pad → **实际增益 +27.95 dB**
- **实测特性**:
  - 5.6 MHz – 3 GHz 全带宽工作
  - 增益 ~28 dB ± 3 dB(平坦度尚可)
  - 在 200-700 MHz 段(EM Eye 主目标频段)增益最强
- **提案用途**:Ch3 Figure 3 — LNA 实测增益证据

### `lna_era4sm_x2_off.PNG`(原 Capture1.PNG)✅ 已确认
- **设备**:同上 VNA
- **DUT**:同一个 ERA-4SM+ × 2 LNA(**断电状态**)+ 30 dB pad
- **Marker @ 100 MHz**:−58.09 dB
- **意义**:LNA 断电时的通过隔离度测试
  - 通电 vs 断电 增益差 ≈ 56 dB @ 100 MHz(开关比足够好)
  - 高频 (>300 MHz) 寄生穿透 ~−42 dB(典型的 RF 放大器关断特性)
- **提案用途**:可选 Figure 3 辅助 — 证明 LNA 没有 RF 短路风险

## 待添加(Day 2-5 制作)

- `figure1_system_block_diagram.png/svg` — Ch1 系统总框图
- `figure2_coupling_protection_schematic.png/svg` — Ch2 耦合 + 保护链
- `figure3_lna_link_budget_table.png` — Ch3 链路预算表
- `figure4_digital_subsystem.png/svg` — Ch4 Pluto + CM4 + WiFi

## 候选人不购置的设备(明确约束)

❌ **不采购任何商用 RF 探头**(Tekbox / Fischer / Pearson 等)

**替代方案**:
- Phase 0 实测 → **依赖实验室公共设备**(假设有宽带电流探头或 LISN)
- 如实验室也无 → **自研最小 CT**(Fair-Rite 磁芯 + 手绕,BOM <¥100,1-2 天)

## 制图工具建议

- 框图 / 流程图:draw.io (https://app.diagrams.net),导出 SVG + PNG
- 电路原理图:KiCad 5/7 或 EasyEDA (Web)
- 波形/曲线:直接用 VNA 截图原图最有说服力,不必复绘
