# LaTeX 提案编译说明

## 文件结构

```
latex/
├── proposal.tex      # 主 LaTeX 源(ctexart 中文学术报告模板)
├── proposal.pdf      # 当前编译产物(可直接预览)
├── .gitignore        # 排除编译中间文件
└── README.md         # 本文件
```

## 依赖

**LaTeX 发行版**：TeX Live 2026 或更新(Ubuntu/Debian/Manjaro/macOS MacTeX 均可)

**必需的 TeXLive 软件包**：

```
texlive-xetex        # xelatex 引擎
texlive-langchinese  # ctex + xeCJK 中文支持
texlive-latexextra   # booktabs, tabularx, tcolorbox, listings 等
texlive-fontsextra   # 字体(部分)
texlive-fontsrecommended  # Latin Modern 数学字体
```

**Manjaro/Arch**:
```bash
sudo pacman -S texlive-xetex texlive-langchinese texlive-latexextra \
               texlive-fontsextra texlive-fontsrecommended
```

**Ubuntu/Debian**:
```bash
sudo apt install texlive-xetex texlive-lang-chinese texlive-latex-extra \
                 texlive-fonts-extra texlive-fonts-recommended
```

**macOS** (MacTeX)：默认安装即包含上述所有包。

## 中文字体

模板使用 **思源宋体 CN / 思源黑体 CN**(Adobe Source Han)。
若系统未安装，请安装其中之一：

**Manjaro/Arch**:
```bash
sudo pacman -S adobe-source-han-serif-cn-fonts adobe-source-han-sans-cn-fonts
```

**Ubuntu**:
```bash
sudo apt install fonts-noto-cjk fonts-noto-cjk-extra
# 然后修改 proposal.tex 把 "Source Han Serif CN" 换成 "Noto Serif CJK SC"
```

**macOS**: 系统自带中文字体即可工作；可选下载思源字体替换 `\setCJKmainfont` 参数。

代码块字体 `JetBrains Maple Mono` 可选；若没装，会自动 fallback 到等宽字体。

## 编译

```bash
cd latex/
xelatex -interaction=nonstopmode proposal.tex   # 第 1 次：生成 .aux
xelatex -interaction=nonstopmode proposal.tex   # 第 2 次：解析目录、交叉引用
```

输出 `proposal.pdf`。

**快捷方式**(若有 `latexmk`)：
```bash
latexmk -xelatex proposal.tex
```

## 模板要点

- **文档类**: `ctexart`(标准中文学术报告)
- **字体系统**: xeCJK + 思源字体覆盖中英文,Latin Modern Math 数学字体
- **三线表**: booktabs(`\toprule \midrule \bottomrule`),`tabularx` 自适应宽度
- **代码块**: listings,自定义 verilog / tcl / bash / c 高亮
- **信息盒**: tcolorbox 自定义 `\begin{infobox}` / `\begin{warnbox}`
- **状态徽章**: `\statusok` / `\statuspartial` / `\statusplan`
- **章节样式**: titlesec 自定义,一级标题下加蓝色规则线
- **页眉页脚**: fancyhdr,左侧章节名 + 右侧文档名 + 居中页码
- **超链接**: hyperref 蓝色彩链,自动生成 PDF 书签

## 修改建议

- 候选人姓名: 在封面页 `\textit{(待填写)}` 处修改
- 字体: 修改 `\setCJKmainfont{Source Han Serif CN}` 为其他可用字体
- 边距: 修改 `\usepackage[margin=2.5cm]` 参数
- 章节标题色: 修改 `\titleformat{\section}` 中的 `\color{tablerule}` 颜色
- 信息盒主题色: 修改 `\definecolor{accent}{HTML}{2980B9}`

## 常见问题

**1. 编译报 "Font ... not found"**

字体未装。改用替代字体：在 `\setCJKmainfont` 行替换为 `Noto Serif CJK SC` 或系统已有的中文字体。

**2. 编译报 "Package xeCJK error"**

`texlive-langchinese` 未装。运行 `tlmgr install ctex xecjk`(若用 tlmgr)或安装对应发行版包。

**3. 表格列对不齐**

`tabularx` 的 `X` 列总宽 = `\textwidth` 减掉 `l/c/r` 列固定宽度。如果表格变形，调整列规范如 `lXX` → `p{2cm}p{6cm}X`。

**4. 中文标点位置不对**

`ctex` 默认全角标点已优化，若仍要调，加 `\xeCJKsetcharclass{0xfe50}{0xfe6f}{1}` 等指令。

## 参考

- [ctex 中文文档](https://ctan.org/pkg/ctex)
- [xeCJK 文档](https://ctan.org/pkg/xecjk)
- [TeX Live 安装指南](https://tug.org/texlive/)

