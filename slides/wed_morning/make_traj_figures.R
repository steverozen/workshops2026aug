#!/usr/bin/env Rscript
#
# Schematics for the Wednesday-morning trajectory-inference slides.
#
# These are SCHEMATICS, not slingshot / monocle3 output. Neither package is
# installed here. Every step below is, however, the real algorithm in
# miniature, so the pictures are honest about how the two methods differ:
#
#   Slingshot  MST over cluster centroids, then a smooth curve per lineage.
#   Monocle 3  many small graph nodes over the embedding, MST over those,
#              pseudotime = geodesic distance from a root node.
#
# The Monocle 3 panel is close to SimplePPT, which alternates between
# assigning cells to centres and rebuilding an MST over the centres.
#
# Output: figures/*.png, sized for the 22pt Arial slide deck.

library(ggplot2)
library(igraph)

set.seed(20260805)

OUT_DIR <- file.path(dirname(sub("^--file=", "", grep("^--file=",
  commandArgs(trailingOnly = FALSE), value = TRUE)[1])), "figures")
dir.create(OUT_DIR, showWarnings = FALSE)

FONT <- "Arial"
CELL_GREY <- "grey72"

# ---------------------------------------------------------------- simulate
# A bifurcating trajectory: a shared trunk that splits into two branches.

bezier <- function(p0, p1, p2, t) {
  cbind(
    x = (1 - t)^2 * p0[1] + 2 * (1 - t) * t * p1[1] + t^2 * p2[1],
    y = (1 - t)^2 * p0[2] + 2 * (1 - t) * t * p1[2] + t^2 * p2[2]
  )
}

TRUNK <- list(p0 = c(0, 0),   p1 = c(2.0, -0.4), p2 = c(4, 0.6))
BR_A  <- list(p0 = c(4, 0.6), p1 = c(6.5, 1.4),  p2 = c(9, 4.0))
BR_B  <- list(p0 = c(4, 0.6), p1 = c(6.5, 0.4),  p2 = c(9, -3.0))

sample_seg <- function(seg, n, noise = 0.32) {
  t <- sort(runif(n))
  pts <- bezier(seg$p0, seg$p1, seg$p2, t)
  data.frame(
    x = pts[, "x"] + rnorm(n, 0, noise),
    y = pts[, "y"] + rnorm(n, 0, noise)
  )
}

cells <- rbind(
  sample_seg(TRUNK, 320),
  sample_seg(BR_A, 240),
  sample_seg(BR_B, 240)
)

# ------------------------------------------------- Slingshot stage 1: clusters
# Coarse clusters, the scale a biologist would actually annotate.

K_COARSE <- 8
km <- kmeans(cells[, c("x", "y")], centers = K_COARSE, nstart = 50)
cells$cluster <- factor(km$cluster)
centroids <- as.data.frame(km$centers)
centroids$cluster <- factor(seq_len(K_COARSE))

# MST over the centroids. This is the cluster-level tree.
mst_edges <- function(pts) {
  d <- as.matrix(dist(pts))
  g <- igraph::graph_from_adjacency_matrix(d, mode = "undirected",
                                           weighted = TRUE, diag = FALSE)
  t <- igraph::mst(g)
  el <- igraph::as_edgelist(t, names = FALSE)
  list(
    tree = t,
    seg = data.frame(
      x = pts[el[, 1], 1], y = pts[el[, 1], 2],
      xend = pts[el[, 2], 1], yend = pts[el[, 2], 2]
    )
  )
}

coarse <- mst_edges(as.matrix(centroids[, c("x", "y")]))
tree_seg <- coarse$seg

# ------------------------------------------ Slingshot stage 2: smooth curves
# Root at the centroid nearest the trunk start, leaves are the two tips.

root_c <- which.min(colSums((t(centroids[, c("x", "y")]) - c(0, 0))^2))
leaf_c <- which(igraph::degree(coarse$tree) == 1)
leaf_c <- setdiff(leaf_c, root_c)
# keep the two leaves furthest from the root, i.e. the two branch tips
far <- igraph::distances(coarse$tree, v = root_c, to = leaf_c)[1, ]
leaf_c <- leaf_c[order(far, decreasing = TRUE)][1:2]

# A lineage is the MST path from root to leaf. Slingshot initialises its
# principal curve from exactly this path, then iterates. Here we just smooth
# it, which is enough to make the point.
smooth_path <- function(pts, n_out = 200) {
  s <- c(0, cumsum(sqrt(rowSums(diff(as.matrix(pts))^2))))
  data.frame(
    x = stats::spline(s, pts[, 1], n = n_out)$y,
    y = stats::spline(s, pts[, 2], n = n_out)$y
  )
}

curves <- do.call(rbind, lapply(seq_along(leaf_c), function(i) {
  path <- igraph::shortest_paths(coarse$tree, from = root_c,
                                 to = leaf_c[i])$vpath[[1]]
  out <- smooth_path(centroids[as.integer(path), c("x", "y")])
  out$lineage <- paste("Lineage", i)
  out
}))

# ------------------------------------------------ Monocle 3 principal graph
# Many small nodes rather than a few biological clusters, then an MST.
#
# A plain MST over k-means centres leaves ragged zigzags and dead-end twigs.
# SimplePPT avoids that by alternating two steps until the graph settles:
# reassign cells to their nearest node, then move each node toward both the
# cells it owns and its neighbours in the graph. `lambda` is the pull toward
# the neighbours, i.e. how stiff the graph is.

refine_graph <- function(xy, nodes, n_iter = 20, lambda = 0.45) {
  for (i in seq_len(n_iter)) {
    d2 <- outer(xy[, 1], nodes[, 1], "-")^2 + outer(xy[, 2], nodes[, 2], "-")^2
    owner <- max.col(-d2, ties.method = "first")
    tree <- mst_edges(nodes)$tree
    nb <- igraph::adjacent_vertices(tree, seq_len(nrow(nodes)))
    for (k in seq_len(nrow(nodes))) {
      mine <- xy[owner == k, , drop = FALSE]
      data_pull <- if (nrow(mine) > 0) colMeans(mine) else nodes[k, ]
      neigh_pull <- colMeans(nodes[as.integer(nb[[k]]), , drop = FALSE])
      nodes[k, ] <- (1 - lambda) * data_pull + lambda * neigh_pull
    }
  }
  list(nodes = nodes, owner = max.col(
    -(outer(xy[, 1], nodes[, 1], "-")^2 + outer(xy[, 2], nodes[, 2], "-")^2),
    ties.method = "first"))
}

K_FINE <- 28
km_fine <- kmeans(cells[, c("x", "y")], centers = K_FINE, nstart = 50)
ref <- refine_graph(as.matrix(cells[, c("x", "y")]), km_fine$centers)
nodes <- as.data.frame(ref$nodes)
fine <- mst_edges(as.matrix(nodes))
graph_seg <- fine$seg

# Pseudotime: geodesic distance from the root node along the graph.
root_n <- which.min(colSums((t(as.matrix(nodes)) - c(0, 0))^2))
node_pt <- igraph::distances(fine$tree, v = root_n)[1, ]
nodes$pseudotime <- node_pt
cells$pseudotime <- node_pt[ref$owner]

# ------------------------------------------------------------------- theme
theme_schematic <- function() {
  theme_void(base_family = FONT, base_size = 15) +
    theme(
      plot.title = element_text(size = 16, hjust = 0, margin = margin(b = 6)),
      strip.text = element_text(size = 16, margin = margin(b = 8)),
      legend.title = element_text(size = 13),
      legend.text = element_text(size = 12),
      plot.margin = margin(10, 14, 10, 14)
    )
}

save_fig <- function(plot, file, width, height) {
  path <- file.path(OUT_DIR, file)
  ggsave(path, plot, width = width, height = height, dpi = 200,
         units = "in", bg = "white")
  cat("wrote", path, "\n")
  invisible(path)
}

# --------------------------------------------- Fig 1: the cluster-level tree
# facet_wrap orders panels alphabetically, so the levels are set explicitly to
# keep the two steps in the order they happen.
TREE_PANELS <- c("1. Cluster the cells",
                 "2. MST on the cluster centroids")
as_panel <- function(df, which) {
  transform(df, panel = factor(TREE_PANELS[which], levels = TREE_PANELS))
}

fig_tree <- ggplot() +
  geom_point(data = as_panel(cells, 1), aes(x, y, colour = cluster),
             size = 1.1, alpha = 0.85) +
  geom_point(data = as_panel(cells, 2), aes(x, y), colour = CELL_GREY,
             size = 1.1, alpha = 0.5) +
  geom_segment(data = as_panel(tree_seg, 2),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.9, colour = "black") +
  geom_point(data = as_panel(centroids, 2),
             aes(x, y), size = 4.2, colour = "black") +
  facet_wrap(~panel) +
  scale_colour_brewer(palette = "Set2") +
  coord_equal() +
  guides(colour = "none") +
  theme_schematic()

save_fig(fig_tree, "fig_cluster_tree.png", 10.4, 4.3)

# ------------------------------------------- Fig 2: Slingshot principal curves
# The two curves nearly coincide along the trunk, which is the whole point, so
# they are drawn in two colours at different widths to keep both visible there.
LIN_COLS <- c("Lineage 1" = "#1B6CA8", "Lineage 2" = "#D1660F")

fig_sling <- ggplot() +
  geom_point(data = cells, aes(x, y), colour = CELL_GREY, size = 1.1,
             alpha = 0.6) +
  geom_path(data = subset(curves, lineage == "Lineage 1"),
            aes(x, y, colour = lineage), linewidth = 2.6, lineend = "round") +
  geom_path(data = subset(curves, lineage == "Lineage 2"),
            aes(x, y, colour = lineage), linewidth = 1.2, lineend = "round") +
  scale_colour_manual(values = LIN_COLS) +
  coord_equal() +
  labs(colour = NULL) +
  theme_schematic() +
  theme(legend.position = "inside",
        legend.position.inside = c(0.13, 0.9),
        legend.key.width = unit(30, "pt"))

save_fig(fig_sling, "fig_slingshot_curves.png", 7.6, 4.3)

# --------------------------------------- Fig 3: Monocle 3 principal graph
# Thin spokes from a sample of cells to the vertex they were assigned to, so
# that "each cell projects to its nearest principal point" is visible rather
# than merely asserted.
proj <- data.frame(
  x = cells$x, y = cells$y,
  xend = nodes$x[ref$owner], yend = nodes$y[ref$owner]
)
proj <- proj[sample(nrow(proj), 220), ]

fig_mono <- ggplot() +
  geom_segment(data = proj, aes(x = x, y = y, xend = xend, yend = yend),
               colour = "grey55", linewidth = 0.22, alpha = 0.75) +
  geom_point(data = cells, aes(x, y, colour = pseudotime), size = 1.1,
             alpha = 0.85) +
  geom_segment(data = graph_seg, aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.8, colour = "black") +
  geom_point(data = nodes, aes(x, y), size = 1.9, colour = "black") +
  annotate("point", x = nodes$x[root_n], y = nodes$y[root_n],
           size = 5.5, shape = 21, fill = "white", colour = "black",
           stroke = 1.3) +
  annotate("text", x = nodes$x[root_n] - 0.35, y = nodes$y[root_n] - 1.15,
           label = "root", family = FONT, size = 4.6) +
  scale_colour_viridis_c(option = "viridis") +
  coord_equal() +
  labs(colour = "pseudotime") +
  theme_schematic() +
  theme(legend.position = "right")

save_fig(fig_mono, "fig_monocle_graph.png", 8.6, 4.3)

# ---------------------------------- Fig 5: what the black dots actually are
# The two methods draw dots-joined-by-lines that mean entirely different
# things, which is the single easiest thing to get wrong when reading these
# figures. Slingshot's dots are biological objects, Monocle 3's are not.
# Strip labels have to stay short or facet_wrap clips them. The full
# explanation goes in the slide caption instead.
VERT_PANELS <- c("Slingshot: cluster centroids",
                 "Monocle 3: learned points")
as_vpanel <- function(df, which) {
  transform(df, panel = factor(VERT_PANELS[which], levels = VERT_PANELS))
}

centroid_lab <- centroids
centroid_lab$label <- paste0("cluster ", seq_len(K_COARSE))

node_lab <- nodes
node_lab$label <- paste0("Y", seq_len(K_FINE))
# labelling all 28 is unreadable, so label a few along the backbone
node_lab <- node_lab[order(node_lab$pseudotime), ][c(1, 8, 15, 22, 28), ]

fig_vertices <- ggplot() +
  geom_point(data = as_vpanel(cells, 1), aes(x, y, colour = cluster),
             size = 0.9, alpha = 0.55) +
  geom_segment(data = as_vpanel(tree_seg, 1),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.8, colour = "black") +
  geom_point(data = as_vpanel(centroids, 1), aes(x, y), size = 4.2,
             colour = "black") +
  geom_text(data = as_vpanel(centroid_lab, 1), aes(x, y, label = label),
            family = FONT, size = 3.5, vjust = -1.3) +
  geom_point(data = as_vpanel(cells, 2), aes(x, y), colour = CELL_GREY,
             size = 0.9, alpha = 0.5) +
  geom_segment(data = as_vpanel(graph_seg, 2),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.7, colour = "black") +
  geom_point(data = as_vpanel(nodes, 2), aes(x, y), size = 1.8,
             colour = "black") +
  geom_text(data = as_vpanel(node_lab, 2), aes(x, y, label = label),
            family = FONT, size = 3.5, vjust = -1.4) +
  facet_wrap(~panel) +
  scale_colour_brewer(palette = "Set2") +
  coord_equal() +
  guides(colour = "none") +
  theme_schematic()

save_fig(fig_vertices, "fig_vertices.png", 10.4, 4.3)

# ------------------------------------------------ Fig 4: the two side by side
contrast_cells <- rbind(
  transform(cells, panel = "Slingshot: smooth curves, one per lineage"),
  transform(cells, panel = "Monocle 3: piecewise-linear principal graph")
)
contrast_cells$panel <- factor(contrast_cells$panel,
  levels = c("Slingshot: smooth curves, one per lineage",
             "Monocle 3: piecewise-linear principal graph"))
p_lab <- levels(contrast_cells$panel)

fig_contrast <- ggplot() +
  geom_point(data = contrast_cells, aes(x, y), colour = CELL_GREY,
             size = 0.9, alpha = 0.55) +
  geom_path(data = transform(curves, panel = factor(p_lab[1], levels = p_lab)),
            aes(x, y, group = lineage), linewidth = 1.4, colour = "black",
            lineend = "round") +
  geom_segment(data = transform(graph_seg,
                                panel = factor(p_lab[2], levels = p_lab)),
               aes(x = x, y = y, xend = xend, yend = yend),
               linewidth = 0.7, colour = "black") +
  geom_point(data = transform(nodes, panel = factor(p_lab[2], levels = p_lab)),
             aes(x, y), size = 1.6, colour = "black") +
  facet_wrap(~panel) +
  coord_equal() +
  theme_schematic()

save_fig(fig_contrast, "fig_contrast.png", 10.4, 4.3)
