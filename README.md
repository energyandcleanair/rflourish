# RFlourish

RFlourish is an R package designed to take snapshots of published Flourish charts. It provides an easy-to-use interface for automating the process of capturing high-quality images of your visualizations.

## Features

- Capture snapshots of Flourish charts with custom dimensions and scaling.
- Save images directly to a specified directory.
- Automate the process for multiple charts using a single function.

## Installation

This depends on a variety of system libraries to run. We recommend using
`pak` to install the package to handle the installation of system dependencies.

If you don't want `pak` to install the system dependencies, you can run the
following to list the required dependencies:
```r
pak::sysreqs_check_installed()
```

### Using `pak`

To install the library and all its required R and system dependencies, run the
following:
```r
# Install RFlourish from GitHub
pak::pkg_install("energyandcleanair/rflourish")
```

### Using `remotes`

To install the library and its required R dependencies, run the following:
```r
# Install RFlourish from GitHub
remotes::install_github("energyandcleanair/rflourish")
```

## Usage

Here's a quick example of how to use RFlourish:

```r
library(rflourish)

chart_defs <- list(
  list(id = "123456", filename = "chart1.png", width = 800, height = 600, scale = 2),
  list(id = "789012", filename = "chart2.png", width = 800, height = 600, scale = 2)
)

collect_charts(chart_defs, "output_dir")
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you'd like to contribute.

### Developing the library

To set up RFlourish for development, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/energyandcleanair/rflourish.git
   cd rflourish
   ```

2. Install the required R packages:
   ```r
   install.packages(c("devtools", "roxygen2", "testthat", "styler"))
   ```

3. Install the package in development mode:
   ```r
   devtools::load_all(".")
   ```

Once you have made changes, you can check it passes quality and testing:

1. Run checks to ensure everything is working:
   ```r
   devtools::check()
   ```

2. Make sure the integration tests succeed.
   ```
   RUN_INTEGRATION_TESTS=true Rscript -e 'devtools::test(filter = "integration")'
   ```

3. Run the pre-commit hooks (as defined below):
   ```
   pre-commit run --all-files
   ```

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality and consistency. To set up the hooks locally, follow these steps:

1. Install `pre-commit` if you haven't already:
   ```bash
   pip install pre-commit
   ```

2. Install the hooks defined in `.pre-commit-config.yaml`:
   ```bash
   pre-commit install
   ```

3. Run the hooks manually on all files (optional):
   ```bash
   pre-commit run --all-files
   ```


## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
