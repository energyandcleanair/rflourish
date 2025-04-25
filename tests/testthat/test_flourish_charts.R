library(testthat)
library(mockery)

test_that("collect_charts saves screenshot correctly", {
  encoded_base64 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64 <- jsonlite::base64_dec(encoded_base64)

  mock_br <- list(
    Page = list(
      navigate = mock(),
      loadEventFired = mock(),
      captureScreenshot = mock(list(data = encoded_base64))
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock()
    ),
    default_timeout = NULL,
    close = mock()
  )
  # Mock writeBin and Sys.sleep
  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_screenshot, "Sys.sleep", mock_sleep, depth = 2)

  # Define a single chart definition
  chart_defs <- list(
    list(
      id = "123456",
      filename = "chart1.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  # Call the function
  collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")

  # Check arguments passed to mocked methods
  expect_args(mock_write_bin, 1, decoded_base64, "mock_output_dir/chart1.png")
})


test_that("collect_charts uses the browser correctly", {
  call_log <- c()
  create_logged_mock <- function(call_name, return_value = NULL) {
    mock({
      call_log <<- c(call_log, call_name)
      if (!is.null(return_value)) {
        return(return_value)
      }
      return(invisible())
    })
  }

  mock_br <- list(
    Page = list(
      navigate = create_logged_mock("navigate"),
      loadEventFired = create_logged_mock("loadEventFired"),
      captureScreenshot = create_logged_mock(
        "captureScreenshot",
        list(data = jsonlite::base64_enc(charToRaw("test")))
      )
    ),
    Emulation = list(
      setDeviceMetricsOverride = create_logged_mock("setDeviceMetricsOverride")
    ),
    Runtime = list(
      evaluate = create_logged_mock("evaluate")
    ),
    default_timeout = NULL,
    close = create_logged_mock("close")
  )

  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_screenshot, "Sys.sleep", mock_sleep, depth = 2)

  # Define a single chart definition
  chart_defs <- list(
    list(
      id = "123456",
      filename = "chart1.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  # Call the function
  collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")

  # Verify the order of calls
  expect_equal(
    call_log,
    c(
      "navigate",
      "loadEventFired",
      "setDeviceMetricsOverride",
      "evaluate",
      "captureScreenshot",
      "close"
    )
  )
  expect_args(mock_br$Page$navigate, 1, "https://flo.uri.sh/visualisation/123456/embed?auto=1")
  expect_args(
    mock_br$Emulation$setDeviceMetricsOverride, 1,
    width = 400, height = 300, scale = 1, deviceScaleFactor = 2, mobile = TRUE
  )
  expect_args(
    mock_br$Runtime$evaluate, 1,
    "window.dispatchEvent(new Event('resize'))",
    timeout_ = 120 * 1000
  )
})

test_that("collect_charts saves multiple correctly", {
  encoded_base64_1 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64_1 <- jsonlite::base64_dec(encoded_base64_1)

  encoded_base64_2 <- jsonlite::base64_enc(charToRaw("test2"))
  decoded_base64_2 <- jsonlite::base64_dec(encoded_base64_2)

  mock_br <- list(
    Page = list(
      navigate = mock(),
      loadEventFired = mock(),
      captureScreenshot = mock(
        list(data = encoded_base64_1),
        list(data = encoded_base64_2)
      )
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock()
    ),
    default_timeout = NULL,
    close = mock()
  )
  # Mock writeBin and Sys.sleep
  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_screenshot, "Sys.sleep", mock_sleep, depth = 2)

  # Define a single chart definition
  chart_defs <- list(
    list(
      id = "123456",
      filename = "chart1.png",
      width = 800,
      height = 600,
      scale = 2
    ),
    list(
      id = "789012",
      filename = "chart2.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  # Call the function
  collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")

  # Check arguments passed to mocked methods
  expect_args(mock_write_bin, 1, decoded_base64_1, "mock_output_dir/chart1.png")
  expect_args(mock_write_bin, 2, decoded_base64_2, "mock_output_dir/chart2.png")
})
