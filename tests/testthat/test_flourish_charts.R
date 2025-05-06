library(testthat)
library(mockery)

actual_date <- "2025-01-01T00:00:00Z"
date_evaluation_result <- list(list(value = actual_date))

page_title_result <- list(list(value = "My Chart Title"))

test_that("collect_charts saves screenshot correctly", {
  encoded_base64 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64 <- jsonlite::base64_dec(encoded_base64)

  mock_br <- list(
    go_to = mock(),
    Page = list(
      captureScreenshot = mock(list(data = encoded_base64))
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock(page_title_result, NULL, date_evaluation_result)
    ),
    default_timeout = NULL,
    close = mock()
  )
  # Mock writeBin and Sys.sleep
  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_chart, "Sys.sleep", mock_sleep, depth = 2)

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


test_that("collect_charts returns correct values", {
  encoded_base64 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64 <- jsonlite::base64_dec(encoded_base64)

  mock_br <- list(
    go_to = mock(),
    Page = list(
      captureScreenshot = mock(list(data = encoded_base64))
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock(page_title_result, NULL, date_evaluation_result)
    ),
    default_timeout = NULL,
    close = mock()
  )
  # Mock writeBin and Sys.sleep
  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_chart, "Sys.sleep", mock_sleep, depth = 2)

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
  results <- collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")

  # Check arguments passed to mocked methods
  expect_equal(results$chart_id[1], "123456")
  expect_equal(results$filepath[1], "mock_output_dir/chart1.png")
})


test_that("collect_charts uses the browser correctly", {
  call_log <- c()
  create_logged_mock <- function(call_name, ...) {
    return_index <- 1
    return_values <- list(...)
    mock(
      {
        call_log <<- c(call_log, call_name)
        if (length(return_values) > 0) {
          this_value <- return_values[[return_index]]
          return_index <- return_index + 1
          if (return_index > length(return_values)) {
            return_index <- 1
          }
          return(this_value)
        }
        return(invisible())
      },
      cycle = TRUE
    )
  }

  mock_br <- list(
    go_to = create_logged_mock("go_to"),
    Page = list(
      captureScreenshot = create_logged_mock(
        "captureScreenshot",
        list(data = jsonlite::base64_enc(charToRaw("test")))
      )
    ),
    Emulation = list(
      setDeviceMetricsOverride = create_logged_mock("setDeviceMetricsOverride")
    ),
    Runtime = list(
      evaluate = create_logged_mock("evaluate", page_title_result, NULL, date_evaluation_result)
    ),
    default_timeout = NULL,
    close = create_logged_mock("close")
  )

  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_chart, "Sys.sleep", mock_sleep, depth = 2)

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
      "go_to",
      "evaluate",
      "setDeviceMetricsOverride",
      "evaluate",
      "captureScreenshot",
      "evaluate",
      "close"
    )
  )
  expect_args(mock_br$go_to, 1, "https://flo.uri.sh/visualisation/123456/embed?auto=1")
  expect_args(
    mock_br$Emulation$setDeviceMetricsOverride, 1,
    width = 400, height = 300, scale = 1, deviceScaleFactor = 2, mobile = TRUE
  )
  expect_args(
    mock_br$Runtime$evaluate, 1,
    "document.title"
  )
  expect_args(
    mock_br$Runtime$evaluate, 2,
    "window.dispatchEvent(new Event('resize'))",
    timeout_ = 120 * 1000
  )
  expect_args(
    mock_br$Runtime$evaluate, 3,
    "window.template.data.data.timestamps.last_updated.toISOString()",
    timeout_ = 1000
  )
})

test_that("collect_charts saves multiple correctly", {
  encoded_base64_1 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64_1 <- jsonlite::base64_dec(encoded_base64_1)

  encoded_base64_2 <- jsonlite::base64_enc(charToRaw("test2"))
  decoded_base64_2 <- jsonlite::base64_dec(encoded_base64_2)

  mock_br <- list(
    go_to = mock(),
    Page = list(
      captureScreenshot = mock(
        list(data = encoded_base64_1),
        list(data = encoded_base64_2)
      )
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock(page_title_result, NULL, date_evaluation_result, cycle = TRUE)
    ),
    default_timeout = NULL,
    close = mock()
  )
  # Mock writeBin and Sys.sleep
  mock_write_bin <- mock()
  mock_sleep <- mock()
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock_write_bin, depth = 2)
  stub(get_chart, "Sys.sleep", mock_sleep, depth = 2)

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
  results <- collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")

  # Check arguments passed to mocked methods
  expect_equal(results$chart_id, c("123456", "789012"))
  expect_equal(results$filepath, c("mock_output_dir/chart1.png", "mock_output_dir/chart2.png"))
})

test_that("collect_charts throws error for missing arguments", {
  # Define a chart definition with missing arguments
  chart_defs <- list(
    list(
      # Missing all arguments
    )
  )

  # Expect an error when calling the function
  expect_error(
    collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir"),
    "Missing required arguments: id, filename, width, height, scale"
  )
})

test_that("collect_charts throws error when error_on_missing_chart is TRUE", {
  mock_br <- list(
    go_to = mock(),
    Page = list(),
    Runtime = list(
      evaluate = mock(list(list(value = "403 Forbidden")))
    ),
    default_timeout = NULL,
    close = mock()
  )
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)

  chart_defs <- list(
    list(
      id = "nonexistent",
      filename = "nonexistent_chart.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  expect_error(
    collect_charts(
      chart_defs = chart_defs,
      output_dir = "mock_output_dir",
      error_on_missing_chart = TRUE
    ),
    "Some charts could not be fetched: nonexistent"
  )
})

test_that("collect_charts does not throw error when error_on_missing_chart is FALSE", {
  mock_br <- list(
    go_to = mock(),
    Page = list(),
    Runtime = list(
      evaluate = mock(list(list(value = "403 Forbidden")))
    ),
    default_timeout = NULL,
    close = mock()
  )
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)

  chart_defs <- list(
    list(
      id = "nonexistent",
      filename = "nonexistent_chart.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  results <- collect_charts(
    chart_defs = chart_defs,
    output_dir = "mock_output_dir",
    error_on_missing_chart = FALSE
  )

  expect_equal(results$chart_id[1], "nonexistent")
  expect_equal(results$error[1], "Chart does not exist or is not public")
})

test_that("collect_charts works with a data frame", {
  encoded_base64 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64 <- jsonlite::base64_dec(encoded_base64)

  mock_br <- list(
    go_to = mock(),
    Page = list(
      captureScreenshot = mock(list(data = encoded_base64))
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock(page_title_result, NULL, date_evaluation_result)
    ),
    default_timeout = NULL,
    close = mock()
  )
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock(), depth = 2)

  chart_defs <- data.frame(
    id = "123456",
    filename = "chart1.png",
    width = 800,
    height = 600,
    scale = 2,
    stringsAsFactors = FALSE
  )

  results <- collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")
  expect_equal(results$chart_id[1], "123456")
  expect_equal(results$filepath[1], "mock_output_dir/chart1.png")
})

test_that("collect_charts works with a list of lists", {
  encoded_base64 <- jsonlite::base64_enc(charToRaw("test"))
  decoded_base64 <- jsonlite::base64_dec(encoded_base64)

  mock_br <- list(
    go_to = mock(),
    Page = list(
      captureScreenshot = mock(list(data = encoded_base64))
    ),
    Emulation = list(
      setDeviceMetricsOverride = mock()
    ),
    Runtime = list(
      evaluate = mock(page_title_result, NULL, date_evaluation_result)
    ),
    default_timeout = NULL,
    close = mock()
  )
  stub(collect_charts, "ChromoteSession$new", mock_br, depth = 1)
  stub(collect_charts, "writeBin", mock(), depth = 2)

  chart_defs <- list(
    list(
      id = "123456",
      filename = "chart1.png",
      width = 800,
      height = 600,
      scale = 2
    )
  )

  results <- collect_charts(chart_defs = chart_defs, output_dir = "mock_output_dir")
  expect_equal(results$chart_id[1], "123456")
  expect_equal(results$filepath[1], "mock_output_dir/chart1.png")
})
