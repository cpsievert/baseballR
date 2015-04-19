# setwd("20150415")
devtools::source_gist("4673815529b7a1e6c1aa")
# variables that we'll use for cluster analysis
vars <- c("start_speed", "break_y", "break_angle", "break_length")

# Rivera tour with color determined by MLBAM pitch type
data(pitches, package = "pitchRx")
rivera <- subset(pitches, pitcher_name == "Mariano Rivera")
pitch_tour(rivera, out_dir = "rivera")
# servr::httd("rivera")

# Rivera tour with color determined by model based clustering
rivera_num <- rivera[names(rivera) %in% vars]
rivera_num[] <- lapply(rivera_num, as.numeric)
m <- mclust::Mclust(rivera_num)
rivera_num$classification <- m$classification
pitch_tour(rivera_num, color_by = "classification", out_dir = "rivera-mbc")
# servr::httd("rivera-mbc")

# Buerhle tour with color determined by MLBAM pitch type
mark <- read.csv("http://www.brianmmills.com/uploads/2/3/9/3/23936510/markb2013.csv")
mark$date2 <- as.Date(mark$date, "%m/%d/%Y")
mark <- subset(mark, date2 > "2013-04-01")
pitch_tour(mark, out_dir = "mark")
# servr::httd("mark")

# Buerhle tour with color determined by model based clustering
mark_num <- mark[names(mark) %in% vars]
mark_num[] <- lapply(mark_num, as.numeric)
m2 <- mclust::Mclust(mark_num)
mark_num$classification <- m2$classification
pitch_tour(mark_num, color_by = "classification", out_dir = "mark-mbc")
# servr::httd("mark-mbc")
