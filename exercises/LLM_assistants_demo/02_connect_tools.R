# Connect your Ollama model to other tools. Nothing leaves your computer.
# Before: Ollama is open (the llama icon near the clock) and you have downloaded a model.

# 1. The API of Ollama. No key is needed.
#    Address: http://localhost:11434   (OpenAI compatible: http://localhost:11434/v1)
#    Open the address in the browser. You should read "Ollama is running".
ok <- tryCatch(readLines("http://localhost:11434", warn = FALSE), error = function(e) "NOT running. Open the Ollama app.")
ok

# 2. The models that you have (same as  ollama list  in PowerShell)
library(ellmer)
models_ollama()

# 3. btw. It gives the model the context of your R session (objects, help pages).
#    Needs a model that supports tools. Check with  ollama show model_name  in PowerShell.
# install.packages("btw")
options(btw.client = ellmer::chat_ollama(model = "qwen2.5-coder:3b"))   # change the name
btw::btw_app()                                                          # opens a chat app

# 4. chattr. A chat inside RStudio.
# install.packages("chattr")
chattr::chattr_use(ellmer::chat_ollama(model = "gemma3:4b"))            # change the name
chattr::chattr_app()

# 5. Positron. Accounts menu, "Configure Language Model Providers", choose Ollama, Connect.
#    Menu names change between versions.

# 6. The context window is a setting of Ollama, not of R.
#    If the model forgets the start of a long text: raise it in the Ollama settings, or in PowerShell
#       setx OLLAMA_CONTEXT_LENGTH 8192
#    and then close Ollama and open it again.
