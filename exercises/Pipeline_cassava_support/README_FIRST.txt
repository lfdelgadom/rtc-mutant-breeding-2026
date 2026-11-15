Data analysis pipeline in plant breeding, support folder (Day 6)
RTC RER5030, Skopje, November 2026. Luis Fernando Delgado Muñoz

1. Unzip this folder and double click Pipeline_cassava_support.Rproj
2. Open 00_install_packages.R and run it. Every package must print TRUE.
3. Open Pipeline_cassava_support.Rmd and press Knit, or run it chunk by chunk.

What is inside
- Pipeline_cassava_support.Rmd  the full pipeline on nine cassava trials, free packages only (SpATS and lme4)
- helpers.R                     the short functions used by the Rmd and by the slides
- data/cassava_DVGXE_tidy.csv   tidy data, 762 plots, 9 trials, 51 clones (public data, Cassava Base)
- reference/Cassava2050_original_analysis.qmd
                                the original analysis of the same trials (Cassava2050 repository)
- reference/Hussain_Analysis-pipeline/
                                code and demo data of Hussain et al. (2022), Plant Methods 18, 1,
                                doi:10.1186/s13007-022-00845-7. Original repository:
                                https://github.com/whussain2/Analysis-pipeline
                                Copied here for training, with credit to the authors.
