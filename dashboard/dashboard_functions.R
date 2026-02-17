make_plot <- function(data, site, vars, start, end, colors) {
  recent <- data %>%
    filter(
      Site == site,
      as.Date(TIMESTAMP) >= start,
      as.Date(TIMESTAMP) <= end
    ) %>%
    select(all_of(c("TIMESTAMP", vars))) %>%
    pivot_longer(vars)
  
  p <- ggplot(recent, aes(TIMESTAMP, value, color = name)) +
    geom_point(size = 0.3) +
    theme_classic() +
    facet_wrap(~name, scales = "free_y") +
    scale_color_manual(values = colors) +
    theme(axis.title.x = element_blank(), legend.position = "none") +
    ggtitle(site)
  
  plotly::ggplotly(p, tooltip = c("TIMESTAMP", "value"))
}

latest_times <- function(df) {
  df %>%
    group_by(Site) %>%
    summarize(
      max = max(TIMESTAMP, na.rm = TRUE),
      formatted = ifelse(
        is.finite(max),
        format(max, "%Y-%m-%d"),
        "No data in past 100 days"
      ),
      color = ifelse(
        formatted == "No data in past 100 days" || now() - max > days(1),
        ' style="color: #990000;"',
        ""
      )
    )
}