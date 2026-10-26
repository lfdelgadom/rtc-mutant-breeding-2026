# Common ggplot2 theme so book and slides look the same
theme_course <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   plot.title.position = "plot")
}
