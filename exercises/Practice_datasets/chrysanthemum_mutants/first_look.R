# A first look at the chrysanthemum data. Run it line by line and read the output.
# Needs the packages ggplot2 (install.packages("ggplot2") if you do not have it).
library(ggplot2)

d <- read.csv("chrysanthemum_mutant_trials.csv", stringsAsFactors = FALSE)
traits <- c("days_to_flowering", "plant_height_cm", "flower_diameter_cm", "flower_number", "stem_weight_g")
for (v in c("environment", "block", "genotype", "type", "parent", "flower_colour")) d[[v]] <- factor(d[[v]])

# 1. Size and structure
dim(d)
str(d)
table(d$environment, d$block)          # plots in each block of each environment
length(unique(d$genotype))             # 4 parents + 116 mutants

# 2. Missing values: how many, and where?
colSums(is.na(d[, traits]))
aggregate(d[, traits], list(environment = d$environment), function(x) sum(is.na(x)))

# 3. Distribution of each trait in each environment. Look for strange values.
long <- reshape(d[, c("environment", "plot", traits)], direction = "long",
                varying = traits, v.names = "value", timevar = "trait", times = traits, idvar = c("environment", "plot"))
ggplot(long, aes(environment, value)) + geom_boxplot() + facet_wrap(~trait, scales = "free_y") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

# 4. The field. Colour = value of one trait. Do you see a pattern by row or column?
ggplot(d[d$environment == "Field_autumn", ], aes(column, row, fill = plant_height_cm)) +
  geom_tile(colour = "white") + scale_y_reverse() + coord_equal() +
  facet_wrap(~environment) + scale_fill_viridis_c(na.value = "grey80")

# 5. Parents and mutants
ggplot(d, aes(type, plant_height_cm, fill = type)) + geom_boxplot() + facet_wrap(~environment)
table(d$flower_colour[!duplicated(d$genotype)], d$type[!duplicated(d$genotype)])
