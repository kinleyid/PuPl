
library(ggplot2)
library(afex)
library(stringr)

rm(list = ls())

# Change this variable based on where you unzipped the Git repo
eg_path <- file.path('C:', 'Users', 'isaac', 'Projects', 'PuPl', 'example')

## Standard analysis

# Load the data
stats_basic <- read.csv(file.path(eg_path, 'stats-basic.csv'))

# Order the difficulty factor
stats_basic$epoch_set <- factor(stats_basic$epoch_set,
                                levels = c('Easy',
                                           'Medium',
                                           'Hard'))

# Repeated-measures ANOVA
summary(
  aov(
    trial_mean ~
      epoch_set +
      Error(recording),
    data = stats_basic
  )
)
# Summary table
aggregate(
  trial_mean ~ epoch_set,
  stats_basic, function(x) {
    c(
      n = length(x),
      mean = mean(x),
      sd = sd(x)
    )
  }
)
# Visualize
ggplot(stats_basic,
       aes(x = epoch_set,
           y = trial_mean)) +
  # Nice colourful violin plots in the background
  geom_violin(mapping = aes(fill = epoch_set)) +
  # Businesslike boxplots in the foreground
  geom_boxplot(width = 0.3) +
  # Legend is redundant with x-axis, so remove it
  theme(legend.position = "none") +
  # Improve axis labels
  labs(x = 'Difficulty',
       y = 'Mean pupil diameter (relative to baseline mean)')

## Mixed effects analysis

# Load the data
stats_long <- read.csv(file.path(eg_path, 'stats-long.csv'))

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
  lmer(
    trial_mean ~
      difficulty +
      epoch_idx +
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
  aov.res <- summary(
    aov(
      curr ~
        epoch_set +
        Error(recording),
      data = ds_wide
    )
  )
  # Collect the statistics
  all_Fs[length(all_Fs) + 1] <- aov.res[['Error: Within']][[1]]['epoch_set', 'F value']
  all_ps[length(all_ps) + 1] <- aov.res[['Error: Within']][[1]]['epoch_set', 'Pr(>F)']
}

# Dunn-Bonferroni-correct the p-values
all_ps <- all_ps * length(all_ps)

# Read window times from column names
# Column names have the following format:
#   t<window number>_<window start>_<window end>
# We will use a regular expression to read the window numbers, starts, and ends
win_ns <- as.numeric(
  str_match(
    colnames(ds_wide)[data_cols],
    't([0-9]+)'
  )[, 2]
)
win_starts <- as.numeric(
  str_match(
    colnames(ds_wide)[data_cols],
    't[0-9]+_([0-9]+\\.*[0-9]*)'
  )[, 2]
)
win_ends <- as.numeric(
  str_match(
    colnames(ds_wide)[data_cols],
    't[0-9]+_.*_([0-9]+\\.*[0-9]*)'
  )[, 2]
)

# Create a new data frame for plotting
anova_result <- data.frame(
  win_start = win_starts,
  F_value = all_Fs,
  p_value = all_ps
)

# Display the data
ggplot(anova_result,
       aes(x = win_start,
           y = F_value)) +
  # Put the non-significant area plot in the background
  geom_area(aes(fill = T)) +
  # Put the significant area plot in the foreground
  geom_ribbon(aes(ymin = 0,
                  ymax = ifelse(
                    p_value > 0.05,
                    F_value,
                    NA),
                  fill = F)) +
  # Outline it with a line
  geom_line() +
  # Order the colours so that the warm colour indicates significance
  scale_fill_discrete(name = 'Significance\n(Dunn-\nBonferroni-\ncorrected)',
                      limits = c(T, F),
                      labels = c('p < 0.05', 'p > 0.05')) +
  labs(x = 'Downsampled window start (s)',
       y = 'Effect of difficulty (F value from repeated measures ANOVA)') +
  theme_classic()

## Long-format downsampled data

# Load the data
ds_long <- read.csv(file.path(exp_path, 'ds-long.csv'))

# Order the difficulty factor
ds_long$epoch_set <- factor(ds_long$epoch_set,
                            levels = c('Easy',
                                       'Medium',
                                       'Hard'))

# Plot the data

ggplot(ds_long,
       mapping = aes(x = win_start,
                     y = pupil_diameter,
                     color = epoch_set)) +
  # Plot each individual participant's data in the background with some transparency
  geom_line(data = ds_long,
            mapping = aes(color = epoch_set,
                          group = interaction(recording,
                                              epoch_set)),
            alpha = 0.2) +
  # Line plots with ribbons for SEM
  geom_smooth(stat = 'summary',
              fun.data = function(y) {
                data.frame(
                  y = mean(y),
                  ymax = mean(y) + sd(y) / sqrt(length(y)),
                  ymin = mean(y) - sd(y) / sqrt(length(y))
                )
              }) +
  labs(x = 'Downsampled window start (s)',
       y = 'Pupil diameter (arbitrary units, change from baseline)',
       color = 'Difficulty') +
  theme_classic()

ggplot(mapping = aes(x = win_start,
                     y = pupil_diameter)) +
  # Line plot with some transparency
  # Note that the interaction between recording and difficulty
  # is necessary for the lines to show up properly
  geom_line(data = ds_long,
            mapping = aes(color = epoch_set,
                          group = interaction(recording,
                                              epoch_set)),
            alpha = 0.2) +
  # LOESS regression (only for the data later than 5 seconds,
  # otherwise the smoothing doesn't capture the trend)
  geom_smooth(data = subset(ds_long, win_start > 5),
              mapping = aes(color = epoch_set),
              method = loess,
              formula = y ~ x) +
  labs(x = 'Downsampled window start (s)',
       y = 'Pupil diameter (arbitrary units, change from baseline)',
       color = 'Difficulty')

# Combine data into a big plot

ggplot() +
  # Display significance in the background
  geom_ribbon(data = anova_result,
              mapping = aes(x = win_start,
                            ymin = -400,
                            ymax = -375,
                            fill = F)) +
  geom_ribbon(data = anova_result,
              mapping = aes(x = win_start,
                            ymin = ifelse(
                              p_value < 0.05,
                              -400,
                              NA), # NA values
                            ymax = ifelse(
                              p_value < 0.05,
                              -375,
                              NA),
                            fill = T)) +
  # Set the fill so that warm colours indicate significance
  scale_fill_discrete(name = 'Significance\n(Dunn-\nBonferroni-\ncorrected)',
                      limits = c(T, F),
                      labels = c('p < 0.05', 'p > 0.05')) +
  geom_line(data = ds_long,
            mapping = aes(x = win_start,
                          y = pupil_diameter,
                          color = epoch_set,
                          group = interaction(recording,
                                              epoch_set)),
            alpha = 0.2) +
  # Plot the averages again
  geom_smooth(data = ds_long,
              mapping = aes(x = win_start,
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
  labs(x = 'Downsampled window start (s)',
       y = 'Pupil diameter (arbitrary units, change from baseline)',
       color = 'Difficulty',
       fill = 'Significance') +
  theme_classic()
