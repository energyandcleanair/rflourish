# RFlourish

RFlourish is an R package designed to take snapshots of published Flourish charts. It provides an easy-to-use interface for automating the process of capturing high-quality images of your visualizations.

## Features

- Capture snapshots of Flourish charts with custom dimensions and scaling.
- Save images directly to a specified directory.
- Automate the process for multiple charts using a single function.

## Installation

### System Dependencies

Before installing RFlourish, ensure that the following system dependencies are installed:

- **Google Chrome or Chromium**: Required for rendering the Flourish charts.
  - On Debian/Ubuntu:
    ```bash
    sudo apt install google-chrome-stable
    ```
  - On macOS (using Homebrew):
    ```bash
    brew install --cask google-chrome
    ```
  - On Windows: Download and install from [Google Chrome's website](https://www.google.com/chrome/).

### Using `remotes`
```r
# Install the remotes package if not already installed
install.packages("remotes")

# Install RFlourish from GitHub
remotes::install_github("energyandcleanair/rflourish")
```

### Using `pak`
```r
# Install the pak package if not already installed
install.packages("pak")

# Install RFlourish from GitHub
pak::pkg_install("energyandcleanair/rflourish")
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


### Development Setup

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

4. Make the changes you want

4. Run checks to ensure everything is working:
   ```r
   devtools::check()
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

Make sure to run the hooks before submitting a pull request to catch any issues early.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
