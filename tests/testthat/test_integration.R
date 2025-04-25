library(testthat)

test_that("Able to download Flourish chart with ID 22847056", {
  skip_if_not(
    Sys.getenv("RUN_INTEGRATION_TESTS") == "true"
  )
  chart_name <- "chart1.png"
  chart_defs <- list(
    list(id = "22847056", filename = chart_name, width = 800, height = 600, scale = 2)
  )
  output_dir <- tempdir()

  results <- expect_no_error(collect_charts(chart_defs, output_dir))

  expect_true(file.exists(file.path(output_dir, chart_name)))

  # Check image dimensions
  img_path <- file.path(output_dir, chart_name)
  img_info <- png::readPNG(img_path, info = TRUE)
  expect_equal(dim(img_info)[2], 800)
  expect_equal(dim(img_info)[1], 600)

  # Test it's similar enough to the expected image
  expected_img_path <- system.file("testdata", "expected_chart.png", package = "rflourish")
  expected_img <- png::readPNG(expected_img_path, info = TRUE)
  expect_true(all(abs(img_info - expected_img) < 0.1))

  expect_equal(results[[1]]$chart_id, "22847056")
  expect_equal(results[[1]]$filepath, file.path(output_dir, "chart1.png"))
  expect_equal(results[[1]]$updated_at, as.Date("2025-04-25T10:54:15.942Z"))
})

test_that("Non existant Flourish chart returns error object", {
  skip_if_not(
    Sys.getenv("RUN_INTEGRATION_TESTS") == "true"
  )

  chart_name <- "chart2.png"

  chart_defs <- list(
    list(id = "x1234", filename = chart_name, width = 800, height = 600, scale = 2)
  )
  output_dir <- tempdir()
  results <- expect_no_error(collect_charts(chart_defs, output_dir, error_on_missing_chart = FALSE))
  expect_false(file.exists(file.path(output_dir, chart_name)))

  expect_equal(results[[1]]$chart_id, "x1234")
  expect_equal(results[[1]]$error, "Chart does not exist or is not public")
})
