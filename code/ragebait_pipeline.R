# YouTube ragebait comment collection and preprocessing
#
# Secrets and machine-specific paths are supplied through environment variables.
# Raw data and generated CSV files are intentionally excluded from this repository.

required_packages <- c("vosonSML", "textclean", "lexicon")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install required packages before running: ",
    paste(missing_packages, collapse = ", ")
  )
}

env_flag <- function(name, default = "false") {
  tolower(trimws(Sys.getenv(name, default))) %in% c("1", "true", "yes")
}

collect_from_youtube <- env_flag("COLLECT_FROM_YOUTUBE")
input_rds <- Sys.getenv("INPUT_RDS", "data/youtube_comments.rds")
output_dir <- Sys.getenv("OUTPUT_DIR", "output")
max_comments <- as.numeric(Sys.getenv("MAX_COMMENTS", "1000000"))

if (is.na(max_comments) || max_comments <= 0) {
  stop("MAX_COMMENTS must be a positive number.")
}

# The final analytic sample: 10 on-camera and 10 voice-over videos.
video_ids <- c(
  OC_1 = "A4jsSuxhooM",
  OC_2 = "CL74JVsprdY",
  OC_3 = "EXTIfkTvgN0",
  OC_4 = "LZwvldLGF3M",
  OC_5 = "uczJV5VHxms",
  OC_6 = "6WBawFVS7VE",
  OC_7 = "gd7VCY_6jjo",
  OC_8 = "F8d3F83SAck",
  OC_9 = "iEnInhLvOM0",
  OC_10 = "iX-Tq4Urhd4",
  VO_1 = "Gd3sql3UG6M",
  VO_2 = "e57HH5I6BoU",
  VO_3 = "S3VB-C8Vbxc",
  VO_4 = "kk6jgleMrck",
  VO_5 = "-uO7YC_otKc",
  VO_6 = "yW7XTGQL8Q8",
  VO_7 = "miFZz_0XfYE",
  VO_8 = "CmcMND9sG2A",
  VO_9 = "Nl-o8ISSrJQ",
  VO_10 = "PmxgMsumWiQ"
)

video_urls <- paste0("https://www.youtube.com/watch?v=", unname(video_ids))

if (collect_from_youtube) {
  api_key <- Sys.getenv("YOUTUBE_API_KEY")
  if (!nzchar(api_key)) {
    stop("YOUTUBE_API_KEY is required when COLLECT_FROM_YOUTUBE=true.")
  }

  youtube_auth <- vosonSML::Authenticate("youtube", apiKey = api_key)
  comments <- vosonSML::Collect(
    youtube_auth,
    videoIDs = video_urls,
    maxComments = max_comments,
    writeToFile = FALSE
  )

  dir.create(dirname(input_rds), recursive = TRUE, showWarnings = FALSE)
  saveRDS(comments, input_rds)
} else {
  if (!file.exists(input_rds)) {
    stop(
      "Input RDS not found: ", input_rds,
      ". Set INPUT_RDS or enable COLLECT_FROM_YOUTUBE."
    )
  }
  comments <- readRDS(input_rds)
}

required_columns <- c(
  "Comment", "ParentID", "VideoID", "ReplyCount", "LikeCount"
)
missing_columns <- setdiff(required_columns, names(comments))

if (length(missing_columns) > 0) {
  stop(
    "Input data is missing required columns: ",
    paste(missing_columns, collapse = ", ")
  )
}

# Normalize text while preserving the original row structure.
comments$Comment <- as.character(comments$Comment)
comments$Comment <- textclean::replace_emoji(
  comments$Comment,
  emoji_dt = lexicon::hash_emojis
)
comments$Comment <- textclean::replace_non_ascii(comments$Comment)
comments$Comment <- gsub("[\r\n]+", " ", comments$Comment)

comments$ReplyCount <- suppressWarnings(as.numeric(comments$ReplyCount))
comments$LikeCount <- suppressWarnings(as.numeric(comments$LikeCount))

parent_id <- as.character(comments$ParentID)
comments$CommentType <- ifelse(
  is.na(parent_id) | !nzchar(parent_id),
  "Parent",
  "Response"
)

source_lookup <- setNames(names(video_ids), unname(video_ids))
comments$Source <- unname(source_lookup[as.character(comments$VideoID)])

if (anyNA(comments$Source)) {
  warning("Some rows have VideoID values outside the 20-video analytic sample.")
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(
  comments,
  file.path(output_dir, "ragebait_all.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

write.csv(
  comments[comments$CommentType == "Parent", , drop = FALSE],
  file.path(output_dir, "ragebait_parents_only.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Preprocessing complete. Output directory: ", output_dir)
