# Install RStudio for Ubuntu or WSL

Comprehensive guide for installing RStudio Desktop on Ubuntu Linux or Windows Subsystem for Linux (WSL2).

## Overview

[RStudio](https://posit.co/products/open-source/rstudio/) is an integrated development environment (IDE) for R programming. While RStudio installation on Linux is officially supported, getting it to work seamlessly with popular R packages like [Tidyverse](https://www.tidyverse.org/) requires additional system dependencies. This guide provides a complete, tested procedure for Ubuntu 24.04.

!!! warning "WSL2 Complexity"
    Installing RStudio in WSL2 is not as straightforward as it initially appears. Package installations often fail due to missing system libraries. Following this complete procedure ensures all dependencies are configured correctly the first time.

## Prerequisites

- Ubuntu 24.04 (or compatible Linux distribution)
- WSL2 if running on Windows
- Administrator (sudo) access
- Internet connection for package downloads

## Installation Steps

### Part 1: Install R Base

R must be installed before RStudio. These instructions follow the official [CRAN repository configuration](https://cran.rstudio.com/bin/linux/ubuntu/).

**Update system and install prerequisites:**

```bash
sudo apt update -qq
sudo apt install --no-install-recommends software-properties-common dirmngr
```

**Add CRAN repository signing key:**

```bash
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
```

**Add CRAN repository for your Ubuntu version:**

```bash
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
```

**Install R:**

```bash
sudo apt install --no-install-recommends r-base
```

**Verify R installation:**

```bash
R --version
```

Should display R version 4.x or later.

### Part 2: Install RStudio Desktop

Download and install RStudio from the official [RStudio download page](https://posit.co/download/rstudio-desktop/).

**Install gdebi package installer:**

```bash
sudo apt-get install gdebi-core
```

**Download RStudio Desktop (Ubuntu/Debian package):**

```bash
wget https://download1.rstudio.org/electron/jammy/amd64/rstudio-2024.04.2-764-amd64.deb
```

!!! tip "Check Latest Version"
    Visit the [RStudio download page](https://posit.co/download/rstudio-desktop/) to get the latest version URL. Update the wget URL accordingly for newer releases.

**Install RStudio:**

```bash
sudo apt install ./rstudio-*.deb
```

This installs the `.deb` package and resolves most basic dependencies automatically.

### Part 3: Install Supporting System Libraries

This is the critical step often missed in basic installation guides. R packages frequently require system-level libraries for compilation and operation.

**Core package dependencies (XML, curl, SSL, Fortran, linear algebra):**

```bash
sudo apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev gfortran liblapack-dev libopenblas-dev cmake
```

These libraries enable:
- `libxml2-dev`: XML parsing for data import/export
- `libcurl4-openssl-dev`: HTTP requests and API interactions
- `libssl-dev`: Secure connections and cryptography
- `gfortran`, `liblapack-dev`, `libopenblas-dev`: Mathematical computations
- `cmake`: Building packages from source

**Font and image rendering libraries:**

```bash
sudo apt -y install libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
```

These libraries enable:
- Graphics rendering in ggplot2 and other visualization packages
- Plot export to PNG, JPEG, TIFF formats
- Proper font rendering in graphics

### Part 4: Configure pkg-config

The `pkg-config` utility is installed as a dependency but may not be configured properly in PATH.

**Add pkg-config to environment:**

```bash
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
```

**Make this permanent by adding to your shell configuration:**

```bash
echo 'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig' >> ~/.bashrc
source ~/.bashrc
```

For Zsh users, replace `~/.bashrc` with `~/.zshrc`.

## Launching RStudio

**Start RStudio from terminal:**

```bash
rstudio
```

RStudio GUI will launch. In WSL2, this requires an X server or uses the built-in WSLg graphics support in Windows 11.

!!! note "WSLg Graphics"
    Windows 11 includes WSLg, which provides native GUI support for Linux applications. On Windows 10, you may need to install an X server like [VcXsrv](https://sourceforge.net/projects/vcxsrv/) or [X410](https://x410.dev/).

## Testing the Installation

Once RStudio is open, test the complete installation by installing Tidyverse, which exercises most system dependencies:

```r
install.packages("tidyverse", dependencies = TRUE)
```

This should complete without errors. If successful, all system libraries are correctly configured.

**Load Tidyverse to verify:**

```r
library(tidyverse)
```

Should load without warnings or errors.

## Troubleshooting

### Package Installation Fails with Missing Library Errors

If you see errors like:

```
ERROR: configuration failed for package 'xml2'
ERROR: dependency 'curl' is not available
```

Ensure you completed **Part 3** - system library installation. Re-run the library installation commands.

### RStudio Won't Launch in WSL2

**Windows 10:** Install an X server (VcXsrv or X410) and set the DISPLAY variable:

```bash
export DISPLAY=:0
```

**Windows 11:** WSLg should work automatically. If not, update WSL:

```powershell
wsl --update
```

### "Cannot open display" Error

Set the DISPLAY environment variable:

```bash
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
```

Or for Windows 11 with WSLg:

```bash
export DISPLAY=:0
```

## Alternative: RStudio Server

For a browser-based alternative without GUI requirements, consider [RStudio Server](https://posit.co/download/rstudio-server/):

```bash
sudo apt-get install rstudio-server
```

Access via browser at `http://localhost:8787`

## Additional Resources

- [RStudio Official Documentation](https://docs.posit.co/ide/user/)
- [CRAN Ubuntu Installation Guide](https://cran.rstudio.com/bin/linux/ubuntu/)
- [Tidyverse Documentation](https://www.tidyverse.org/)
- [R for Data Science Book](https://r4ds.had.co.nz/) - Free online resource

## Next Steps

After successful installation:

1. Configure RStudio preferences (Tools → Global Options)
2. Install additional R packages as needed
3. Set up version control integration with Git
4. Explore RStudio projects for organizing work

---

**Reference:** Installation procedure adapted from [Installing RStudio in WSL2](https://code.adonline.id.au/installing-rstudio-in-wsl2/) by Adrian Huxley, with style and organization adapted for this documentation.
