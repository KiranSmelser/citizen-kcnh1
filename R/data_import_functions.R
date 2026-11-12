# Import API and WHO reference loading shared by descriptive scripts.
source(file.path("R", "import_schema.R"))

load_who_lms <- function(parameter) {
  param <- tolower(as.character(parameter))

  .read_lms <- function(path, sex_id) {
    df <- readxl::read_excel(path)

    age_col <- if ("Month" %in% names(df)) "Month" else
      if ("Age" %in% names(df)) "Age" else
      if ("Age (months)" %in% names(df)) "Age (months)" else
      names(df)[1]

    out <- data.frame(
      age = suppressWarnings(as.numeric(df[[age_col]])),
      L   = suppressWarnings(as.numeric(df[["L"]])),
      M   = suppressWarnings(as.numeric(df[["M"]])),
      S   = suppressWarnings(as.numeric(df[["S"]])),
      sex = as.integer(sex_id),
      stringsAsFactors = FALSE
    )

    out <- out[!is.na(out$age) & !is.na(out$L) & !is.na(out$M) & !is.na(out$S), ]
    out
  }

  if (param == "body weight") {
    boys <- .read_lms(PATH_WEIGHT_BOYS, 1L)
    girls <- .read_lms(PATH_WEIGHT_GIRLS, 2L)
    res <- rbind(boys, girls)
  } else if (param == "body height") {
    b_0_2 <- .read_lms(PATH_HEIGHT_BOYS_0_TO_2, 1L)
    b_2_5 <- .read_lms(PATH_HEIGHT_BOYS_2_TO_5, 1L)
    g_0_2 <- .read_lms(PATH_HEIGHT_GIRLS_0_TO_2, 2L)
    g_2_5 <- .read_lms(PATH_HEIGHT_GIRLS_2_TO_5, 2L)
    res <- rbind(b_0_2, b_2_5, g_0_2, g_2_5)
    dup <- duplicated(res[, c("sex", "age")], fromLast = TRUE)
    res <- res[!dup, ]
  } else if (param == "head circumference") {
    boys <- .read_lms(PATH_HEAD_BOYS, 1L)
    girls <- .read_lms(PATH_HEAD_GIRLS, 2L)
    res <- rbind(boys, girls)
  } else {
    stop(sprintf("Unknown parameter '%s' for WHO LMS loading", parameter))
  }

  res$age <- as.integer(round(res$age))
  res
}
