library(testthat)

test_that("Integration test for ID 22847056", {
  skip_if_not(
    Sys.getenv("RUN_INTEGRATION_TESTS") == "true"
  )
  chart_defs <- list(
    list(id = "22847056", filename = "chart1.png", width = 800, height = 600, scale = 2)
  )
  output_dir <- tempdir()

  expect_no_error(collect_charts(chart_defs, output_dir))

  expect_true(file.exists(file.path(output_dir, "chart1.png")))

  # Check image dimensions
  img_path <- file.path(output_dir, "chart1.png")
  img_info <- png::readPNG(img_path, info = TRUE)
  expect_equal(dim(img_info)[2], 800)
  expect_equal(dim(img_info)[1], 600)

  # Test it's similar enough to the expected image
  expected_img_path <- system.file("testdata", "expected_chart.png", package = "rflourish")
  expected_img <- png::readPNG(expected_img_path, info = TRUE)
  expect_true(all(abs(img_info - expected_img) < 0.1))
})
