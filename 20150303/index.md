This post explores some characteristics of missing data in PITCHf/x data acquired via [**pitchRx**](https://github.com/cpsievert/pitchRx)



## Get your data into memory

When working with PITCHf/x data, it is often useful to join the `"pitch"` table with the `"atbat"` table. To avoid repeating an expensive join operation, I've found it generally useful to join the entire `"pitch"` table with the `"atbat"` table and store the resulting table in [my PITCHf/x database](https://baseballwithr.wordpress.com/2014/03/24/422/).


```r
library("dplyr")
db <- src_sqlite("~/pitchfx/pitchRx.sqlite3")
pa_full <- left_join(tbl(db, "pitch"), tbl(db, "atbat"), 
                     by = c("num", "gameday_link"))
compute(pa_full, name = "pa_full", temporary = FALSE)
```

Although this table is quite large, it fits into memory on machines with a decent amount of RAM (it takes up about 5 out of the 8GB available on my laptop). In general, having your data in memory can **drastically** reduce the computational time of operations. Thus, if you can, `collect()` this table to pull it into R as a data frame.


```r
pa_full <- tbl(db, "pa_full") %>% collect()
dim(pa_full)
```

```
[1] 5348578      74
```

## Exploring missingness

Now that `pa_full` is in memory, let's compute the proportion of `NA`s (which is `R`'s way of encoding missing values) for each variable broken down by year.


```r
prop_na <- function(x) mean(is.na(x))
nas <- pa_full %>% 
  mutate(year = substr(date, 0, 4)) %>%
  group_by(year) %>% 
  summarise_each(funs(prop_na))
```

To plot the proportions, we should transform `nas` from "wide form" (where each variable has it's own column) to "long form" (where variable names are stored in a single column). This is a job for `tidyr::gather()`:


```r
na_tidy <- nas %>% 
  tidyr::gather(variable, prop_na, -year) %>%
  # the row_names variable is useless
  filter(variable != "row_names")
```

For visualization purposes, we'll also want the ordering of the variables to reflect the overall proportion of `NA`s.


```r
# order variables according to the proportion of NAs
na_sort <- na_tidy %>%
  group_by(variable) %>%
  summarise(avg_na = mean(prop_na)) %>%
  arrange(desc(avg_na))
# reorder the variable factor in na_tidy 
na_tidy$variable <- factor(na_tidy$variable, levels = na_sort$variable)
library("ggplot2")
ggplot(data = na_tidy, aes(x = variable, y = prop_na, color = year)) + 
  geom_point(alpha = 0.4) + coord_flip() + xlab("")
```



<p><a href="https://baseballwithr.files.wordpress.com/2015/03/prop_na.png"><img src="https://baseballwithr.files.wordpress.com/2015/03/prop_na.png" alt="prop_na" width="500" height="800" class="alignnone size-full wp-image-810" /></a></p>

I see roughly three different categories of missingness here: (1) nothing missing, (2) partially missing (3) mostly missing. 

Thankfully, variables that are mostly missing are that way by design. It's not very intuitive that `away_team_runs`, `home_team_runs`, or `score` would have missing values, but for some reason, MLBAM programmers decided to populate these variables only when a run was scored during that at-bat/pitch. For modeling purposes, you probably want to replace `NA` with 0 in these columns, but you may also prefer to have these columns have the running total instead (in that case, you can use [this](https://github.com/cpsievert/pitchRx/issues/17)). It makes sense that `event2`, `event2`, & `event4` are mostly missing since most at-bat outcomes can be adequately summarised with a single event (but some need an additional tag like wild-pitch, error, and/or pick-off). We can also see that Spanish translations of at-bat & pitch descriptions (`des_es` & `atbat_des_es`) started in 2012.

The variables that are partially missing (for example, `px`, `pz`, etc) are potentially more worrisome since these are the actual PITCHf/x variables. As I've pointed out in [other posts](https://baseballwithr.wordpress.com/2014/07/28/acquire-minor-league-play-by-play-data-with-pitchrx-4/), it's important to remember that by default, **pitchRx** will acquire some non-MLB games played in non-MLB venues. Thus, we have some observations where it *wasn't possible* to measure these variables. 

To investigate, we essentially perform the same computations as before, but distinguish between regular and non-regular season games.


```r
game <- tbl(db, "game") %>%
  mutate(reg = as.integer(game_type == "R")) %>%
  select(gameday_link, reg) %>%
  collect()
# unfortunately we have to prepend "gid_" for this variable
# to match the one in pa_full
game <- game %>%
  mutate(gameday_link = paste0("gid_", gameday_link))
pa_full <- pa_full %>%
  left_join(game, by = "gameday_link")
```


```r
nas <- pa_full %>% 
  mutate(year = substr(date, 0, 4)) %>%
  group_by(year, reg) %>% 
  summarise_each(funs(prop_na))
na_tidy <- nas %>% 
  tidyr::gather(variable, prop_na, -(year:reg)) %>%
  # the row_names variable is useless
  filter(variable != "row_names")
# order variables according to the proportion of NAs
na_sort <- na_tidy %>%
  group_by(variable) %>%
  summarise(avg_na = mean(prop_na)) %>%
  arrange(desc(avg_na))
# reorder the variable factor in na_tidy 
na_tidy$variable <- factor(na_tidy$variable, levels = na_sort$variable)
library("ggplot2")
ggplot(data = na_tidy, aes(x = variable, y = prop_na, color = year)) + 
  geom_point(alpha = 0.4) + coord_flip() + xlab("") +
  facet_wrap(~reg)
```



<p><a href="https://baseballwithr.files.wordpress.com/2015/03/prop_na2.png"><img src="https://baseballwithr.files.wordpress.com/2015/03/prop_na2.png" alt="prop_na2" width="500" height="800" class="alignnone size-full wp-image-810" /></a></p>

Within the regular season panel (labeled '1') above, there are hardly any missing values for the variables I previously called partially missing. If you look closely in that panel, most of the missing values occur in 2008 when the PITCHf/x system was still being adopted. This means that we can explain the missing values based on what we've observed, which is a type of missingness that statisticians refer to as *Missing At Random* or *ignorable*. This is a good thing, since this type of missing data can be ignored without it effecting likelihood based models ([such as](https://baseballwithr.wordpress.com/2014/04/21/are-umpires-becoming-less-merciful/) the Generative Additive Models [I've used](https://baseballwithr.wordpress.com/2014/10/23/a-probabilistic-model-for-interpreting-strike-zone-expansion-7/) to model the probability of a called strike).
