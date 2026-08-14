# R 数据流程

本目录公开论文所用的 YouTube 评论采集与预处理流程。代码已移除 API Key、本机绝对路径、原始数据和与论文无关的实验段落。

## 环境

- R 4.1 或更高版本
- `vosonSML`
- `textclean`
- `lexicon`

安装依赖：

```r
install.packages(c("vosonSML", "textclean", "lexicon"))
```

## 处理已有 RDS 数据

把输入文件放在 `data/youtube_comments.rds`，然后运行：

```powershell
Rscript .\code\ragebait_pipeline.R
```

也可以通过环境变量指定路径：

```powershell
$env:INPUT_RDS = "D:\research\youtube_comments.rds"
$env:OUTPUT_DIR = "D:\research\output"
Rscript .\code\ragebait_pipeline.R
```

## 重新采集 YouTube 评论

API Key 只通过环境变量传入，不应写进代码或提交到 Git：

```powershell
$env:COLLECT_FROM_YOUTUBE = "true"
$env:YOUTUBE_API_KEY = "your-key-here"
Rscript .\code\ragebait_pipeline.R
```

采集模式会把 RDS 文件保存在 `INPUT_RDS` 指定的位置，再执行相同的预处理。

## 输出

- `ragebait_all.csv`：清洗后的全部评论；
- `ragebait_parents_only.csv`：仅保留父级评论的分析语料。

`data/`、`output/`、RDS 和 CSV 文件已被 `.gitignore` 排除，不会进入公开仓库。

## 公开边界

本仓库不提供原始评论内容。研究者在重新采集和使用平台数据时，应自行遵守 YouTube API 服务条款、隐私要求与所在机构的研究伦理规范。
