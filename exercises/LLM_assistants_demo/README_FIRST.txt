AI ASSISTANTS (LLMs) FOR CODING AND REPORTING
RTC RER5030, Day 7
=============================================

WHAT IS IN THIS FOLDER
  data/john_alpha.csv          72 plots, 24 genotypes, 3 reps, alpha-lattice (the data of Day 2)
  prompts/                     the prompts we use in the demos (copy and paste them)
  prompt_template.md           a template for your own prompts
  checklist.md                 7 checks before you trust an answer
  buggy_code.R                 a script with 3 small errors, for the debugging demo
  00_install_packages.R        run once
  01_ellmer_local_model.R      talk to a local model from R
  02_connect_tools.R           check the API, connect btw and chattr
  cheatsheets/                 Ollama commands, local models in simple words, tonight's task
  LLM_assistants_demo.Rproj    double click to open in RStudio

STEP 1. FREE ASSISTANTS IN THE BROWSER (no installation)
  ChatGPT (chatgpt.com), Claude (claude.ai), Gemini (gemini.google.com),
  DeepSeek (chat.deepseek.com), Qwen (chat.qwen.ai).
  Free plans have limits that change often. Use any two of them.

STEP 2. A FREE MODEL ON YOUR OWN COMPUTER (Windows)
  1. Go to  ollama.com/download  and download the Windows installer. Install it.
  2. Open PowerShell (Start menu, type PowerShell).
  3. Download ONE model (it takes a few minutes):
        8 GB RAM     ollama pull gemma3:4b       (3.3 GB)
        6 GB RAM     ollama pull llama3.2:3b     (2.0 GB)
        4 GB RAM     ollama pull gemma3:1b       (0.8 GB)
  4. Test it:
        ollama run gemma3:4b
     Write "Hello" and press Enter. To leave, write  /bye
  5. Close the browser tabs you do not need. The model uses your RAM.

STEP 3. THE WINDOW OF OLLAMA (no terminal)
  Open the Ollama app from the Start menu. It has a chat window. It uses the same models.

STEP 4. USE IT FROM R
  Run 00_install_packages.R, then open 01_ellmer_local_model.R.
  Change the model name in the script if you downloaded a different one.

STEP 5. THE API (to connect other programs)
  The address is  http://localhost:11434  (no key, no account). Open it in the browser: "Ollama is running".
  For programs that ask for an OpenAI compatible URL use  http://localhost:11434/v1  and any text as key.
  02_connect_tools.R shows how to connect btw and chattr. In Positron: Accounts menu, Configure Language Model Providers, Ollama.

STEP 6. TONIGHT'S TASK
  Read cheatsheets/tonight_task.pdf. Two more cheat sheets are in the same folder:
  ollama_commands_cheatsheet.pdf and local_models_cheatsheet.pdf.

TALK TO YOUR COMPUTER
  In any text box (browser chat, RStudio, Word) press the Windows key + H and speak.
  Free option that works without internet: the program "Handy" (open source).
