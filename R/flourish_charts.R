#' Collect charts from Flourish.
#' @param chart_defs A data frame (with the following columns) or a list of chart definitions (each
#' a list with the following named values):
#' - id: The Flourish chart ID
#' - filename: The output filename
#' - width: The width of the chart
#' - height: The height of the chart
#' - scale: The scale factor for the chart
#' @param output_dir The directory to save the charts to
#' @param error_on_missing_chart Whether to throw an error if any chart is missing or inaccessible.
#' @return NULL
#' @export
#' @examples
#' \dontrun{
#' collect_charts(
#'   chart_defs = list(
#'     list(id = "123456", filename = "chart1.png", width = 800, height = 600, scale = 2),
#'     list(id = "789012", filename = "chart2.png", width = 800, height = 600, scale = 2)
#'   ),
#'   "output_dir"
#' )
#' collect_charts(
#'   chart_defs = data.frame(
#'     id = c("123456", "789012"),
#'     filename = c("chart1.png", "chart2.png"),
#'     width = c(800, 800),
#'     height = c(600, 600),
#'     scale = c(2, 2)
#'   ),
#'   "output_dir"
#' )
#' }
collect_charts <- function(chart_defs, output_dir, error_on_missing_chart = TRUE) {
  # Convert list of lists to data frame if necessary
  if (is.list(chart_defs) && !is.data.frame(chart_defs)) {
    chart_defs <- do.call(rbind, lapply(chart_defs, as.data.frame))
  }

  if (!is.data.frame(chart_defs)) {
    stop("chart_defs must be a data frame or a list of lists")
  }

  required_args <- c("id", "filename", "width", "height", "scale")
  missing_args <- setdiff(required_args, names(chart_defs))
  if (length(missing_args) > 0) {
    stop(glue("Missing required arguments: {paste(missing_args, collapse = ', ')}"))
  }

  br <- ChromoteSession$new(width = 4000, height = 4000)
  br$default_timeout <- 120

  chart_results <- apply(chart_defs, 1, function(chart_def) {
    id <- chart_def[["id"]]
    file <- chart_def[["filename"]]
    width <- as.integer(chart_def[["width"]])
    height <- as.integer(chart_def[["height"]])
    scale <- as.integer(chart_def[["scale"]])

    filename <- paste(output_dir, "/", file, sep = "")

    message(glue("Saving chart {id} to {filename}"))

    result <- get_chart(
      id = id,
      br = br,
      width = width / scale,
      height = height / scale,
      scale = scale
    )

    if (!is.null(result$error)) {
      return(data.frame(
        chart_id = id,
        filepath = NA,
        updated_at = NA,
        error = result$error,
        stringsAsFactors = FALSE
      ))
    }

    writeBin(result$chart_image, filename)

    return(data.frame(
      chart_id = result$chart_id,
      filepath = filename,
      updated_at = result$updated_at,
      error = NA,
      stringsAsFactors = FALSE
    ))
  })

  br$close()

  chart_results_df <- do.call(rbind, chart_results)

  if (error_on_missing_chart) {
    missing_charts <- subset(chart_results_df, !is.na(error))
    if (nrow(missing_charts) > 0) {
      error_summary <- paste(missing_charts$chart_id, collapse = ", ")
      stop(glue("Some charts could not be fetched: {error_summary}"))
    }
  }

  return(chart_results_df)
}


get_chart <- function(id, br, width, height, scale) {
  # Use the embedded chart directly. This automatically sizes to the window.
  url <- paste0("https://flo.uri.sh/visualisation/", id, "/embed?auto=1")
  log_info(glue("Fetching chart at url: {url}"))

  result <- navigate_to_chart(br, url)
  if (result$status != navigation_status$SUCCESS) {
    return(list(
      chart_id = id,
      error = "Chart does not exist or is not public"
    ))
  }

  resize_chart(br, width, height, scale)
  chart_as_bytes <- take_screenshot(br)
  updated_at <- extract_updated_at(br)

  return(list(
    chart_id = id,
    chart_image = chart_as_bytes,
    updated_at = as.Date(updated_at)
  ))
}

navigate_to_chart <- function(br, url) {
  br$Page$navigate(url)
  # Get page title
  page_title_result <- br$Runtime$evaluate("document.title")

  page_title <- page_title_result[[1]]$value

  if (page_title == "403 Forbidden") {
    return(list(
      status = navigation_status$FAILURE
    ))
  }

  br$Page$loadEventFired()

  return(list(
    status = navigation_status$SUCCESS
  ))
}

resize_chart <- function(br, width, height, scale) {
  # As it resizes to the window, we can set the width and height that we want.
  br$Emulation$setDeviceMetricsOverride(
    width = width, height = height, scale = 1, deviceScaleFactor = scale, mobile = TRUE
  )

  # But setting the device metrics doesn't trigger a resize event - we need
  # to trigger it manually otherwise the charts will look odd.
  br$Runtime$evaluate("window.dispatchEvent(new Event('resize'))", timeout_ = 120 * 1000)
  Sys.sleep(2)
}

take_screenshot <- function(br) {
  screenshot_result <- br$Page$captureScreenshot(format = "png")
  as_bytes <- jsonlite::base64_dec(screenshot_result$data)
}

extract_updated_at <- function(br) {
  date_results <- br$Runtime$evaluate(
    "window.template.data.data.timestamps.last_updated.toISOString()",
    timeout_ = 1000
  )
  updated_at <- date_results[[1]]$value
  return(updated_at)
}

navigation_status <- list(
  SUCCESS = "success",
  FAILURE = "failure"
)
