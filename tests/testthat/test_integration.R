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
  actual_image <- png::readPNG(img_path, info = TRUE)
  expect_equal(dim(actual_image)[2], 800)
  expect_equal(dim(actual_image)[1], 600)

  # Test it's similar enough to the expected image
  expected_img_path <- system.file("testdata", "expected_chart.png", package = "rflourish")
  expected_image <- png::readPNG(expected_img_path, info = TRUE)

  avg_image_diff <- mean(abs(actual_image - expected_image))
  expect_true(avg_image_diff < 0.001)

  expect_equal(results$chart_id[1], "22847056")
  expect_equal(results$filepath[1], file.path(output_dir, "chart1.png"))
  expect_equal(results$updated_at[1], as.Date("2025-04-25T10:54:15.942Z"))
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

  expect_equal(results$chart_id[1], "x1234")
  expect_equal(results$error[1], "Chart does not exist or is not public")
})
