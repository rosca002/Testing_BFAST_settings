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

As mentioned, the basis of the BFAST Monitor method consists in fitting a model to the data of a period defined as stable history. Therefore, to be able to detect deforestion occuring in a desired time span (monitoring period), it is mandatory to have enough data prior to this interval.  

To facilitate reliable monitoring, the history period has to fulfil two essential conditions: (i) to be sufficiently long for model fitting, and (ii) to be free of disturbances, so that the model parameters are stable in this period and can be used to model normal expected behaviour in the monitoring period.

###(i) How long should the history period be?

The second condition relates to the chosen regression model of the algorithm, as from a mathematical point of view, depending on the number of parameters of the regression, there is a need for a certain minimum number of observations in the history period. Of course, the more observations there are in the history period, the better the fitting of the model. Verbesselt et al. (2012) suggest a stable history period of at least two years when using MODIS time-series with a 16 days temporal resolution. While Landsat has a temporal resolution equal or better than MODIS 16 day composites, due to the presence of clouds in the images, a longer history period is required. For a frequently cloudy area (like the tropics), it is advisable to have a minimum number of 55-60 scenes in the history period. This should be able to provide enough observations per pixel for the algorithm to fit a model (a min of 20 observations per pixel, and a mean of 40-50 observations per pixel). The more cloudy the scenes are, the bigger the number of scenes needed. 

###(ii) How to have a disturbance free history period?

If all observations available before the start of the monitoring period are to be included in the history period, it is unlikely that no disturbance took place during this long period of time. Therefore, in order to meet the first condition, a moment that delineates a stable period in the history period can be provided by expert knowledge or can be calculated automatically using the reverse-order-cumulative sum (ROC or CUSUM) of residuals (Verbesselt et al., 2012). 

If there is knowledge of a disturbance in the history period that affects the entire study area, to minimise the processing time, it is advisable to manually define the start of the history period as being after the disturbance rather than applying ROC. In this case, eventhough the bfastSpatial function has the option to choose as a start date of the history period a different date than the date of the first scene of the provided time-series, it is considerably faster to trim the time-series as a pre-process step, and set the trimmed timestack as input for the function.

In cases were there is an extremly low number of scenes available (due to cloud coverage, e.g. Gabon) it is recomended to use all scenes available in the hstory period, whith the condition to visually assess the study area for disturbances in this period.

##Monitoring period

The monitoring period is decided by the user. It is the period in which the change is studied.

###Full monitoring period approach

The whole period studied is considered as being part of the monitoring period.

```{r, eval=FALSE}
bfmSpatial(P_ndmiStack, start = c(2010, 1), formula = response~harmon,
           order = 1, history = c(2000, 1), filename = out))
```                               

The bfastSpatial algorithm detects deforestation in near-real time, meaning that there is a delay in detecting the deforestation. This delay is entirely dependent of the data itself, as for a structural break to be declared, the MOSUM needs to exceed a 95% confidence interval of the calculated residuals in the history period. Therefore, in order to capture deforestation events that occured at the end of the monitoring period, some extra scenes after this point should also be included.

###Sequential monitoring approach

The sequential monitoring approach was developed by DeVries et al. (2015b) specifically for cases where the monitoring period is longer, taking into account that the measure of change magnitude could be affected by an increased number of observations before and after a change event.

This approach limits the monitoring period to one year, and applies the analysis in an iterative way, using sequentially defined monitoring periods. It is advisable to use this method if the monitoring period excedees 5 years.

```{r, eval=FALSE}
bfmSpatial(P_ndmiStack, start = c(2010, 1),monend=c(2011,1), formula = response~harmon,
           order = 1, history = c(2000, 1), filename = out))
```           

This method of applying bfastSpatial offers a slightly better accuracy than using the full monitoring period approach. This approach can make a big difference in the cases with very few observations available, as the history period is enlarged with every iteration.

The downsize of using the sequential approach is the processing time. It takes as much time as aplying bfastSpation using the full monitoring period times the number of years in the monitoring period (number of iterations).

At the moment, using the sequential approach implies more post-processing steps, as each iteration will yield the deforestation for the 1 year monitoring period, and so, all results have to be post-process into one.

##Regression model

The BFAST Monitor algorithm consists in fitting a model to the data in the stable history period, and testing for stability of the same model, during the monitoring period.

The general additive seasonal trend model as used by Verbesselt et al. (2012) to detect change within satellite time-series is the following:
y_t=α_1+α_2 t+∑_(j=1)^k▒〖γ_j  sin⁡〖(2πjt/f〗 〗+δ_j)+ε_t  ,                                                                 (1)

where the dependent variable y at a given time t is expressed as the sum of an intercept α_1, a slope α_2 for potential temporal trend in the data, a sum of different frequency harmonic components representing seasonality ( ∑_(j=1)^k▒〖γ_j  sin⁡〖(2πjt/f〗 〗+δ_j) ), and an error term ε_t. For the harmonic component of the model, j=1 corresponds to the one year cycle, k is the choosen harmonic order, γ_j and δ_j correspond respectively to the amplitude and phase of the harmonic order j, and f is the known frequency of the time-series - i.e. number of observations per year (Verbesselt et al., 2012).
Choosing the parameters of the regression model in order for the time-series analysis algorithm to offer the most accurate results in respect to detecting deforestation, depends on the particularities of each AOI: (i) the phenology of the forest and (ii) the number and frequency of the cloud-free available imagery. 
The phenology of the forest present in the AOI translates into choosing the appropriate harmonic order of the model in order to follow as closely as possible the seasonal patterns, and in deciding if trend is, or not, to be included in the model. 
The number and frequency of the cloud-free available imagery of the AOI can also influence the choice of harmonic order in the sense that the more complex the regression, more observations are needed in the history period. Therefore, even though present, complex seasonal patterns might not be detectable with Landsat data alone, if the AOI is frequently cloud covered.  
The “selva alta” evergreen forest in the Peru study site, presents two distinct seasons: a wet one occurring around February-March and a dry one in July-August (Figure 3). In this case, a simple single order model was used for the time-series analysis, as there are also enough available observations in the history period (Figure 8) to be able to fit this model.
In the case of the Gabon study site, the equatorial forest has no seasonality at all, the constant function, the mean of the observations in the history period, being the appropriate one to use in the analysis. This constant model is also imposed by the extremely low number of observations in the history period (Figure 10).

