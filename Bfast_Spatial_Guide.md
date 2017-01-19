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

To apply the steps of the workflow illusrated above, it is important to understand the parameters of the bfastSpatial function, as it will provide insight on what data is required to be dowloaded.  

## bfastSpatial parameters
The bfastSpatial function requires the user to set the input parameters (input data, hystory period, monitoring period, and regression model). Other parameters (length of the MOSUM window, etc.) can also be tuned in accordance with the particularities of each specific case study.

```{r, eval=FALSE}
bfmSpatial(x, dates = NULL, pptype = "irregular", start, monend = NULL,
  formula = response ~ trend + harmon, order = 3, lag = NULL,
  slag = NULL, history = c("ROC", "BP", "all"), type = "OLS-MOSUM",
  h = 0.25, end = 10, level = 0.05, mc.cores = 1,
  returnLayers = c("breakpoint", "magnitude", "error"), sensor = NULL, ...)                                       
```

##Input data: What vegetation index to use?

Spectral indices, whether wetness related indices or greenness related indices, are simple and robust techniques to extract quantitaive information on the amount of vegetation for every pixel in an image.

NDMI (Normalized Difference Moisture Index) has proven to offer very good results for detecting deforestation from Landsat time series using bfastSpatial, and so, it is recommended to test it as a first option. Nevertheless, for very dry forests with patchy vegetation, NDVI (Normalized Difference Vegetation Index) can be preffered instead.

Both of these indices can be directly downloaded from the USGS archive or processed from Surface Reflectance Bands using the processLandsat() function from the bfastSpatial package as explained in the [mentioned tutorial](http://www.loicdutrieux.net/bfastSpatial/#Data_pre_processing).

In case the algorithm fails to detect deforestation using the NDMI or NDVI, other indices can be tested as Schultz et al.(2016) suggest in their paper "Performance of vegetation indices from Landsat time series in deforestation monitoring". Nevertheless, all other parameters of the bfastSpatial function should be tuned before deciding to test a different vegetation index, as it is more probable that results are not good because of another setting.

##History Period

As mentioned, the basis of the BFAST Monitor method consists in fitting a model to the data from a period defined as stable history. Therefore, to be able to detect deforestion occuring in a desired time span (monitoring period), it is mandatory to have enough data prior to this interval.  

To facilitate reliable monitoring, the history period has to fulfil two essential conditions: (i) to be sufficiently long for model fitting, and (ii) to be free of disturbances, so that the model parameters are stable in this period and can be used to model normal expected behaviour in the monitoring period.

###(i) How long should the history period be?

The second condition relates to the chosen regression model of the algorithm, as from a mathematical point of view, depending on the number of parameters of the regression, there is a need for a certain minimum number of observations in the history period. Of course, the more observations there are in the history period, the better the fitting of the model. Verbesselt et al. (2012) suggest a stable history period of at least two years when using MODIS time-series with a 16 days temporal resolution. While Landsat has a temporal resolution equal or lower than MODIS 16 day composites, it is considered that a minimum history of at least of 2 years is necessary (Dutrieux et al., 2015).

###(ii) How to have a disturbance free history period?

If all observations available before the start of the monitoring period are to be included in the history period, it is unlikely that no disturbance took place during this long period of time. Therefore, in order to meet the first condition, a moment that delineates a stable period in the history period can be provided by expert knowledge or can be calculated automatically using the reverse-order-cumulative sum (ROC or CUSUM) of residuals (Verbesselt et al., 2012).

