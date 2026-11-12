#!/usr/bin/env bash
# =====================================================================
# Publish the course website (book + slides) on GitHub Pages.
#
# Run it from the RStudio Terminal, inside the project folder:
#
#   bash publish.sh                      # only update the website
#   bash publish.sh "message"            # save and push your changes
#                                        # to GitHub, then update the website
#
# Add a new slide deck to the SLIDES list when it is ready.
# =====================================================================

set -e   # stop at the first error

# Slide decks to publish (file names in slides/, without .qmd)
SLIDES=(
  "01-r-basics"
  "02-tidy-data"
  "05-experimental-designs"
  "05b-analysing-designs"
  "06-anova"
  "09-spatial-analysis"
  "09b-image-analysis"
  "tutorial-artemis-photos"
  "tutorial-mrbean-spatial"
  "11-ai-plant-breeding"
)

# 0. Optional: save and push the source files to GitHub (branch main)
if [ -n "$1" ]; then
  echo ""
  echo "==> Saving your changes to GitHub: \"$1\""
  git add .
  if git diff --cached --quiet; then
    echo "    Nothing new to commit."
  else
    git commit -m "$1"
  fi
  git push
fi

# 0b. Build the exercise ZIP files (one per folder in exercises/) for the slides
echo ""
echo "==> Building exercise ZIP files (downloads/)"
mkdir -p downloads
for d in exercises/*/; do
  name=$(basename "$d")
  rm -f "downloads/${name}.zip"
  (cd exercises && zip -qr "../downloads/${name}.zip" "$name" -x "*/.Rhistory" "*/.DS_Store" "*/Exercise*.html" "*/my_field_book.csv" "*/alpha_field_book.csv")
  echo "    downloads/${name}.zip"
done

# 1. Render the slides
for deck in "${SLIDES[@]}"; do
  echo ""
  echo "==> Rendering slides: slides/${deck}.qmd"
  quarto render "slides/${deck}.qmd"
done

# 2. Render the book as a website (it copies the slides into _book/)
echo ""
echo "==> Rendering the book (HTML)"
quarto render --to html

# 3. Publish the website on GitHub Pages (branch gh-pages)
echo ""
echo "==> Publishing on GitHub Pages"
if git ls-remote --exit-code --heads origin gh-pages > /dev/null 2>&1; then
  quarto publish gh-pages --no-render --no-prompt
else
  # first time: Quarto creates the gh-pages branch and asks you to confirm (answer Y)
  quarto publish gh-pages --no-render
fi

echo ""
echo "Done. Website: https://lfdelgadom.github.io/rtc-mutant-breeding-2026/"
echo "(It can take 1 or 2 minutes to show the changes.)"
