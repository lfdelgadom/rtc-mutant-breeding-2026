RER5030 training course - Day 4, afternoon: image analysis in R with pliman

1. Unzip this folder on your computer (do not work inside the ZIP file).
2. Open Day4_afternoon.Rproj in RStudio (double click).
3. Run 00_install_packages.R once. All lines should show TRUE.
   If library(pliman) says "Package EBImage is required", the Bioconductor step did not finish: run the script again.

All the images are the sample images installed with pliman: no download is needed, and everything works offline.

Practical of this session (15:00 - 16:30), in this order:
  Image1_count_and_measure.Rmd         counting seeds, size and scale (dpi and reference object)  (30 min)
  Image2_colour_leaves_severity.Rmd    colour, leaves, senescence score, disease severity          (30 min)
  Image3_folder_to_field_book.Rmd      a folder of images, the field book, validation, the model   (30 min)
  Image4_download_Artemis_photos_optional.Rmd   optional: download real field photos (needs internet)

How to work: run each grey box with the green triangle, from top to bottom.
Replace the ___ in the lines marked # TODO. The # HINT line above tells you where to look.
Every part says what result you should get, so you can check yourself.
Write your findings in the boxes. Knit only at the end, if time allows.
Work with your neighbour: one types, the other checks the labelled image. Swap every part.

Files:
  data/Example_Beans.csv     the bean trial of Day 3 (used in Image3 to show how an image trait enters the model)
  data/field_book_demo.csv   a tiny field book of 3 plots (Image3)
  my_images/                 optional: your own phone photos

Keep everything in this folder. It is your own copy: updating the course project with Git never touches it.
Posit Cloud users: upload this ZIP to your project (Files > Upload), then open the .Rmd files.
