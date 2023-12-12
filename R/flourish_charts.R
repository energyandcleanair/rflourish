library(chromote)

ChromoteSession$public_fields$default_timeout <- 60

save_screenshot <- function(id, br, filename, width, height) {
  # Use the embedded chart directly. This automatically sizes to the window.
  br$Page$navigate(
    paste0("https://flo.uri.sh/visualisation/", id, "/embed?auto=1")
  )
  br$Page$loadEventFired()

  # As it resizes to the window, we can set the width and height that we want.
  br$Emulation$setDeviceMetricsOverride(
    width = width, height = height, deviceScaleFactor = 0, mobile = FALSE
  )
  # But setting the device metrics doesn't trigger a resize event - we need
  # to trigger it manually otherwise the charts will look odd.
  br$Runtime$evaluate("window.dispatchEvent(new Event('resize'))")
  Sys.sleep(2)

  # Now we write the image out.
  image_data <- br$Page$captureScreenshot(format = "png")
  writeBin(jsonlite::base64_dec(image_data$data), filename)
}

collect_charts <- function(urls, output_dir, force_rebuild = FALSE) {
  br <- ChromoteSession$new(width = 2000, height = 2000)

  lapply(urls, function(x) {
    id <- x[["id"]]
    file <- x[["filename"]]
    width <- strtoi(x[["width"]])
    height <- strtoi(x[["height"]])

    filename <- paste(output_dir, "/", file, sep = "")

    if (force_rebuild == TRUE | !file.exists(filename)) {
      save_screenshot(
        id = id,
        br = br,
        width = width,
        height = height,
        filename = filename
      )
    }
  })

  br$close()
}
