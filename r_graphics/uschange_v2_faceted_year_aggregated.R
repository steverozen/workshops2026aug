## v2: same year-aggregated mean + 95% CI as v1, but faceted with one
## panel per variable and free y scales so each series gets its own range.

library(DataSetsVerse)
library(timeSeriesDataSets)
library(tidyverse)

df <- as.data.frame(uschange_mts) |>
  mutate(
    date = as.Date(paste0(
      rep(1970:2016, each = 4)[seq_len(nrow(uschange_mts))], "-",
      c("01", "04", "07", "10")[((seq_len(nrow(uschange_mts)) - 1) %% 4) + 1],
      "-01"
    )),
    year = as.numeric(format(date, "%Y"))
  ) |>
  pivot_longer(
    cols = c(Consumption, Income, Production, Savings, Unemployment),
    names_to = "variable",
    values_to = "value"
  )

ggplot(df, aes(x = year, y = value,
               color = variable, linetype = variable, shape = variable)) +
  stat_summary(fun.data = mean_cl_normal, geom = "ribbon",
               aes(fill = variable), color = NA, alpha = 0.2) +
  stat_summary(fun = mean, geom = "line") +
  stat_summary(fun = mean, geom = "point", size = 2) +
  facet_wrap(~ variable, scales = "free_y", ncol = 1, strip.position = "right") +
  labs(x = "year", y = "value", color = "variable",
       linetype = "variable", shape = "variable", fill = "variable") +
  theme_gray() +
  theme(
    panel.background = element_rect(fill = "grey90"),
    panel.grid.major = element_line(color = "white"),
    panel.grid.minor = element_line(color = "white")
  )

ggsave("/tmp/uschange_v2_faceted_year_aggregated.png",
       width = 8, height = 9, dpi = 120)
