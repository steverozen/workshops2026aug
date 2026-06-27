library(tidyverse)

fmri <- read_csv(here::here("fmri.csv"))

p <- ggplot(fmri, aes(x = timepoint, y = signal,
                      colour = region, linetype = event,
                      fill = region)) +
  stat_summary(fun.data = mean_cl_boot, geom = "ribbon",
               alpha = 0.2, colour = NA) +
  stat_summary(fun = mean, geom = "line", linewidth = 0.8) +
  scale_colour_manual(values = c(parietal = "#4C72B0", frontal = "#DD8452")) +
  scale_fill_manual(values   = c(parietal = "#4C72B0", frontal = "#DD8452")) +
  scale_linetype_manual(values = c(stim = "solid", cue = "dashed")) +
  theme_gray(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#EAEAF2", colour = NA),
    panel.grid.major = element_line(colour = "white"),
    panel.grid.minor = element_line(colour = "white", linewidth = 0.3),
    legend.key = element_rect(fill = "#EAEAF2")
  ) +
  labs(x = "timepoint", y = "signal", colour = "region",
       linetype = "event", fill = "region")

ggsave("/tmp/fmri_seaborn_lineplot.png", p, width = 6.5, height = 4.5, dpi = 150)
