# Schematic layouts: one small example per design, drawn by one function
set.seed(2026)
dark <- "#1F3A5F"; mid <- "#F28E2B"; light <- "#E8EDF2"
pal6 <- c("#4E79A7", "#F28E2B", "#59A14F", "#B07AA1", "#76B7B2", "#EDC948")

draw_layout <- function(d, title, blocks = NULL, reps = NULL, hi = NULL,
                        fill = "fill", label = "label", ncol_, nrow_) {
  if (is.null(d$tcol)) d$tcol <- "black"
  p <- ggplot(d, aes(col, row)) +
    geom_tile(aes(fill = .data[[fill]]), colour = "white", linewidth = 1.2) +
    geom_text(aes(label = .data[[label]], colour = tcol), size = 4.2) +
    scale_fill_identity() + scale_colour_identity() +
    scale_y_reverse() + coord_equal(clip = "off") + theme_void(base_size = 14) +
    labs(title = title) +
    theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5, colour = dark),
          plot.margin = margin(4, 8, 4, 8))
  rect <- function(r, lw, colr) geom_rect(data = r, aes(xmin = xmin - .5, xmax = xmax + .5,
                                           ymin = ymin - .5, ymax = ymax + .5),
                                   inherit.aes = FALSE, fill = NA, colour = colr, linewidth = lw)
  if (!is.null(blocks)) p <- p + rect(blocks, 1.1, dark)
  if (!is.null(reps))   p <- p + rect(reps, 1.7, "black")
  if (!is.null(hi))     p <- p + rect(hi, 1.8, mid)
  p
}
R <- function(...) data.frame(xmin = ..1, xmax = ..2, ymin = ..3, ymax = ..4)

# 1. CRD: 6 genotypes x 3 reps placed completely at random
g <- expand.grid(row = 1:3, col = 1:6); g$e <- sample(rep(1:6, 3))
g$fill <- pal6[g$e]; g$label <- LETTERS[g$e]
p_crd <- draw_layout(g, "CRD")

# 2. RCBD: every block (a row) has every genotype once
g <- expand.grid(row = 1:3, col = 1:6)
g$e <- NA; for (b in 1:3) g$e[g$row == b] <- sample(1:6)
g$fill <- pal6[g$e]; g$label <- LETTERS[g$e]
p_rcbd <- draw_layout(g, "RCBD", blocks = do.call(rbind, lapply(1:3, function(b) R(1, 6, b, b))))

# 3. Augmented: checks A and B in every block, new lines once
g <- expand.grid(row = 1:3, col = 1:8); g$lab <- NA
for (b in 1:3) g$lab[g$row == b] <- sample(c("A", "B", paste0("n", (b - 1) * 6 + 1:6)))
g$fill <- ifelse(g$lab == "A", dark, ifelse(g$lab == "B", mid, light))
g$label <- g$lab; g$tcol <- ifelse(g$lab == "A", "white", "black")
p_aug <- draw_layout(g, "Augmented", blocks = do.call(rbind, lapply(1:3, function(b) R(1, 8, b, b))))

# 4. Alpha-lattice: 2 replicates, each with 3 incomplete blocks of 4 plots
g <- do.call(rbind, lapply(1:2, function(r) {
  e <- sample(1:12); x <- expand.grid(row = 1:4, k = 1:3)
  data.frame(row = x$row, col = x$k + (r - 1) * 4, e = e, blk = x$k, rep = r)
}))
g$fill <- ifelse(g$blk %% 2 == 1, "#DCE6F0", "#F4F7FA"); g$label <- g$e
bl <- do.call(rbind, lapply(1:2, function(r) do.call(rbind, lapply(1:3, function(k)
  R(k + (r - 1) * 4, k + (r - 1) * 4, 1, 4)))))
rp <- rbind(R(1, 3, 1, 4), R(5, 7, 1, 4))
p_alpha <- draw_layout(g, "Alpha-lattice", blocks = bl, reps = rp)

# 5. Row-column (not resolvable): 12 entries twice in 4 rows x 6 columns
repeat {
  e <- sample(rep(1:12, 2)); m <- matrix(e, 4, 6)
  ok <- all(apply(m, 1, function(v) !anyDuplicated(v))) && all(apply(m, 2, function(v) !anyDuplicated(v)))
  if (ok) break
}
g <- expand.grid(row = 1:4, col = 1:6); g$e <- as.vector(m)
g$fill <- light; g$label <- g$e
p_rowcol <- draw_layout(g, "Row-column", hi = rbind(R(1, 6, 2, 2), R(4, 4, 1, 4)))

# 6. Resolvable row-column: each replicate is a 4 x 3 block with all 12 entries once
g <- do.call(rbind, lapply(1:2, function(r) {
  x <- expand.grid(row = 1:4, k = 1:3)
  data.frame(row = x$row, col = x$k + (r - 1) * 4, e = sample(1:12))
}))
g$fill <- light; g$label <- g$e
p_rrc <- draw_layout(g, "Resolvable row-col.", reps = rbind(R(1, 3, 1, 4), R(5, 7, 1, 4)),
                     hi = rbind(R(1, 3, 2, 2), R(2, 2, 1, 4)))

# 7. p-rep: 4 lines in 2 plots (dark), 16 lines in 1 plot (light)
g <- expand.grid(row = 1:4, col = 1:6)
lab <- sample(c(rep(paste0("R", 1:4), 2), paste0("s", 1:16)))
g$fill <- ifelse(substr(lab, 1, 1) == "R", dark, light)
g$label <- ifelse(substr(lab, 1, 1) == "R", lab, "")
g$tcol <- ifelse(substr(lab, 1, 1) == "R", "white", "black")
p_prep <- draw_layout(g, "p-rep")

# 8. The real john.alpha layout (24 oat varieties, 3 replicates of 6 blocks of 4 plots)
#    annotated with t, k, s and r
local({
  d <- agridat::john.alpha
  d$b <- as.integer(sub("B", "", d$block)); d$r <- as.integer(sub("R", "", d$rep))
  d$pos <- ave(d$row, d$rep, d$block, FUN = function(v) rank(v))
  g <- data.frame(row = d$pos + 1.2, col = d$b + (d$r - 1) * 7,
                  label = as.integer(sub("G", "", d$gen)), fill = ifelse(d$b %% 2 == 1, "#DCE6F0", "#F4F7FA"),
                  tcol = "black")
  bl <- unique(data.frame(xmin = g$col, xmax = g$col, ymin = 2.2, ymax = 5.2))
  rp <- data.frame(xmin = c(1, 8, 15), xmax = c(6, 13, 20), ymin = 2.2, ymax = 5.2)
  p <- draw_layout(g, "", blocks = bl, reps = rp) +
    annotate("text", x = c(3.5, 10.5, 17.5), y = 0.5, label = paste("Replicate", 1:3),
             fontface = "bold", colour = "black", size = 4.2) +
    annotate("segment", x = 0.5, xend = 6.5, y = 1.3, yend = 1.3, colour = mid, linewidth = 1) +
    annotate("text", x = 3.5, y = 1.0, label = "s = 6 blocks per replicate", colour = mid, size = 4) +
    annotate("segment", x = 0.0, xend = 0.0, y = 1.75, yend = 5.65, colour = mid, linewidth = 1) +
    annotate("text", x = -0.4, y = 3.7, label = "k = 4 plots", colour = mid, size = 4, angle = 90) +
    theme(plot.title = element_blank())
  p_john <<- p + labs(caption = "t = 24 entries, r = 3 replicates, 72 plots in total")  +
    theme(plot.caption = element_text(size = 12, hjust = 0.5, colour = dark))
})
