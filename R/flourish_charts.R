save_screenshot <- function(id, br, filename, width, height, scale) {
  url <- paste0("https://flo.uri.sh/visualisation/", id, "/embed?auto=1")
  log_info(glue("Fetching chart at url: {url}"))
  # Use the embedded chart directly. This automatically sizes to the window.
  br$Page$navigate(url)
  br$Page$loadEventFired()

  # As it resizes to the window, we can set the width and height that we want.
  br$Emulation$setDeviceMetricsOverride(
    width = width, height = height, scale = 1, deviceScaleFactor = scale, mobile = TRUE
  )

  # But setting the device metrics doesn't trigger a resize event - we need
  # to trigger it manually otherwise the charts will look odd.
  br$Runtime$evaluate("window.dispatchEvent(new Event('resize'))", timeout_ = 120 * 1000)
  Sys.sleep(2)

  # Now we write the image out.
  image_data <- br$Page$captureScreenshot(format = "png")
  writeBin(jsonlite::base64_dec(image_data$data), filename)
}

#' Collect charts from Flourish.
#' @param chart_defs A vector of chart definitions, each a list containing:
#'  - id: The Flourish chart ID
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

  lapply(chart_defs, function(x) {
    id <- x[["id"]]
    file <- x[["filename"]]
    width <- strtoi(x[["width"]])
    height <- strtoi(x[["height"]])
    scale <- strtoi(x[["scale"]])

    filename <- paste(output_dir, "/", file, sep = "")

    save_screenshot(
      id = id,
      br = br,
      width = width / scale,
      height = height / scale,
      scale = scale,
      filename = filename
    )
  })

  br$close()
}
