library( rmarkdown )
library( ggplot2 )

stitchedFile <- "stitched.Rmd";

formatFile <- "format.Rmd"

rmdFiles <- c( formatFile,
   "titlePage.Rmd",
  #               "notes.Rmd",
   "abstract.Rmd",
   "intro.Rmd",
   "imagingMethods.Rmd",
   "processingMethods.Rmd",
   "statisticalMethods2.Rmd",
   "results.Rmd",
   "discussion.Rmd",
   "appendix.Rmd",
   "acknowledgments.Rmd"
   )

for( i in 1:length( rmdFiles ) )
  {
  if( i == 1 )
    {
    cmd <- paste( "cat", rmdFiles[i], ">", stitchedFile )
    } else {
    cmd <- paste( "cat", rmdFiles[i], ">>", stitchedFile )
    }
  system( cmd )
  }

cat( '\n Pandoc rendering', stitchedFile, '\n' )
render( stitchedFile, output_format = c( "pdf_document", "word_document" ) )



stitchedFile <- "stitched2.Rmd";

formatFile <- "format.Rmd"

rmdFiles <- c( formatFile,
               "floats.Rmd"
             )

for( i in 1:length( rmdFiles ) )
  {
  if( i == 1 )
    {
    cmd <- paste( "cat", rmdFiles[i], ">", stitchedFile )
    } else {
    cmd <- paste( "cat", rmdFiles[i], ">>", stitchedFile )
    }
  system( cmd )
  }

cat( '\n Pandoc rendering', stitchedFile, '\n' )
render( stitchedFile, output_format = c( "pdf_document", "html_document", "word_document" ) )

