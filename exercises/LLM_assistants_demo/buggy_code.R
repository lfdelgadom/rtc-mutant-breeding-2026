# Debugging demo. This script has 3 small errors. Run it line by line.
# Copy the red error message to the assistant, with the line that failed.

d <- read.csv("data/john_alpha.csv")
d$rep <- factor(d$rep); d$block <- factor(d$block); d$gen <- factor(d$gen)

# Error 1
m <- lmer(yield ~ rep + gen + (1 | rep:block), data = d)

# Error 2
boxplot(yeild ~ gen, data = d, las = 2)

# Error 3
means <- emmeans(m, "gen")
head(as.data.frame(means))
