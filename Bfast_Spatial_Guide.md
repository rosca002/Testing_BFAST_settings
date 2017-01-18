# Understanding bfastSpatial

These guidelines are addressed to everybody that is interested in detecting deforestation from Landsat time series using the bfastSpatial algorithm.

## Goal

The purpose of the present guide is to help the user understand what settings are more appropriate to use for bfastSpatial in order to obtain the best results considering the particularities of their specific case study.

Documentation explaining step by step how to apply the algorithm exists as a [full tutorial](http://www.loicdutrieux.net/bfastSpatial/) in which everything from data download to pre-processing, analysis, and post-processing of the BFM output is described.

It is recomended to first read these explanations and then follow the [above mentioned tutorial](http://www.loicdutrieux.net/bfastSpatial/) in order to be able to detect deforestation from Landsat time series using the bfastSpatial algorithm.

## How does bfastSpatial work?
[bfastSpatial] (https://github.com/loicdtx/bfastSpatial) is a tool developed by L. Dutrieux, B. DeVries and J. Verbesselt that applies the pixel based approach of BFAST Monitor in a spatial context.

The BFAST Monitor method consists in fitting a model to the data by Ordinary Least Squares (OLS) fitting, on a period defined as stable history, and testing for stability of the same model, during a period defined as monitoring period (Dutrieux et al., 2015). As shown in the illustration below, if the new data does not fit the model, a break is detected.

![Detecting deforestation using bfastMonitor on Landsat time-series](https://github.com/rosca002/Testing_BFAST_settings/blob/master/amedium.gif)

The tools provided by bfastSpatial R package allows the user to perform all the steps of the change detection workflow (see figure below), from pre-processing raw surface reflectance Landsat data, inventorying and preparing them for analysis to the production and formatting of change detection results. 
![bfastSpatial work-flow](https://github.com/rosca002/Testing_BFAST_settings/blob/master/BfastSpatial3.PNG)

## bfastSpatial parameters
The bfastSpatial function requires the user to set the input parameters (input data, hystory period, monitoring period, and regression model). Other parameters (length of the MOSUM window, etc.) can also be tuned in accordance with the particularities of each specific case study.

```{r, eval=FALSE}
bfmSpatial(x, dates = NULL, pptype = "irregular", start, monend = NULL,
  formula = response ~ trend + harmon, order = 3, lag = NULL,
  slag = NULL, history = c("ROC", "BP", "all"), type = "OLS-MOSUM",
  h = 0.25, end = 10, level = 0.05, mc.cores = 1,
  returnLayers = c("breakpoint", "magnitude", "error"), sensor = NULL, ...)                                       
```

Input data

