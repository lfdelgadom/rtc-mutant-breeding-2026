# Course manual – RTC Experimental Design and Data Analysis for Mutant Populations

Quarto book and slides for the IAEA Regional Training Course (RER5030), Skopje, 9–20 November 2026.

## Structure

- `_quarto.yml` – book configuration
- `part0-precourse/`, `part1-week1/`, `part2-week2/` – chapters (one per session block)
- `slides/` – revealjs slides (condensed versions of the chapters)
- `data/` – shared datasets
- `R/` – install script, dataset checker, common plot theme
- `templates/` – chapter template for co-authors, report template for participants

## Chapter owners

| Chapter | Author |
|---|---|
| 01 R basics, 05 designs, 06 ANOVA, 09 spatial, 09b image analysis, 10 MET/G×E (book only, taught by Mirjana), 11 machine learning, 12 pipeline, 14 LLMs | Luis Fernando Delgado Muñoz |
| 02 tidy data | Mirjana Jankulovska and Luis Fernando Delgado Muñoz |
| 03 field data, 04 QC/EDA, 07 mixed models, 08 heritability | Mirjana Jankulovska |
| 13 mutant populations (Topic 10: radiosensitivity and M2 to M5 pipeline by Luis Fernando, 1-hour lecture by Mirjana), 15 selection in mutation breeding (Topic 11) | Luis Fernando Delgado Muñoz (Anand Badigannavar will not attend) |
| 16 participant projects | all experts |

## Build

```bash
quarto preview            # live preview of the book
quarto render             # full book (HTML + PDF)
quarto render slides/05-experimental-designs.qmd
quarto publish gh-pages   # publish on GitHub Pages
```

Code chunks are set to `eval: false` until the shared datasets are in `data/`. Remove that line chunk by chunk as each demo becomes runnable.
