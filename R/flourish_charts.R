library(chromote)

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

collect_charts <- function(urls, output_dir, force_rebuild = FALSE) {
  set_chrome_args(
    c(
      default_chrome_args(),
      "--force-prefers-reduced-motion"
    )
  )
  br <- ChromoteSession$new(width = 4000, height = 4000)
  br$default_timeout <- 120

  lapply(urls, function(x) {
    id <- x[["id"]]
    file <- x[["filename"]]
    width <- strtoi(x[["width"]])
    height <- strtoi(x[["height"]])
    scale <- strtoi(x[["scale"]])

    filename <- paste(output_dir, "/", file, sep = "")

    if (force_rebuild == TRUE | !file.exists(filename)) {
      save_screenshot(
        id = id,
        br = br,
        width = width / scale,
        height = height / scale,
        scale = scale,
        filename = filename
      )
    }
  })

  br$close()
}
