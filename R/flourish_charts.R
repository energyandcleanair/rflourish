#' Collect charts from Flourish.
#' @param chart_defs A list of chart definitions, each a list containing:
#' - id: The Flourish chart ID
#' - filename: The output filename
#' - width: The width of the chart
#' - height: The height of the chart
#' - scale: The scale factor for the chart
#' @param output_dir The directory to save the charts to
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
#' }
collect_charts <- function(chart_defs, output_dir) {
  set_chrome_args(
    c(
      default_chrome_args(),
      "--force-prefers-reduced-motion"
    )
  )
  br <- ChromoteSession$new(width = 4000, height = 4000)
  br$default_timeout <- 120

  lapply(chart_defs, function(chart_def) {
    if (!is.list(chart_def)) {
      stop("chart_defs must be a list of lists")
    }

    required_args <- c("id", "filename", "width", "height", "scale")
    actual_args <- names(chart_def)
    if (!all(required_args %in% names(chart_def))) {
      joined_missing_args <- paste(setdiff(required_args, actual_args), collapse = ", ")
      stop(glue("Missing required arguments: {joined_missing_args}"))
    }
  })

  chart_results <- lapply(chart_defs, function(chart_def) {
    id <- chart_def[["id"]]
    file <- chart_def[["filename"]]
    width <- strtoi(chart_def[["width"]])
    height <- strtoi(chart_def[["height"]])
    scale <- strtoi(chart_def[["scale"]])

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
      return(result)
    }

    writeBin(result$chart_image, filename)

    return(
      list(
        chart_id = result$chart_id,
        filepath = filename,
        updated_at = result$updated_at
      )
    )
  })

  br$close()

  return(
    chart_results
  )
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
