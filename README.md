grid3Covariates
===================
grid3Covariates is an R Package interface for downloading raster datasets from [WorldPop](http://www.worldpop.org.uk/) FTP.

What is WorldPop?
High spatial resolution, contemporary data on human population distributions are a prerequisite for the accurate measurement of the impacts of population growth, for monitoring changes and for planning interventions. The WorldPop project aims to meet these needs through the provision of detailed and open access population distribution datasets built using transparent approaches.

Installation
------------

**Installation**
grid3Covariates isn't available from CRAN yet, but you can get it from github with:

    install.packages("devtools")
    devtools::install_github("wpgp/grid3Covariates")
    
    # load package
    library(grid3Covariates)
    
**Basic usage**

After installation you should be able to use five main functions from the library:

 - grid3ListCountries
 - grid3ListCountryCovariates
 - grid3GetCountryCovariate
----------
