# A first look at the bean data. Run it line by line and read the output.
# Needs the package ggplot2 (install.packages("ggplot2") if you do not have it).
library(ggplot2)

# Open Practice_datasets.Rproj first. The working directory is then the folder Practice_datasets.
d <- read.csv("bean_mutants/bean_mutant_trials.csv", stringsAsFactors = FALSE)
traits <- c("days_to_flowering", "days_to_maturity", "pods_per_plant", "hundred_seed_weight_g", "seed_yield_kg_ha")
for (v in c("environment", "block", "genotype", "type", "parent", "seed_coat_colour")) d[[v]] <- factor(d[[v]])

# 1. Size and structure
dim(d)
str(d)
table(d$environment, d$block)          # plots in each block of each environment
length(unique(d$genotype))             # 3 parents + 81 mutants

# 2. Missing values and zeros: how many, and where?
colSums(is.na(d[, traits]))
colSums(d[, traits] == 0, na.rm = TRUE)     # zeros are NOT missing values. Where are they?
d[which(d$seed_yield_kg_ha == 0), c("environment", "plot", "genotype", "pods_per_plant", "seed_yield_kg_ha")]

# 3. Distribution of each trait in each environment. Look for strange values.
long <- reshape(d[, c("environment", "plot", traits)], direction = "long",
                varying = traits, v.names = "value", timevar = "trait", times = traits, idvar = c("environment", "plot"))
ggplot(long, aes(environment, value)) + geom_boxplot() + facet_wrap(~trait, scales = "free_y") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# 4. The field. Colour = value of one trait. Do you see a pattern or a damaged corner?
ggplot(d, aes(column, row, fill = seed_yield_kg_ha)) +
  geom_tile(colour = "white") + scale_y_reverse() + coord_equal() +
  facet_wrap(~environment, ncol = 1) + scale_fill_viridis_c(na.value = "grey80")

# 5. Parents and mutants
ggplot(d, aes(type, seed_yield_kg_ha, fill = type)) + geom_boxplot() + facet_wrap(~environment)
table(d$seed_coat_colour[!duplicated(d$genotype)], d$type[!duplicated(d$genotype)])
