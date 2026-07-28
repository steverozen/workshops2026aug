## ggplot2 reproduction of a seaborn lineplot style, using uschange_mts.
## Plots every quarter; one panel per variable with its own y scale.

library(DataSetsVerse)
library(timeSeriesDataSets)
library(tidyverse)

## Wide multivariate ts -> long data frame with year as the timepoint.
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
  ) |>
  mutate(variable = factor(variable,
    levels = c("Unemployment", "Consumption", "Production", "Income", "Savings")))

ggplot(df, aes(x = date, y = value)) +
  geom_line(aes(color = variable)) +
  geom_smooth(aes(fill = variable), method = "loess", se = TRUE, span = 0.1,
              color = "black", alpha = 0.3, linewidth = 0.3) +
  facet_wrap(~ variable, scales = "free_y", ncol = 1, strip.position = "right") +
  labs(x = "date", y = "value", color = "variable") +
  theme_gray() +
  theme(
    panel.background = element_rect(fill = "grey90"),
    panel.grid.major = element_line(color = "white"),
    panel.grid.minor = element_line(color = "white")
  )

ggsave("/tmp/uschange_seaborn_style.png", width = 8, height = 9, dpi = 120)
