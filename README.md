
<!-- README.md is generated from README.Rmd. Please edit that file -->

# scDiffCom

<!-- badges: start -->

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![CRAN
status](https://www.r-pkg.org/badges/version/scDiffCom)](https://CRAN.R-project.org/package=scDiffCom)
[![Codecov test
coverage](https://codecov.io/gh/CyrilLagger/scDiffCom/branch/master/graph/badge.svg)](https://app.codecov.io/gh/CyrilLagger/scDiffCom?branch=master)
[![R-CMD-check](https://github.com/CyrilLagger/scDiffCom/workflows/R-CMD-check/badge.svg)](https://github.com/CyrilLagger/scDiffCom/actions)
<!-- badges: end -->

scDiffCom stands for “single-cell Differential Communication” and infers
changes in intercellular communication between two biological conditions
from scRNA-seq data (as [Seurat](https://satijalab.org/seurat/)
objects). The package relies on an internal collection of
ligand-receptor interactions (available for human, mouse and rat)
retrieved from seven curated databases.

<details>

<summary>Display LRI databases</summary> \*
[CellChat](http://www.cellchat.org/) \*
[CellPhoneDB](https://www.cellphonedb.org/) \*
[CellTalkDB](http://tcm.zju.edu.cn/celltalkdb/) \*
[connectomeDB2020](https://github.com/forrest-lab/NATMI) \*
[ICELLNET](https://github.com/soumelis-lab/ICELLNET) \*
[NicheNet](https://github.com/saeyslab/nichenetr) \*
[SingleCellSignalR](https://www.bioconductor.org/packages/release/bioc/html/SingleCellSignalR.html)

</details>

 

## Installation

``` r
# We currently highly recommend to install the development version from GitHub
devtools::install_github("CyrilLagger/scDiffCom")

# Install release version from CRAN
install.packages("scDiffCom")
```

## Usage

As an introduction, please look at the
[documentation](https://cyrillagger.github.io/scDiffCom/) and this
[vignette](https://cyrillagger.github.io/scDiffCom/articles/scDiffCom-vignette.html).

For a concrete and large-scale project that used scDiffCom, please look
at [scagecom.org](https://scagecom.org/), our murine atlas of
age-related changes in intercellular communication.

## Citation

Please consider reading and citing our Nature Aging paper:
[here](https://www.nature.com/articles/s43587-023-00514-x).
