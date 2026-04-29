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
    coord_cartesian(
      xlim = c(
        lubridate::ymd(start, tz = "EST"),
        lubridate::ymd(end + 1, tz = "EST")
      )
    ) +
    theme(axis.title.x = element_blank(), legend.position = "none",
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    ggtitle(site)
  
  plotly::ggplotly(p, tooltip = c("TIMESTAMP", "value"))
}

latest_times <- function(df) {
  filt <- df %>%
    group_by(Site) %>%
    filter(if_any(-TIMESTAMP, ~!is.na(.))) 
  
  if(!"FLUME" %in% filt$Site){
    filt <- bind_rows(filt, data.frame(Site = "FLUME"))
  }
  
  if(!"DOCK" %in% filt$Site){
    filt <- bind_rows(filt, data.frame(Site = "DOCK"))
  }
  
  out <- filt %>%
    summarize(
      max = max(TIMESTAMP, na.rm = TRUE),
      formatted = ifelse(
        is.finite(max),
        paste0(format(max, "%Y-%m-%d %H:%M"), " EST"),
        "No data in past 100 days"
      ),
      color = ifelse(
        formatted == "No data in past 100 days" || now() - max > days(1),
        ' style="color: #990000;"',
        ""
      )
    )
  
  return(out)
}
