# A first look at the wheat data. Run it line by line and read the output.
# Needs the package ggplot2 (install.packages("ggplot2") if you do not have it).
library(ggplot2)

# Open Practice_datasets.Rproj first. The working directory is then the folder Practice_datasets.
d <- read.csv("wheat_mutants/wheat_mutant_trials.csv", stringsAsFactors = FALSE)
traits <- c("days_to_heading", "plant_height_cm", "spikes_per_m2", "thousand_kernel_weight_g", "grain_yield_t_ha")
for (v in c("environment", "block", "genotype", "type", "parent", "awn_type")) d[[v]] <- factor(d[[v]])

# 1. Size and structure
dim(d)
str(d)
table(d$environment, d$block)               # plots in each block of each environment
length(unique(d$genotype))                  # 3 parents + 102 mutants
table(table(d$genotype, d$environment)[, 1]) # how many times is each line in one environment? (0, 1 or 2)

# 2. Missing values: how many, and where?
colSums(is.na(d[, c(traits, "lodging_score")]))
aggregate(d[, traits], list(environment = d$environment), function(x) sum(is.na(x)))

# 3. Distribution of each trait in each environment. Look for strange values.
long <- reshape(d[, c("environment", "plot", traits)], direction = "long",
                varying = traits, v.names = "value", timevar = "trait", times = traits, idvar = c("environment", "plot"))
ggplot(long, aes(environment, value)) + geom_boxplot() + facet_wrap(~trait, scales = "free_y") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# 4. The field. Colour = value of one trait. Do you see a pattern or a damaged corner?
ggplot(d, aes(column, row, fill = grain_yield_t_ha)) +
  geom_tile(colour = "white") + scale_y_reverse() + coord_equal() +
  facet_wrap(~environment) + scale_fill_viridis_c(na.value = "grey80")

# 5. Parents and mutants
ggplot(d, aes(type, plant_height_cm, fill = type)) + geom_boxplot() + facet_wrap(~environment)
table(d$awn_type[!duplicated(d$genotype)], d$type[!duplicated(d$genotype)])

# 6. Lodging is a score: look at it as counts, not as a mean
table(d$lodging_score, d$environment)
