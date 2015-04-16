# setwd("20150415")
library(tourr)
library(animint)

pitch_tour <- function(dat, vars = c("start_speed", "break_y", "break_angle", "break_length"),
                       nprojs = 200, out_dir = tempdir()) {
  kept <- dat[names(dat) %in% vars]
  kept[] <- lapply(kept, as.numeric)
  mat <- rescale(as.matrix(kept))
  tour <- new_tour(mat, grand_tour(), NULL)
  steps <- c(0, rep(1/15, nprojs))
  stepz <- cumsum(steps)
  tour_dat <- function(step_size) {
    step <- tour(step_size)
    proj <- center(mat %*% step$proj)
    df <- data.frame(x = proj[,1], y = proj[,2], type = rivera$pitch_type)
    list(dat = df, proj = data.frame(step$proj, vars = vars))
  }
  dats <- lapply(steps, tour_dat)
  datz <- Map(function(x, y) cbind(x$dat, step = y), dats, stepz)
  dat <- do.call("rbind", datz)
  projz <- Map(function(x, y) cbind(x$proj, step = y), dats, stepz)
  projs <- do.call("rbind", projz)
  projs$X1 <- round(projs$X1, 3)
  projs$X2 <- round(projs$X2, 3)
  p <- ggplot() + 
    geom_point(data = dat,
               aes(x = x, y = y, colour = type, showSelected = step)) +
    geom_segment(data = projs, alpha = 0.25,
                 aes(x = 0, y = 0, xend = X1, yend = X2, showSelected = step)) +
    geom_text(data = projs, alpha = 0.25,
              aes(x = X1, y = X2, label = vars, showSelected = step))
  plist <- list(
    plot = p,
    time = list(variable = "step", ms = 300),
    duration = list(step = 300)
  )
  animint2dir(plist, out.dir = out_dir, open.browser = FALSE)
}

data(pitches, package = "pitchRx")
rivera <- subset(pitches, pitcher_name == "Mariano Rivera")
pitch_tour(rivera, out_dir = "tour1")
# servr::httd("tour1")
pitch_tour(rivera, vars = c("break_angle", "break_length"), out_dir = "tour2")

# library(tourr)
# animate(kept, grand_tour(), display_xy())
# animate(kept, grand_tour(), display_dist())
# 
# #kept <- cbind(kept, pitch_type = rivera$pitch_type)
# animate_xy(kept, guided_tour(holes))
# animate_xy(kept, guided_tour(cmass))
# animate_xy(kept, guided_tour(lda_pp(rivera$pitch_type)))
