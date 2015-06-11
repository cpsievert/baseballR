---
title: "3D surface plots of the strikezone"
author: "Carson Sievert"
date: "June 7, 2015"
output: html_document
---

Over the past month, I've been working on [plotly's R package](https://github.com/ropensci/plotly); and in particular, a [new interface for creating plotlys from R](http://cpsievert.github.io/plotly/dsl/). I'm really excited about this project and I think it's one of the most elegant, straight-forward ways to create interactive graphics that are easy to share. In this post, I'll show you just how easy it is to create 3D surface plots of the strikezone using plotly.

### Kernel Densities

The __MASS__ package in R has a function called `kde2d()` which performs 2D density estimation (with a bivariate normal kernel) 


```r
data(pitches, package = "pitchRx")
dens <- with(pitches, MASS::kde2d(px, pz))
```


```r
# plotly isn't available on CRAN, but u can install from GitHub
# devtools::install_github("ropensci/plotly@carson-dsl")
library(plotly)
with(dens, plot_ly(x = x, y = y, z = z, type = "surface"))
```

```
## Success! Created a new plotly here -> https://plot.ly/~cpsievert/1086
```

<iframe height="600" id="igraph" scrolling="no" seamless="seamless" src="https://plot.ly/~cpsievert/1086" width="800" frameBorder="0"></iframe>

Although this plot is cool, we can't perform any interesting statistical inference with it. All we can see is an estimated frequency.

### Probabilistic Surfaces

Brian Mills and I [have](http://princeofslides.blogspot.com/2013/07/advanced-sab-r-metrics-parallelization.html) a [number](https://baseballwithr.wordpress.com/2014/04/21/are-umpires-becoming-less-merciful/) [of](https://baseballwithr.wordpress.com/2014/10/23/a-probabilistic-model-for-interpreting-strike-zone-expansion-7/) [posts/papers](http://onlinelibrary.wiley.com/doi/10.1002/mde.2630/abstract) on using generalized additive models (GAMs) to model event probabilities over the strikezone. To keep things simple, we'll stick with the example data, and model the probablity of a called strike by allowing it to vary by location and batter stance.


```r
# condition on umpire decisions
noswing <- subset(pitches, des %in% c("Ball", "Called Strike"))
noswing$strike <- as.numeric(noswing$des %in% "Called Strike")
library(mgcv)
```

```
## Loading required package: nlme
## This is mgcv 1.8-6. For overview type 'help("mgcv-package")'.
```

```r
m <- bam(strike ~ s(px, pz, by = factor(stand)) + factor(stand), 
         data = noswing, family = binomial(link = 'logit'))
```

Now we use the `predict.gam()` method to fit response values (for right handers) over a strike-zone grid.


```r
px <- round(seq(-2, 2, length.out = 20), 2)
pz <- round(seq(1, 4, length.out = 20), 2)
dat <- expand.grid(px = px, pz = pz, stand = "R")
dat$fit <- as.numeric(predict(m, dat, type = "response"))
```

plotly's `z` argument likes numeric matrices, so we need change the data structure accordingly.


```r
z <- Reduce(rbind, split(dat$fit, dat$px))
plot_ly(x = px, y = pz, z = z, type = "surface")
```

```
## Success! Created a new plotly here -> https://plot.ly/~cpsievert/1088
```

<iframe height="600" id="igraph" scrolling="no" seamless="seamless" src="https://plot.ly/~cpsievert/1088" width="800" frameBorder="0"></iframe>

It's probably more interesting to look at the difference in fitted values for right/left handed batters:


```r
dat2 <- expand.grid(px = px, pz = pz, stand = "L")
dat2$fit <- as.numeric(predict(m, dat2, type = "response"))
z <- Reduce(rbind, split(dat2$fit - dat$fit, dat2$px))
plot_ly(x = px, y = pz, z = z, type = "surface")
```

```
## Success! Created a new plotly here -> https://plot.ly/~cpsievert/1090
```

<iframe height="600" id="igraph" scrolling="no" seamless="seamless" src="https://plot.ly/~cpsievert/1090" width="800" frameBorder="0"></iframe>



