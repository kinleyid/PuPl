
# This code requires:
#   ggplot2
#   afex
#   stringr

rm(list = ls())

# Change this variable based on where you unzipped the Git repo
proj_path <- file.path('C:', 'Users', 'isaac', 'Projects', 'pupl-worked-example')

exp_path <- file.path(proj_path, 'export')

## Standard analysis

# Load the data
stats_basic <- read.csv(file.path(exp_path, 'stats-basic.csv'))

# Order the difficulty factor
stats_basic$epoch_set <- factor(stats_basic$epoch_set,
                                levels = c('Easy',
                                           'Medium',
                                           'Hard'))

# Anova
anova(
  aov(
    trial_mean ~
      epoch_set,
    data = stats_basic
  )
)
# Linear model, to get estimates of the effects
summary(
  lm(
    trial_mean ~
      0 +
      epoch_set,
    data = stats_basic
  )
)
# Visualize
ggplot2::ggplot(stats_basic,
                ggplot2::aes(x = epoch_set,
                             y = trial_mean)) +
  # Nice colourful violin plots in the background
  ggplot2::geom_violin(mapping = ggplot2::aes(fill = epoch_set)) +
  # Businesslike boxplots in the foreground
  ggplot2::geom_boxplot(width = 0.3) +
  # Legend is redundant with x-axis, so remove it
  ggplot2::theme(legend.position = "none") +
  # Improve axis labels
  ggplot2::labs(x = 'Difficulty',
                y = 'Mean pupil diameter (relative to baseline mean)')

## Mixed effects analysis

# Load the data
stats_long <- read.csv(file.path(exp_path, 'stats-long.csv'))

# Convert difficulty from a design matrix to a single factor
difficulty <- rep(NA, nrow(stats_long))
difficulty[stats_long$set_Easy == 1] <- 'Easy'
difficulty[stats_long$set_Medium == 1] <- 'Medium'
difficulty[stats_long$set_Hard == 1] <- 'Hard'
(table(difficulty)) # Double check that there are the same numbers for each trial type
# Order the factor
stats_long$difficulty <- factor(difficulty,
                                levels = c('Easy',
                                           'Medium',
                                           'Hard'))

# Run a mixed effects model
anova(
  afex::lmer(
    trial_mean ~
      difficulty +
      (1 | recording),
    data = subset(stats_long, !rejected)
  )
)

summary(
  afex::lmer(
    trial_mean ~
      0 +
      difficulty +
      (1 | recording),
    data = subset(stats_long, !rejected)
  )
)

## Wide-format downsampled data

# Load the data
ds_wide <- read.csv(file.path(exp_path, 'ds-wide.csv'))

# Order the difficulty factor
ds_wide$epoch_set <- factor(ds_wide$epoch_set,
                            levels = c('Easy',
                                       'Medium',
                                       'Hard'))

# Find the columns that contain the data
data_cols <- grep('t\\d+', colnames(ds_wide))

# Find where the 3 conditions are most differentiated
all_Fs <- c()
all_ps <- c()
for (curr_col in data_cols) {
  # Create the new column that we will be analyzing
  ds_wide$curr <- ds_wide[, curr_col]
  # Run the anova
  aov.res <- anova(
    aov(
      curr ~
        epoch_set,
      data = ds_wide
    )
  )
  # Collect the statistics
  all_Fs[length(all_Fs) + 1] <- aov.res['epoch_set', 'F value']
  all_ps[length(all_ps) + 1] <- aov.res['epoch_set', 'Pr(>F)']
}

# Bonferroni-correct the p-values
all_ps <- all_ps * length(all_ps)

# Read window times from column names
# Column names have the following format:
#   t<window number>_<window start>_<window end>
# We will use a regular expression to read the window starts
win_starts <- as.numeric(
  stringr::str_match(
    colnames(ds_wide)[data_cols],
    't[0-9]+_([0-9]+\\.*[0-9]*)'
  )[, 2]
)

# Create a new data frame for plotting
anova_result <- data.frame(
  win_start = win_starts,
  F_value = all_Fs,
  p_value = all_ps
)

# Display the data
ggplot2::ggplot(anova_result,
                ggplot2::aes(x = win_start,
                             y = F_value)) +
  # Put the non-significant area plot in the background
  ggplot2::geom_area(ggplot2::aes(fill = F)) +
  # Put the significant area plot in the foreground
  ggplot2::geom_area(data = subset(anova_result, p_value < 0.05),
                     mapping = ggplot2::aes(fill = T)) +
  # Outline it with a line
  ggplot2::geom_line() +
  # Order the colours so that the warm colour indicates significance
  ggplot2::scale_fill_discrete(name = 'Significance\n(Bonferroni-\ncorrected)',
                               limits = c(T, F),
                               labels = c('p < 0.05', 'p > 0.05')) +
  ggplot2::labs(x = 'Downsampled window start (s)',
                y = 'F value')

## Long-format downsampled data

# Load the data
ds_long <- read.csv(file.path(exp_path, 'ds-long.csv'))

# Order the difficulty factor
ds_long$epoch_set <- factor(ds_long$epoch_set,
                            levels = c('Easy',
                                       'Medium',
                                       'Hard'))

# Plot the data

ggplot2::ggplot(ds_long,
                mapping = ggplot2::aes(x = win_start,
                                       y = pupil_diameter,
                                       color = epoch_set)) +
  # Line plots with ribbons for SEM
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

ggplot2::ggplot(mapping = ggplot2::aes(x = win_start,
                                       y = pupil_diameter)) +
  # Line plot with some transparency
  # Note that the interaction between recording and difficulty
  # is necessary for the lines to show up properly
  ggplot2::geom_line(data = ds_long,
                     mapping = ggplot2::aes(color = epoch_set,
                                            group = interaction(recording,
                                                                epoch_set)),
                     alpha = 0.5) +
  # LOESS regression (only for the data later than 5 seconds,
  # otherwise the smoothing is too dang smooth)
  ggplot2::geom_smooth(data = subset(ds_long, win_start > 5),
                       mapping = ggplot2::aes(color = epoch_set),
                       method = loess,
                       formula = y ~ x) +
  ggplot2::labs(x = 'Downsampled window start (s)',
                y = 'Pupil diameter (arbitrary units, change from baseline)',
                color = 'Difficulty')

# Combine data into a big plot

ggplot2::ggplot() +
  # Display significance in the background
  ggplot2::geom_ribbon(data = anova_result,
                       mapping = ggplot2::aes(x = win_start,
                                              ymin = -400,
                                              ymax = -375,
                                              fill = p_value < 0.05)) +
  # Set the fill so that warm colours indicate significance
  ggplot2::scale_fill_discrete(name = 'Significance\n(Bonferroni-\ncorrected)',
                               limits = c(T, F),
                               labels = c('p < 0.05', 'p > 0.05')) +
  # Plot the averages again
  ggplot2::geom_smooth(data = ds_long,
                       mapping = ggplot2::aes(x = win_start,
                                              y = pupil_diameter,
                                              color = epoch_set),
                       stat = 'summary',
                       fun.data = function(y) {
                         data.frame(
                           y = mean(y),
                           ymax = mean(y) + sd(y) / sqrt(length(y)),
                           ymin = mean(y) - sd(y) / sqrt(length(y))
                         )
                       }) +
  ggplot2::labs(x = 'Downsampled window start (s)',
                y = 'Pupil diameter (arbitrary units, change from baseline)',
                color = 'Difficulty',
                fill = 'Significance')

