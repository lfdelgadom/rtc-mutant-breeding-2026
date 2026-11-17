# Talk to a model that runs on YOUR computer. Nothing leaves your machine.
# Before: Ollama is installed and you ran  ollama pull gemma3:4b  in PowerShell.

library(ellmer)

# 0. Is Ollama running? Which models do I have? (the same list as  ollama list)
models_ollama()

# 1. Connect. Change the name if you downloaded another model.
chat <- chat_ollama(
  model = "gemma3:4b",
  system_prompt = "You are a statistics assistant for plant breeders. Answer in simple English. Give R code, not results."
)

# 2. A first question
chat$chat("What is an alpha-lattice design? Explain in 3 sentences.")

# 3. Ask for code. The data stay in R, only the description goes to the model.
chat$chat("
I have a field trial. Design: alpha-lattice with 3 replicates, 6 incomplete blocks per replicate, 24 genotypes.
Data frame 'd' with columns: rep, block, gen, yield (t/ha). Block names B1 to B6 are repeated in every replicate.
Objective: mean yield of each genotype adjusted for the design.
Write R code with lme4. Give only code and one line of explanation.")

# 4. Run the code that the model wrote. ALWAYS check it (see checklist.md).
d <- read.csv("data/john_alpha.csv")
d$rep <- factor(d$rep); d$block <- factor(d$block); d$gen <- factor(d$gen)
# paste the code of the model here and run it

# 5. A chat window in the Viewer (optional)
# live_browser(chat)
