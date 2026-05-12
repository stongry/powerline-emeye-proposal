# Figures 目录

提案中使用的所有图表 / 测量数据 / 框图源文件。

## 现有文件

### `lna_era4sm_x2_gain.PNG` (待确认)
- **设备**:E5061B Network Analyzer
- **测量**:S21 Log Mag, 5.6 MHz – 3 GHz, IFBW 30 kHz
- **Marker**:100 MHz = −2.05 dB
- **猜测**:候选人自研 ERA-4SM+ × 2 LNA 测试,VNA 输入端串接 30 dB 衰减器保护
- **如猜测正确**:LNA 实际增益 ≈ +28 dB @ 100 MHz, ±3 dB 平坦度跨 5.6 MHz – 3 GHz
- **提案用途**:Ch3 §3.1 Figure 3,作为 LNA 实测增益证据(比论文用文字描述更可信)

### `coupling_probe_s21.PNG` (待确认)
- **设备**:同上 VNA
- **测量**:S21 Log Mag, 5.6 MHz – 3 GHz
- **Marker**:100 MHz = −58.09 dB
- **猜测**:某个宽带 CT 或耦合探头的 S21 特性
- **如猜测正确**:插损 ~−45 dB 平台 (50 MHz – 3 GHz),低频拐点 ~30 MHz
- **关键意义**:如果此探头是 Bring-Your-Own 资产,可省 ¥4,500 + 1-2 个月自研时间

## 待添加(Day 2-5 制作)

- `figure1_system_block_diagram.png/svg` — Ch1 系统总框图(从 day1_decisions.md ASCII 转换)
- `figure2_coupling_protection_schematic.png/svg` — Ch2 耦合 + 保护链原理图
- `figure3_lna_module_layout.png/svg` — Ch3 LNA 模块电路 + PCB 草图
- `figure4_digital_subsystem.png/svg` — Ch4 Pluto + CM4 + WiFi 数字子系统
- `link_budget_table.png` — Ch3 链路预算表(可直接用 Markdown)

## 制图工具建议

- **框图 / 流程图**:draw.io (https://app.diagrams.net),导出 SVG + PNG
- **电路原理图**:KiCad 5/7 (轻量) 或 EasyEDA (Web)
- **波形/曲线复绘**:直接用 VNA 截图原图最有说服力,不必复绘
