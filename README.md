
<strong>Please note:</strong> This vignette will be updated from time to
time when new features are implemented. Please find the most recent
version at the [QurvE GitHub
repository](https://github.com/NicWir/QurvE).

# Introduction

In virtually all disciplines of biology dealing with living organisms,
from classical microbiology to applied biotechnology, it is routine to
characterize the **growth** of the species under study. `QurvE` provides
a suite of analysis tools to make such growth profiling quick,
efficient, and reproducible. In addition, it allows the characterization
of **fluorescence** data for, e.g., biosensor characterization in plate
reader experiments (further discussed in the vignette *Quantitiative
Fluorescence Curve Evaluation with Package `QurvE`)*. All computational
steps to obtain an in-depth characterization are combined into
user-friendly *workflow* functions and a range of plotting functions
allow the visualization of fits and the comparison of organism
performances.

Any physiological parameter calculated (e.g., growth rate µ, doubling
time t<sub>D</sub>, lag time $\lambda$, density increase $\Delta$Y, or
equivalent fluorescence parameters) can be used to perform a
dose-response analysis to determine the *half-maximal effective
concentration* (EC<sub>50</sub>).

The package is build on the foundation of the two R packages from Kahm
*et al.* ([2010](#ref-kahm2010)) and Petzoldt
([2022](#ref-petzoldt2022)). `QurvE` was designed to be usable with
minimal prior knowledge of the R programming language or programming in
general. You will need to be familiar with the idea of running commands
from a console or writing basic scripts. For R beginners,
[this](https://moderndive.netlify.app/1-getting-started.html) is a great
starting point, there are some good resources
[here](https://education.rstudio.com/learn/beginner/) and we suggest
using the [RStudio application](https://rstudio.com/products/rstudio/).
It provides an environment for writing and running R code.

With consideration for `R` novices, `QurvE` establishes a framework in
which a complete, detailed growth curve analysis can be performed in two
simple steps:

1.  *Read data* in custom format or parse data from a plate reader
    experiment.

2.  *Run workflow*, including fitting of growth curves, dose-response
    analysis, and rendering a report that summarizes the results.

All computational results of a workflow are stored in a data container
(list) and can be visualized by passing them to the generic function
`plot(list_object)`. `QurvE` further extends the user’s control over the
fits by defining thresholds and quality criteria, allows the direct
parsing of data from plate reader result files, and calculates
parameters for an additional growth phase (bi-phasic growth).

# Installation

## Development version

Install the most current version with package `devtools`:

``` r
install.packages("devtools")
library(devtools)
install_github("NicWir/QurvE")
```

# Growth profiling methods

Three methods are available to characterize growth curves:

1.  Fit parametric growth models to (log-transformed) growth data

2.  Determine maximum growth rates (µ<sub>max</sub>) from the log-linear
    part of a growth curve using a heuristic approach proposed as the
    “growth rates made easy”-method by Hall *et al.*
    ([2014](#ref-hall2014)). Do do so, `QurvE` uses code from the
    package Petzoldt ([2022](#ref-petzoldt2022)), but adds user-defined
    thresholds for (i) R<sup>2</sup> values of linear fits, (ii)
    relative standard deviations (RSD) of estimates slopes, and (iii)
    the minimum fraction of total density increase ($\Delta$Y) a
    regression window should cover to be considered for the analysis.
    These thresholds ensure a more robust and reproducible
    identification of the linear range that best describes the growth
    curve. Additionally, parameters for a *secondary growth phase* can
    be extracted for bi-linear growth curves.[^1]  
    The algorithm works as follows:

    1.  Fit linear regressions \[with the Theil-Sen estimator ([Sen,
        1968](#ref-sen1968); [Theil, 1992](#ref-theil1992))\] to all
        subsets of `h` consecutive, log-transformed data points (sliding
        window of size `h`). If, for example, `h=5`, fit a linear
        regression to points 1 $\dots$ 5, 2 $\dots$ 6, 3 $\dots$ 7 and
        so forth.

    2.  Find the subset with the highest slope $\mu_{max}$. Do the
        R<sup>2</sup> and RSD values of the regression meet the defined
        thresholds and do the data points within the regression window
        account for at least a defined fraction of the total density
        increase? If not, evaluate the regression with the second
        highest slope, and so forth.

    3.  Include also the data points of adjacent subsets that have a
        slope of at least a $defined \space quota \times \mu_{max}$,
        e.g., all regression windows that have at least 95% of the
        maximum slope.

    4.  Fit a new linear model to the extended data window identified in
        step iii.

    If `biphasic = TRUE` (see section @ref(run-workflow)), the following
    steps are performed to define a second growth phase:

    1.  Perform a smooth spline fit on the data with a smoothing factor
        of 0.5.

    2.  Calculate the second derivative of the spline fit and perform a
        smooth spline fit of the derivative with a smoothing factor of
        0.4.

    3.  Determine local maxima and minima in the second derivative.

    4.  Find the local minimum following $\mu_{max}$ and repeat the
        heuristic linear method for later time values.

    5.  Find the local maximum before $\mu_{max}$ and repeat the
        heuristic linear method for earlier time values.

    6.  Choose the greater of the two independently determined slopes as
        $\mu_{max}2$.

3.  Perform a smooth spline fit on (log-transformed) growth data and
    extract µ<sub>max</sub> as the maximum value of the first
    derivative<sup>1</sup>.

    If `biphasic = TRUE` (see section @ref(run-workflow)), the following
    steps are performed to define a second growth phase:

    1.  Determine local minima within the first derivative of the smooth
        spline fit.

    2.  Remove the *‘peak’* containing the highest value of the first
        derivative (i.e., $\mu_{max}$) that is flanked by two local
        minima.

    3.  Repeat the smooth spline fit and identification of maximum slope
        for later time values than the local minimum after $\mu_{max}$.

    4.  Repeat the smooth spline fit and identification of maximum slope
        for earlier time values than the local minimum before
        $\mu_{max}$.

    5.  Choose the greater of the two independently determined slopes as
        $\mu_{max}2$.

# Dose-response analysis methods

The purpose of a dose-response analysis is to define the *sensitivity*
of a given organism to the effects of a compound or the *potency* of a
substance, respectively. Such effects can be either beneficial (e.g., a
nutrient compound) or detrimental (e.g., an antibiotic). The sensitivity
is reflected in the half-maximal effective concentration
(*EC<sub>50</sub>*), i.e., the concentration (dose) at which the
half-maximal response (e.g., $\mu_{max}$ or $\Delta$Y) is observed.
`QurvE` provides two methods to determine the *EC<sub>50</sub>*:

1.  Perform a smooth spline fit on response vs. concentration data and
    extract the *EC<sub>50</sub>* as the concentration at the midpoint
    between the largest and smallest response value.

2.  Apply up to 20 (parametric) dose-response models to response
    vs. concentration data and choose the best model based on the Akaike
    information criterion (AIC). This is done using the excellent
    package `drc` ([Ritz *et al.*, 2016](#ref-ritz2016)).

# Data formats

`QurvE` accepts files with the formats *.xls*, *.xlsx*, *.csv*, *.tsv*,
and *.txt* (tab separated). The data in the files should be structured
as shown in Figure @ref(fig:data-layout). Alternatively, data parsers
are available that allow direct import of raw data from different
culture instruments. For a list of currently supported devices, please
run `?parse_data`.

*Please note: I recommend always converting .xls or .xlsx files to an
alternate format first to speed up the parsing process. Reading Excel
files may require orders of magnitude longer processing time.*

## Custom format

To ensure compatibility with any type of measurement and data type
(e.g., optical density, cell count, measured dimensions), `QurvE` uses a
custom data layout. Here the first column contains *time values* and
**‘Time’** in the top cell, cells \#2 and \#3 are ignored. The remaining
columns contain *measurement values* and the following sample
identifiers in the top three rows:

1.  Sample name; usually a combination of organism and condition, or
    ‘blank’.
2.  Replicate number; replicates are identified by *identical* names and
    concentration values. If only one type of replicate (biological or
    technical) was performed, enter numerical values here. If **both**
    biological and technical replicates of these biological replicates
    have been performed, the biological replicates shall be indicated
    with numbers and the technical replicates with letters. The
    technical replicates are then combined with their average value.
3.  (*optional*) Concentration values of an added compound; this
    information is used to perform a dose-response analysis.

Several experiments (e.g., runs on different plate readers) can be
combined into a single file and analyzed simultaneously. Therefore,
different experiments are marked by the presence of separate time
columns. Different lengths and values in these time columns are
permitted.  
  

<img src="man/figures/Data_layout.jpg" alt="\label{fig:data-layout} Custom QurvE data layout" width="100%" style="display: block; margin: auto;" />

  
To read data in custom format, run:

``` r
grodata <- read_data(data.density = 'path_to_data_file',
                   csvsep = ';', # or ','
                   dec = '.', # or ','
                   sheet.density = 1, # number (or "name") of the EXCEL file sheet containing data
                   subtract.blank = TRUE,
                   calibration = NULL)
```

The argument takes the path to the file containing experimental data in
custom format. specifies the separator symbol (only required for .csv
files; default: `';'`). is the decimal separator (only required for
.csv, .tsv, or .txt files; default: `'.'`). If an Excel file format is
used, specifies the number or name (in quotes) of the sheet containing
the data.  
If , columns with name ‘blank’ will be combined by their row-wise
average, and the mean values will be subtracted from the measurements of
all remaining samples. For the argument, a formula can be provided in
the form *‘y = function(x)’* (e.g., `calibration = 'y = x * 2 + 0.5'`)
to transform all measurement values.

## Data parser

The data generated by culture devices (e.g., plate readers) from
different manufacturers come in different formats. If these data are to
be used directly, they must first be “parsed” from the plate reader into
the `QurvE` standard format. In this scenario, sample information must
be provided in a separate table that *maps* samples with their
respective identifiers.The *mapping table* must have the following
layout (Figure @ref(fig:mapping-layout)):

<img src="man/figures/mapping_layout.png" alt="\label{fig:mapping-layout} Data parser mapping layout" width="40%" style="display: block; margin: auto;" />

To parse data, run:

``` r
grodata <- parse_data(data.file = 'path_to_data_file',
                    map.file = 'path_to_mapping_file',
                    software = 'used_software_or_device',
                    csvsep.data = ';', # or ','
                    dec.data = '.', # or ','
                    csvsep.map = ';', # or ','
                    dec.map = '.', # or ','
                    sheet.data = 1, # number (or "name") of the EXCEL file sheet containing data
                    sheet.map = 1, # number (or "name") of the EXCEL file sheet containing
                                   # mapping information
                    subtract.blank = TRUE,
                    calibration = NULL,
                    convert.time = NULL)
```

The argument takes the path to the file containing experimental data
exported from a culture device, the path to the file with mapping
information. With , you can specify the device (or software) that was
used to generate the data. and specify the separator symbol for data and
mapping file, respectively (only required for .csv files; default:
`';'`). and are the decimal separator used in data and mapping file,
respectively (only required for .csv, .tsv, or .txt files; default:
`'.'`). If an Excel file format is used for both or one of data or
mapping file, and/or specify the number or name (in quotes) of the sheet
containing the data or mapping information, respectively. If , columns
with name ‘blank’ will be combined by their row-wise average, and the
mean values will be subtracted from the measurements of all remaining
samples. For the argument, a formula can be provided in the form *‘y =
function(x)’* (e.g., `calibration = 'y = x * 2 + 0.5'`) to transform all
measurement values. Similarly, accepts a function *‘y = function(x)’* to
transform time values (e.g., `convert.time = 'y = x/3600'` to convert
seconds to hours).

# Run a complete growth analysis workflow

`QurvE` reduces all computational steps required to create a complete
growth profiling to two steps, **read data** and **run workflow**.

After loading the package:

``` r
library(QurvE)
```

we load experimental data from the publication Wirth & Nikel
([2021](#ref-wirth2021)) in which *Pseudomonas putida* KT2440 and an
engineered strain were tested for their sensitivity towards the product
2-fluoromuconic acid:

## Load data

``` r
grodata <- read_data(data.density = system.file("2-FMA_toxicity.xlsx",
    package = "QurvE"))
```

The created object `grodata` can be inspected with `View(grodata)`. It
is a list of class `grodata` containing:

- a `time` matrix with 66 rows, each corresponding to one sample in the
  dataset, and 161 columns, i.e., time values for each sample.

- a `density` data frame with 66 rows and 161+3 columns. The three
  additional columns contain the sample identifiers `condition`,
  `replicate`, and `concentration`.

- `fluorescence1` (here: `NA`)

- `fluorescence2` (here: `NA`)

- `norm.fluorescence1` (here: `NA`)

- `norm.fluorescence2` (here: `NA`)

- `expdesign`, a data frame containing the `label`, `condition`,
  `replicate`, and `concentration` for each sample:

``` r
head(grodata$expdesign)
#>             label condition replicate concentration
#> 1 KT2440 | 1 | 90    KT2440         1            90
#> 2 KT2440 | 1 | 70    KT2440         1            70
#> 3 KT2440 | 1 | 50    KT2440         1            50
#> 4 KT2440 | 1 | 25    KT2440         1            25
#> 5 KT2440 | 1 | 20    KT2440         1            20
#> 6 KT2440 | 1 | 15    KT2440         1            15
```

We can plot the raw data. Applying the generic `plot()` function to
`grodata` objects calls the function `plot.grodata()`.:

``` r
plot(grodata, data.type = "dens", log.y = FALSE,
     x.lim = c(NA, 32), legend.position = "right",
     exclude.conc = c(50, 70, 90),
     basesize = 10, legend.ncol = 1, lwd = 0.7)
```

<img src="vignettes/vigfig-raw-data-plot-1.png" alt="\label{fig:raw-data-plot} Raw data plot.
Conditions can be selected or deselected using the `names = c('grp1', 'grp2')` argument or `exclude.nm = c('grp3', 'grp4')` argument, respectively. Similarly, concentrations can be (de-selected) via the `conc` and `exclude.conc` arguments. To plot individual samples instead of grouping replicates, add `mean = FALSE`. See `?plot.grodata` for further options." width="80%" />

## Run Workflow

To perform a complete growth profiling of all samples in the input
dataset, we call the `growth.workflow()` function on the `grodata`
object. With , we avoid printing information about every sample’s fit in
the sample to the console. By default, the selected response parameter
to perform a dose-response analysis is ‘mu.linfit’. To choose a
different parameter, provide the argument . A list of appropriate
parameters is provided within the function documentation
(`?growth.workflow`).

``` r
grofit <- growth.workflow(grodata = grodata, fit.opt = "a", ec50 = T,
    suppress.messages = TRUE, export.res = F)  # Prevent creating TXT table and RData files with results
#> 
#> Results of growth fit analysis saved as tab-delimited text file in:
#> ''...GrowthResults_20221028_110353/results.gc.txt'
#> Results of EC50 analysis saved as tab-delimited text file in:
#> '...GrowthResults_20221028_110353/results.dr.txt'
```

Tab-delimited .txt files summarizing the computation results are created
automatically, as well as the `grofit` object (an object of class
`grofit`) as .RData file. This object (or the .RData file) contains all
raw data, fitting options, and computational results. Figure
@ref(fig:grofit-container) shows the structure of the generated
`grofit`object. In RStudio, `View(grofit)` allows interactive inspection
of the data container.

If you want to create a report summarizing all computational results
including a graphical representation of every fit, provide the desired
output format(s) as , , or . The advantage of having the report in HTML
format is that every figure can be exported as (editable) PDF file.

*<span style="color: orange;">In the spirit of good scientific practice
(data transparency), I would encourage anyone using QurvE to attach the
.RData file and generated reports to their publication.</span>*

Arguments that are commonly modified:

<table>
<tbody>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Which growth fitting methods to perform; a string containing for linear
fits, for spline fits, for model fits, or (the default) for all three
methods. Combinations can be also given as a vector of strings, e.g.,
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Which growth models to apply; a string containing one of, or a vector of
strings containing any combination of ‘logistic’, ‘richards’,
‘gompertz’, ‘gompertz.exp’, ‘huang’, and ‘baranyi’.
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Should Ln(y/y0) be applied to the growth data for the respective fits?
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Extract growth parameters for two different growth phases (as observed
with, e.g., diauxic shifts)
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Controls interactive mode. If , each fit is visualized in the Plots pane
and the user can adjust fitting parameters and confirm the reliability
of each fit per sample
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Number of bootstrap samples used for nonparametric growth curve fitting.
See for details.
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
Define the method used to perform a dose-responde analysis: smooth
spline fit () or model fitting (, the default). See section 4
</td>
</tr>
<tr>
<td style="text-align:left;width: 3cm; vertical-align: top !important; ">
</td>
<td style="text-align:left;vertical-align: top !important; ">
The response parameter in the output table to be used for creating a
dose response curve. See for further details.
</td>
</tr>
</tbody>
</table>

  
Please consult `?growth.workflow` for further arguments to customize the
workflow.  
  

<img src="man/figures/grofit_container.jpg" alt="\label{fig:grofit-container} Internal structure of a `grofit`object generated by `growth.workflow()`." width="90%" style="display: block; margin: auto;" />

## Tabular results

A `grofit` object contains two tables summarizing the computational
results: - `grofit$gcFit$gcTable` lists all calculated physiological
parameters for every sample and fit - `grofit$drFit$drTable` contains
the results of the dose-response analysis

``` r
# show the first three rows and first 14 columns of gcTable
gcTable <- grofit$gcFit$gcTable
gcTable[1:3, 1:14]
```

TestId AddId concentration reliability_tag used.model 1 KT2440 1 90 TRUE
<NA> 2 KT2440 1 70 TRUE <NA> 3 KT2440 1 50 TRUE <NA> log.x log.y.lin
log.y.spline log.y.model nboot.gc 1 FALSE TRUE TRUE TRUE 0 2 FALSE TRUE
TRUE TRUE 0 3 FALSE TRUE TRUE TRUE 0 mu.linfit tD.linfit lambda.linfit
dY.linfit 1 0 <NA> <NA> 0 2 0 <NA> <NA> 0 3 0 <NA> <NA> 0

``` r

# Show drTable. The function as.data.frame() ensures that it is shown in table format.
drTable <- as.data.frame(grofit$drFit$drTable)
```

Additionally, the dedicated functions `table_group_growth_linear()`,
`table_group_growth_model()`, and `table_group_growth_spline()` allow
the generation of grouped results tables for each of the three fit types
with averages and standard deviations. The column headers in the
resulting data frames are formatted with HTML for visualization in shiny
and with `DT::datatable()`.

A summary of results for each individual fit can be obtained by applying
the generic function `summary()` to any fit object within `grofit`.

## Visualize results

Several generic `plot()` methods have been written to allow easy
plotting of results by merely accessing list items within the `grofit`
object structure (Figure @ref(fig:grofit-container)).

### Grouped spline fits

Applying `plot()` to the `grofit` object produces a figure of all spline
fits performed as well as the first derivative (slope) over time. The
generic function calls `plot.grofit()` with `data.type = 'spline'` and
thus, the same options are available as described for Figure
@ref(fig:raw-data-plot).

``` r
plot(grofit,
     data.type = "spline",
     log.y = TRUE,
     conc = c(0,5,10,15,20),
     legend.position = "right",
     legend.ncol = 1,
     x.lim = c(NA, 32),
     y.lim = c(0.01,NA),
     n.ybreaks = 10,
     basesize=10,
     lwd = 0.7)
```

<img src="vignettes/vigfig-group-spline-plot-1.png" alt="\label{fig:group-spline-plot} Combined plot of all spline fits performed.
In addition to the options available with `data.type = 'raw'`, further arguments can be defined that control the appearance of the secondary panel showing the slope over time. See `?plot.grofit` for all options." width="80%" />

### Compare growth parameters

A convenient way to compare the performance of different organisms under
different conditions is to plot the calculated growth parameters by
means of the function `plot.parameter()`.

``` r
# Parameters obtained from linear regression
plot.parameter(grofit, param = "mu.linfit", basesize = 10, legend.position = "bottom")
plot.parameter(grofit, param = "dY.linfit", basesize = 10, legend.position = "bottom")

# Parameters obtained from nonparametric fits
plot.parameter(grofit, param = "mu.spline", basesize = 10, legend.position = "bottom")
plot.parameter(grofit, param = "dY.spline", basesize = 10, legend.position = "bottom")

# Parameters obtained from model fits
plot.parameter(grofit, param = "mu.model", basesize = 10, legend.position = "bottom")
plot.parameter(grofit, param = "dY.orig.model", basesize = 10,
    legend.position = "bottom")
```

<img src="vignettes/vigfig-plot-parameter-1.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" /><img src="vignettes/vigfig-plot-parameter-2.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" /><img src="vignettes/vigfig-plot-parameter-3.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" /><img src="vignettes/vigfig-plot-parameter-4.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" /><img src="vignettes/vigfig-plot-parameter-5.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" /><img src="vignettes/vigfig-plot-parameter-6.png" alt="\label{fig:plot-parameter} Parameter plots. If `mean = TRUE`, the results of replicates are combined and shown as their mean ± 95\% confidence interval. As with the functions for combining different growth curves, the arguments `name`, `exclude.nm`, `conc` and `exclude.conc` allow (de)selection of specific samples or conditions. Since we applied growth models to log-transformed data, calling 'dY.orig.model' or 'A.orig.model' instead of 'dY.model' or 'A.model' provides the respective values on the original scale. For linear and spline fits, this is done automatically. For details about this function, run `?plot.parameter`." width="47%" style="display: block; margin: auto;" />

From the parameter plot for ´mu.linfit´ (the growth rates determined
with linear regression), we can see that there is an outlier for strain
KT2440 at concentration 0. We can plot the individual fits for this
condition to find out if this is due to the fit quality:

``` r
plot(grofit$gcFit$gcFittedLinear$`KT2440 | 1 | 0`, cex.lab = 1.2,
    cex.axis = 1.2)
plot(grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0`, cex.lab = 1.2,
    cex.axis = 1.2)
```

<img src="vignettes/vigfig-plot-linear-1.png" alt="\label{fig:plot-linear} Linear fit plots to identify sample outliers. For details about this function, run `?plot.gcFitLinear`." width="70%" style="display: block; margin: auto auto auto 0;" /><img src="vignettes/vigfig-plot-linear-2.png" alt="\label{fig:plot-linear} Linear fit plots to identify sample outliers. For details about this function, run `?plot.gcFitLinear`." width="70%" style="display: block; margin: auto auto auto 0;" />

Apparently, the algorithm to find the maximum slope in the growth curve
with the standard threshold of `lin.R2 = 0.97` could not find an
appropriate fit within the first stage of growth due to insufficient
linearity. We can manually re-run the fit for this sample with adjusted
parameters. Thereby, we lower the R2 threshold and increase the size of
the sliding window to cover a larger fraction of the growth curve. Then,
we update the respective entries in the `gcTable` object that summarizes
all fitting results (and that plot.parameter() accesses to extract
relevant data). The generic function `summary()`, when applied to a the
fit object of a single sample within `grofit`, provides the required
parameters to update the table. Lastly, we also have to re-run the
dose-response analysis since ‘mu.linfit’ was used as response parameter
(the default), including the erroneous value.

*Note: This process of manually updating `grofit`elements with adjusted
fits can be avoided by re-running `growth.workflow` with adjusted global
parameters or my running the workflow in interactive mode
(`interactive = TRUE`). In interactive mode, each individual fit is
printed and the user can decide to re-run a single fit with adjusted
parameters.*

``` r
# Replace the existing linear fit entry for sample `KT2440 | 2 | 0`
# with a new fit
grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0` <-
  growth.gcFitLinear(time = grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0`$raw.time,
                     data = grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0`$raw.data,
                     control = growth.control(lin.R2 = 0.90, lin.h = 12))

# extract row index of sample `KT2440 | 2 | 0`
ndx.row <- grep("KT2440 \\| 2 \\| 0", grofit$expdesign$label)

# get column indices of linear fit parameters (".linfit")
ndx.col <- grep("\\.linfit", colnames(grofit$gcFit$gcTable) )

# Replace previous growth parameters stored in gcTable
grofit$gcFit$gcTable[ndx.row, ndx.col] <-
  summary(grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0`)

# Replace existing dose-response analysis with new fit
grofit$drFit <- growth.drFit(
  gcTable = grofit$gcFit$gcTable,
  control = grofit$control) # we can copy the control object from the original workflow.
```

And we can validate the quality of the updated fit:

``` r
plot(grofit$gcFit$gcFittedLinear$`KT2440 | 2 | 0`, cex.lab = 1.2)
```

<img src="vignettes/vigfig-plot-linear-update-1.png" alt="\label{fig:plot-linear-update} Updated linear fit for the outlier sample 'KT2440 | 2 | 0'." width="70%" style="display: block; margin: auto;" />

That looks better!

``` r
# Parameters obtained from linear regression
plot.parameter(grofit, param = "mu.linfit", basesize = 8.5)
```

<img src="vignettes/vigfig-plot-parameter-update-1.png" alt="\label{fig:plot-parameter-update} Parameter plot with updated fit." width="70%" style="display: block; margin: auto;" />

### Dose-response analysis

The results of the dose-response analysis can be visualized by calling
`plot()` on the `drFit` object that is stored within `grofit`. This
action calls `plot.drFit()` which in turn runs `plot.drFitSpline()` or
`plot.drFitModel()` (depending on the choice of in the workflow) on
every condition for which a dose-response analysis has been performed.
Alternatively, you can call `plot()` on the list elements in
`grofit$drFit$drFittedModels` or `grofit$drFit$drFittedSplines`,
respectively.

``` r
plot(grofit$drFit, cex.point = 1, basesize = 12)
```

<img src="vignettes/vigfig-plot-drFit-1.png" alt="\label{fig:plot-drFit} Dose response analysis - model fits. For details about this function, run `?plot.drFit`." width="70%" style="display: block; margin: auto;" />

# Bootstrapping

When growth experiments are performed on a larger scale with manual
density measurements, technical deviations can result in outliers. Such
outliers can lead to a distortion of the curve fits, especially if fewer
data points are available than is usual in plate reading experiments. In
this instance, bootstrapping can provide a more realistic estimation of
growth parameters. Bootstrapping is a statistical procedure that
resamples a single dataset to create many simulated samples. This is
done by randomly drawing data points from a dataset with replacement
until the original number of data points has been reached. The analysis
(here: growth fitting) is then performed individually on each
bootstrapped replicate. The variation in the resulting estimated
parameters is a reasonable approximation of the variance in those
parameters. To include bootstrapping into the `QurvE` workflow, we
define the argument .

Similarly, we can include bootstrapping in the dose-response analysis if
done with by defining argument .

``` r
grofit_bt <- growth.workflow(grodata = grodata,
                             fit.opt = "s", # perform only nonparametric growth fitting
                             nboot.gc = 50,
                             ec50 = T,
                             dr.method = "spline",
                             dr.parameter = "mu.spline",
                             nboot.dr = 50,
                             smooth.dr = 0.25,
                             suppress.messages = TRUE,
                             export.res = F)
#> 
#> Results of growth fit analysis saved as tab-delimited text file in:
#> ''...GrowthResults_20221028_110546/results.gc.txt'
#> Results of EC50 analysis saved as tab-delimited text file in:
#> '...GrowthResults_20221028_110546/results.dr.txt'
```

To plot the results of a growth fit with bootstrapping, we call `plot()`
on a `gcBootSpline` object:

``` r
plot(grofit_bt$gcFit$gcBootSpline[[7]], # Double braces serve as an alternative to
                                        # access list items and allow their access by number
     combine = TRUE, # combine both growth curves and parameter plots in the same window
     lwd = 0.7)
```

<img src="vignettes/vigfig-plot-gcBootSpline-1.png" alt="\label{fig:plot-gcBootSpline} Nonparametric growth fit with bootstrapping. For details about this function, run `?plot.gcBootSpline`." width="85%" style="display: block; margin: auto;" />

And by applying `plot()` to a `drBootSpline` object, we can plot the
dose-response bootstrap results:

``` r
plot(grofit_bt$drFit$drBootSpline[[1]],
     combine = TRUE, # combine both dose-response curves and parameter plots in the same window
     lwd = 0.7)
```

<img src="vignettes/vigfig-plot-drBootSpline-1.png" alt="\label{fig:plot-drBootSpline} Dose-response analysis with bootstrapping. For details about this function, run `?plot.drBootSpline`." width="85%" style="display: block; margin: auto;" />

# References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-hall2014" class="csl-entry">

Hall B.G., Acar H., Nandipati A. & Barlow M. (2014). Growth rates made
easy. Mol Biol Evol 31 (1): 232–8.
<https://doi.org/10.1093/molbev/mst187>.

</div>

<div id="ref-kahm2010" class="csl-entry">

Kahm M., Hasenbrink G., Lichtenberg-Fraté H., Ludwig J. & Kschischo M.
(2010). Grofit: Fitting biological growth curves with r. Journal of
Statistical Software 33 (7): 1–21.
<https://doi.org/10.18637/jss.v033.i07>.

</div>

<div id="ref-petzoldt2022" class="csl-entry">

Petzoldt T. (2022). Growthrates: Estimate growth rates from experimental
data. <https://github.com/tpetzoldt/growthrates>.

</div>

<div id="ref-ritz2016" class="csl-entry">

Ritz C., Baty F., Streibig J.C. & Gerhard D. (2016). Dose-response
analysis using r. PLOS ONE 10 (12): e0146021.
<https://doi.org/10.1371/journal.pone.0146021>.

</div>

<div id="ref-sen1968" class="csl-entry">

Sen P.K. (1968). Estimates of the regression coefficient based on
kendall’s tau. Journal of the American Statistical Association 63 (324):
1379–1389. <https://doi.org/10.1080/01621459.1968.10480934>.

</div>

<div id="ref-theil1992" class="csl-entry">

Theil H. (1992). A Rank-Invariant Method of Linear and Polynomial
Regression Analysis. Springer Netherlands, p. 345–381.
<https://doi.org/10.1007/978-94-011-2546-8_20>.

</div>

<div id="ref-wirth2021" class="csl-entry">

Wirth N.T. & Nikel P.I. (2021). Combinatorial pathway balancing provides
biosynthetic access to 2-fluoro-cis,cis-muconate in engineered
Pseudomonas putida. Chem catalysis 1 (6): 1234–1259.
<https://doi.org/10.1016/j.checat.2021.09.002>.

</div>

</div>

[^1]: For linear and nonparametric (i.e, smooth spline) fits, the lag
    time is calculated as the intersect of the tangent at
    µ<sub>max</sub> and a horizontal line at the first data point
    (y<sub>0</sub>). For the analysis of bi-phasic growth curves, the
    lag time is extracted as the lower of the two obtained $\lambda$
    values.