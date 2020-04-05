
# This code requires both ggplot2 and afex

rm(list = ls())

# Change this variable based on where you unzipped the Git repo
proj_path <- file.path('C:', 'Users', 'isaac', 'Projects', 'pupl-worked-example')

exp_path <- file.path(proj_path, 'export')

diff_as_fac <- function(data) {
  # Get difficulty as a factor
  difficulty <- rep(NA, nrow(data))
  difficulty[data$set_Easy == 1] <- 'Easy'
  difficulty[data$set_Medium == 1] <- 'Medium'
  difficulty[data$set_Hard == 1] <- 'Hard'
  (table(difficulty)) # Double check that there are the same numbers for each trial type
  # Order the factor
  data$difficulty <- factor(difficulty,
                            levels = c('Easy',
                                       'Medium',
                                       'Hard'))
  return(data)
}

## Standard analysis

# Load the data
data <- read.csv(file.path(exp_path, 'stats-basic.csv'))

# Get difficulty as a factor
data <- diff_as_fac(data)

# Anova
anova(
  aov(
    trial_mean ~
      difficulty,
    data = data
  )
)
# Linear model, to get estimates of the effects
summary(
  lm(
    trial_mean ~
      difficulty,
    data = data
  )
)
# Visualize
ggplot2::ggplot(data,
                ggplot2::aes(x = difficulty,
                             y = trial_mean)) +
  # Nice colourful violin plots in the background
  ggplot2::geom_violin(mapping = ggplot2::aes(fill = difficulty)) +
  # Businesslike boxplots in the foreground
  ggplot2::geom_boxplot(width = 0.3) +
  # Legend is redundant with x-axis, so remove it
  ggplot2::theme(legend.position = "none") +
  # Improve axis labels
  ggplot2::labs(x = 'Difficulty',
                y = 'Mean pupil diameter (relative to baseline mean)')

## Mixed effects analysis

# Load the data
data <- read.csv(file.path(exp_path, 'stats-long.csv'))

# Get difficulty as a factor
data <- diff_as_fac(data)

# Run a mixed effects model
lme.mod <- afex::lmer(
  trial_mean ~
    difficulty +
    (1 | recording),
  data = subset(data, rejected != 1)
)
summary(lme.mod)

## Long format downsampled data

# Load the data
data <- read.csv(file.path(exp_path, 'ds-long.csv'))

# Get difficuly as a factor
data <- diff_as_fac(data)

# Plot the data
ggplot2::ggplot(mapping = ggplot2::aes(x = win_start,
                                       y = pupil_diameter)) +
  # Line plot with some transparency
  # Note that the interaction between recording and difficulty
  # is necessary for the lines to show up properly
  ggplot2::geom_line(data = data,
                     mapping = ggplot2::aes(color = difficulty,
                                            group = interaction(recording,
                                                                difficulty)),
                     alpha = 0.5) +
  # LOESS regression (only for the data later than 5 seconds,
  # otherwise the smoothing is too dang smooth)
  ggplot2::geom_smooth(data = subset(data, win_start > 5),
                       mapping = ggplot2::aes(color = difficulty),
                       method = loess,
                       formula = y ~ x) +
  ggplot2::labs(x = 'Downsampled window start (s)',
                y = 'Pupil diameter (arbitrary units, change from baseline)',
                color = 'Difficulty')

ggplot2::ggplot(data,
                mapping = ggplot2::aes(x = win_start,
                                       y = pupil_diameter,
                                       color = difficulty)) +
  ggplot2::geom_smooth(stat = 'summary',
                       fun.data = function(y) {
                         data.frame(
                           y = mean(y),
                           ymax = mean(y) + sd(y) / sqrt(length(y)),
                           ymin = mean(y) - sd(y) / sqrt(length(y))
                         )
                       }) +
  ggplot2::labs(x = 'Downsampled window start (s)',
                y = 'Pupil diameter (arbitrary units, change from baseline)',
                color = 'Difficulty')
