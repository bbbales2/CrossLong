library( ggplot2 )
library( dplyr )
library( lme4 )
library( nlme )
library( lmerTest )
library( knitr )
library( kableExtra )
library( ADNIMERGE )

# baseDirectory <- '/Users/ntustison/Data/Public/CrossLong/'
baseDirectory <- '/Users/ntustison/Documents/Academic/InProgress/CrossLong/'
dataDirectory <- paste0( baseDirectory, 'Data/' )
manuscriptDirectory <- paste0( baseDirectory, 'Manuscript/' )
plotDir <- paste0( dataDirectory, "RegionalThicknessSlopeDistributions/" )

corticalThicknessPipelineNames <- c(  'FSCross', 'FSLong', 'ANTsCross', 'ANTsNative', 'ANTsSST' )
numberOfRegions <- 62

diagnosticLevels <- c( "CN", "LMCI", "AD" )
visits <- c( 0, 6, 12, 18, 24, 36 )
visitsCode <- c( "bl", "m06", "m12", "m18", "m24", "m36" )

doTemporalSmoothing <- FALSE

dktRegions <- read.csv( paste0( dataDirectory, 'dkt.csv' ) )
dktBrainGraphRegions <- dktRegions$brainGraph[( nrow( dktRegions ) - numberOfRegions + 1 ):nrow( dktRegions )]
dktBrainGraphRegions <- gsub( " ", "", dktBrainGraphRegions ) 

corticalThicknessData <- list()
demographicsData <- data.frame()
for( i in 1:length( corticalThicknessPipelineNames ) )
  {
  corticalThicknessCsv <- paste0( dataDirectory, 'reconciled_', corticalThicknessPipelineNames[i], '.csv' )
  cat( "Reading ", corticalThicknessCsv, "\n" )
  corticalThicknessData[[i]] <- read.csv( corticalThicknessCsv )

  if( i == 1 )
    {
    naColumn <- rep( NA, nrow( corticalThicknessData[[i]] ) )
    visitCode <- naColumn
    for( j in 1:length( visits ) )
      {
      visitCode[which( corticalThicknessData[[i]]$VISIT == visits[j] )] <- visitsCode[j]
      }
    demographicsData <- data.frame( corticalThicknessData[[i]][, 1:8],
                                    VISCODE = visitCode,
                                    AGE.bl = naColumn,
                                    GENDER = naColumn,
                                    ICV.bl = naColumn,
                                    DX.bl = naColumn,
                                    SITE = naColumn,
                                    APOE4.bl = naColumn,
                                    ABETA.bl = naColumn,
                                    TAU.bl = naColumn,
                                    AV45.bl = naColumn,
                                    CDRSB = naColumn,
                                    CDRSB.bl = naColumn,
                                    LDELTOTAL = naColumn,
                                    LDELTOTAL.bl = naColumn,
                                    RAVLT.immediate = naColumn,
                                    RAVLT.immediate.bl = naColumn,
                                    MMSE = naColumn,
                                    MMSE.bl = naColumn,
                                    FAQ = naColumn,
                                    FAQ.bl = naColumn,
                                    mPACCdigit = naColumn,
                                    mPACCdigit.bl = naColumn,
                                    mPACCtrailsB = naColumn,
                                    mPACCtrailsB.bl = naColumn
                                  )
 
    for( j in seq_len( nrow( demographicsData ) ) )
      {
      subjectAdniMergeIndices.bl <- 
        which( adnimerge$PTID == demographicsData$ID[j] & 
          adnimerge$VISCODE == 'bl' )      
      subjectAdniMergeIndices <- 
        which( adnimerge$PTID == demographicsData$ID[j] & 
          adnimerge$VISCODE == demographicsData$VISCODE[j] )      

      demographicsData$AGE.bl[j] <- adnimerge$AGE[subjectAdniMergeIndices.bl]
      demographicsData$GENDER[j] <- adnimerge$PTGENDER[subjectAdniMergeIndices.bl]
      demographicsData$ICV.bl[j] <- adnimerge$ICV.bl[subjectAdniMergeIndices.bl]
      demographicsData$DX.bl[j] <- levels( adnimerge$DX.bl )[adnimerge$DX.bl[subjectAdniMergeIndices.bl]]
      demographicsData$SITE[j] <- adnimerge$SITE[subjectAdniMergeIndices]

      demographicsData$APOE4.bl[j] <- adnimerge$APOE4[subjectAdniMergeIndices.bl]
      demographicsData$ABETA.bl[j] <- adnimerge$ABETA.bl[subjectAdniMergeIndices.bl]
      demographicsData$TAU.bl[j] <- adnimerge$TAU.bl[subjectAdniMergeIndices.bl]
      demographicsData$AV45.bl[j] <- adnimerge$AV45.bl[subjectAdniMergeIndices.bl]
      demographicsData$CDRSB[j] <- adnimerge$CDRSB[subjectAdniMergeIndices]
      demographicsData$CDRSB.bl[j] <- adnimerge$CDRSB.bl[subjectAdniMergeIndices.bl]
      demographicsData$LDELTOTAL[j] <- adnimerge$LDELTOTAL[subjectAdniMergeIndices]
      demographicsData$LDELTOTAL.bl[j] <- adnimerge$LDELTOTAL.bl[subjectAdniMergeIndices.bl]
      demographicsData$RAVLT.immediate[j] <- adnimerge$RAVLT.immediate[subjectAdniMergeIndices]
      demographicsData$RAVLT.immediate.bl[j] <- adnimerge$RAVLT.immediate.bl[subjectAdniMergeIndices.bl]
      demographicsData$MMSE[j] <- adnimerge$MMSE[subjectAdniMergeIndices]
      demographicsData$MMSE.bl[j] <- adnimerge$MMSE.bl[subjectAdniMergeIndices.bl]
      demographicsData$FAQ[j] <- adnimerge$FAQ[subjectAdniMergeIndices]
      demographicsData$FAQ.bl[j] <- adnimerge$FAQ.bl[subjectAdniMergeIndices.bl]
      demographicsData$mPACCdigit[j] <- adnimerge$mPACCdigit[subjectAdniMergeIndices]
      demographicsData$mPACCdigit.bl[j] <- adnimerge$mPACCdigit.bl[subjectAdniMergeIndices.bl]
      demographicsData$mPACCtrailsB[j] <- adnimerge$mPACCtrailsB[subjectAdniMergeIndices]
      demographicsData$mPACCtrailsB.bl[j] <- adnimerge$mPACCtrailsB.bl[subjectAdniMergeIndices.bl]
      }
    demographicsData$dTIME  <- demographicsData$AGE - demographicsData$AGE.bl

    demographicsData$ID <- factor( demographicsData$ID )
    demographicsData$SITE <- factor( demographicsData$SITE )
    demographicsData$GENDER <- factor( demographicsData$GENDER )
    demographicsData$DX.bl <- factor( demographicsData$DX.bl, levels = c( "CN", "LMCI", "AD" ) )
    demographicsData$APOE4.bl <- factor( demographicsData$APOE4.bl )
    }
  }  

thicknessColumns <- 9:ncol( corticalThicknessData[[1]] )
thicknessNames <- colnames( corticalThicknessData[[1]] )[thicknessColumns]

# Smooth the data (if requested).  Also, add the baseline thickness measurements and
# delta thickness measurements to the corticalThicknessData data frames

for( p in seq_len( length( corticalThicknessPipelineNames ) ) )
  {
  if( doTemporalSmoothing )
    {
    numberOfSmoothingIterations <- 1
    smoothingSigma <- 5.5

    subjects <- unique( demographicsData$ID )

    for( i in seq_len( numberOfSmoothingIterations ) )
      {
      for( s in seq_len( length( subjects ) ) )
        {
        subjectIndices <- which( demographicsData$ID == subjects[s] )  

        if( length( subjectIndices ) > 1 )
          {
          subjectMatrix <- data.matrix( corticalThicknessData[[p]][subjectIndices, thicknessColumns] )
          subjectTime <- matrix( demographicsData$dTIME[subjectIndices], ncol = 1 )
          timeDistance <- as.matrix( 
            dist( subjectTime, method = "euclidean", diag = TRUE, upper = TRUE, p = 2 ) )
          gaussianDistance <- 
            as.matrix( exp( -1.0 * timeDistance / ( smoothingSigma * sd( subjectMatrix ) ) ) )
          gaussianDistance <- gaussianDistance / colSums( gaussianDistance )  
          smoothedThickness <- gaussianDistance %*% subjectMatrix
          corticalThicknessData[[p]][subjectIndices, thicknessColumns] <- smoothedThickness
          }
        }
      }
    }

  baselineThickness <- 0 * corticalThicknessData[[p]][,thicknessColumns]
  colnames( baselineThickness ) <- paste0( thicknessNames, ".bl" )
  for( i in seq_len( nrow( corticalThicknessData[[p]] ) ) )
    {
    subjectIndices <- which( corticalThicknessData[[p]]$ID == corticalThicknessData[[p]]$ID[i] )  
    subjectIndices.bl <- which( corticalThicknessData[[p]]$ID == corticalThicknessData[[p]]$ID[i] &
      corticalThicknessData[[p]]$VISIT == 0 )  

    if( length( subjectIndices.bl ) == 1 )
      {
      baselineThickness[subjectIndices,] <- corticalThicknessData[[p]][subjectIndices.bl, thicknessColumns]
      }
    }    
  deltaThickness <- corticalThicknessData[[p]][, thicknessColumns] - baselineThickness  
  colnames( deltaThickness ) <- paste0( "d", thicknessNames )

  corticalThicknessData[[p]] <- cbind( corticalThicknessData[[p]], baselineThickness, deltaThickness )
  }

##########
#
# Read the slope files, if they exist.  Otherwise, create them.
# 
##########

slopeFiles <- c()
slopeDataList <- list()
for( i in 1:length( corticalThicknessData ) )
  {
  slopeFiles[i] <- paste0( dataDirectory, 'slopes_', corticalThicknessPipelineNames[i], '.csv' )

  if( ! file.exists( slopeFiles[i] ) )
    {
    cat( "Creating ", slopeFiles[i], "\n" )

    ID <- unique( corticalThicknessData[[i]]$ID )    
    slopeDataList[[i]] <- matrix( NA, nrow = length( subjects ), ncol = length( thicknessColumns ) )
    DX <- rep( NA, length( subjects ) )

    for( j in 1:length( subjects ) )
      {
      DX[j] <- levels( demographicsData$DX.bl )[demographicsData$DX.bl[which( demographicsData$ID == subjects[j] )][1]]
      }
    DX <- factor( DX, levels = levels( demographicsData$DX.bl ) )

    pb <- txtProgressBar( min = 0, max = ncol( slopeDataList[[i]] ), style = 3 )
   
    for( j in 1:length( thicknessColumns ) )
      {
      # corticalThicknessDataFrame <- data.frame( Y = corticalThicknessData[[i]][, thicknessColumns[j]], 
      #                                           VISIT = corticalThicknessData[[i]]$VISIT,
      #                                           ID = corticalThicknessData[[i]]$ID )
      # lmeModel <- lme( Y ~ VISIT, random = ~ VISIT -  1 | ID, data = corticalThicknessDataFrame )
      # slopeDataList[[i]][, j] <- as.numeric( lmeModel$coefficients$fixed[2]) + as.vector( lmeModel$coefficients$random[[1]][,1] )

      corticalThicknessDataFrame <- data.frame( Y = corticalThicknessData[[i]][, thicknessColumns[j]],
                                                Y.bl = corticalThicknessData[[i]][, thicknessColumns[j] + 62],
                                                dY = corticalThicknessData[[i]][, thicknessColumns[j] + 62 + 62],
                                                VISIT = corticalThicknessData[[i]]$VISIT/12,
                                                ID = corticalThicknessData[[i]]$ID,
                                                DX.bl = factor( demographicsData$DX.bl, levels = c( "CN", "LMCI", "AD" ) ),
                                                AGE.bl = demographicsData$AGE.bl,
                                                GENDER = demographicsData$GENDER,
                                                APOE4.bl = demographicsData$APOE4.bl,
                                                SITE = demographicsData$SITE,
                                                ICV.bl = demographicsData$ICV.bl
                                              )
      # lmeModel <- lmer( scale( Y ) ~ VISIT + APOE4.bl + GENDER + 
      #                       scale( AGE.bl ) + scale( ICV.bl ) + ( 1 | SITE ) +
      #                       ( VISIT - 1 | ID ), data = corticalThicknessDataFrame, REML = FALSE ) 

      lmeModel <- lmer( scale( Y ) ~ VISIT + APOE4.bl + GENDER + 
                            scale( AGE.bl ) + scale( ICV.bl ) + ( 1 | SITE ) +
                            ( VISIT | ID ), data = corticalThicknessDataFrame, REML = FALSE ) 
      slopeDataList[[i]][, j] <- 
        as.numeric( coefficients( lmeModel )$ID$VISIT + coefficients( summary( lmeModel ) )['VISIT', 'Estimate'] )

      setTxtProgressBar( pb, j )
      }
    cat( "\n" )

    slopeDataList[[i]] <- as.data.frame( slopeDataList[[i]] )
    colnames( slopeDataList[[i]] ) <- colnames( corticalThicknessData[[i]] )[thicknessColumns]

    slopeDataList[[i]] <- cbind( ID, DX, slopeDataList[[i]] )

    write.csv( slopeDataList[[i]], slopeFiles[i], quote = FALSE, row.names = FALSE )
    } else {
    cat( "Reading ", slopeFiles[i], "\n" )
    slopeDataList[[i]] <- read.csv( slopeFiles[i] )
    }
  }

##########
#
# Plot the distributions
# 
##########

thicknessColumns <- grep( "thickness", colnames( slopeDataList[[1]] ) )

roiThicknessDataFrame <- data.frame( Pipeline = factor(), Diagnosis = factor(),
  ThicknessSlope = double(), Region = factor() )
for( i in 1:length( slopeDataList ) )
  {
  for( j in 1:length( thicknessColumns ) )
    {
    combinedDiagnosis <- slopeDataList[[i]]$DX

    if( j > 31 )
      {
      hemisphere <- rep( "Right", length( combinedDiagnosis ) )
      region <- sub( "r", '', dktBrainGraphRegions[j] )
      } else {
      hemisphere <- rep( "Left", length( combinedDiagnosis ) )
      region <- sub( "l", '', dktBrainGraphRegions[j] )
      }

    singleDataFrame <- data.frame( 
      Pipeline = factor( corticalThicknessPipelineNames[i], levels = corticalThicknessPipelineNames ),
      Diagnosis = factor( slopeDataList[[i]]$DX, levels = c( 'CN', 'LMCI', 'AD' ) ),
      ThicknessSlope = slopeDataList[[i]][, thicknessColumns[j]], 
      Region = rep( region, length( slopeDataList[[i]]$DX ) ),
      Hemisphere = hemisphere )
    roiThicknessDataFrame <- rbind( roiThicknessDataFrame, singleDataFrame )
    }
  thicknessPlot <- ggplot( data = 
    roiThicknessDataFrame[which( roiThicknessDataFrame$Pipeline == corticalThicknessPipelineNames[i] ),] ) +
    geom_boxplot( aes( y = ThicknessSlope, x = Region, fill = Diagnosis ), 
      alpha = 0.75, outlier.size = 0.1 ) +
    ggtitle( corticalThicknessPipelineNames[i] ) +
    scale_y_continuous( "Thickness slope", limits = c( -0.05, 0.02 ) ) +
    scale_x_discrete( "Cortical region" ) +
    coord_flip() +
    facet_wrap( ~Hemisphere, ncol = 2 )
  ggsave( paste0( plotDir, '/', corticalThicknessPipelineNames[i], '.pdf' ),
          thicknessPlot, width = 6, height = 8, unit = 'in' )
  }

tukeyResultsDataFrame <- data.frame( Pipeline = factor(), Region = factor(), 
  Hemisphere = factor(), DiagnosticPair = factor(), Pvalue = double() )

tukeyLeft <- matrix( NA, nrow = 31, ncol = 3 * 5 )
tukeyRight <- matrix( NA, nrow = 31, ncol = 3 * 5 )

tukeyLeftCI <- matrix( NA, nrow = 31, ncol = 3 * 5 )
tukeyRightCI <- matrix( NA, nrow = 31, ncol = 3 * 5 )

for( i in 1:length( slopeDataList ) )
  {
  for( j in 1:length( thicknessColumns ) )
    {
    if( j > 31 )
      {
      hemisphere <- "Right"
      dktRegion <- sub( "r", '', dktBrainGraphRegions[j] )
      row <- j - 31
      } else {
      hemisphere <- "Left"
      dktRegion <- sub( "l", '', dktBrainGraphRegions[j] )
      row <- j
      }

    indices <- which( roiThicknessDataFrame$Hemisphere == hemisphere & 
      roiThicknessDataFrame$Region == dktRegion & 
      roiThicknessDataFrame$Pipeline == corticalThicknessPipelineNames[i] )
    regionalDataFrame <- roiThicknessDataFrame[indices,]  

    fitLm <- lm( formula = "ThicknessSlope ~ Diagnosis", 
      data = regionalDataFrame )
    anovaResults <- aov( fitLm )
    tukeyResults <- as.data.frame( TukeyHSD( anovaResults )$Diagnosis )[c( 1, 3, 2 ),]

    for( k in 1:nrow( tukeyResults ) )
      {
      tukeyResultsDataFrame <- rbind( tukeyResultsDataFrame, data.frame( 
        Pipeline = corticalThicknessPipelineNames[i],
        Region = dktRegion,
        Hemisphere = hemisphere,
        DiagnosticPair = rownames( tukeyResults )[k],
        Pvalue = tukeyResults$`p adj`[k] ) )

      # col <- ( i - 1 ) * 3 + k
      col <- ( k - 1 ) * 5 + i

      if( j > 31 )
        {
        tukeyLeft[row, col] <- as.double( tukeyResults$`p adj`[k] )
        tukeyLeftCI[row, col] <- paste0( as.character( round( tukeyResults$lwr[k], 3 ) ), 
          ",", as.character( round( tukeyResults$upr[k], 3 ) ) )
        } else {
        tukeyRight[row, col] <- as.double( tukeyResults$`p adj`[k] )
        tukeyRightCI[row, col] <- paste0( as.character( round( tukeyResults$lwr[k], 3 ) ), 
          ",", as.character( round( tukeyResults$upr[k], 3 ) ) ) 
        }
      }  
    }
  }  

tukeyLeftLog10 <- data.frame( cbind( dktBrainGraphRegions[1:31] ), log10( tukeyLeft + 1e-10 ) )
tukeyRightLog10 <- data.frame( cbind( dktBrainGraphRegions[32:62] ), log10( tukeyRight + 1e-10 ) )


## Create box plots

tukeyBoxPlotDataFrame <- data.frame( Pipeline = factor(), Diagnoses = factor(), 
  Hemisphere = factor(), Region = factor(), pValues = double() )
for( i in 2:ncol( tukeyLeftLog10 ) )
  {  
  whichPipeline <- corticalThicknessPipelineNames[( i - 2 ) %% 5 + 1]

  whichDiagnoses <- rownames( tukeyResults )[1]
  if( ( i - 1 ) > 5 && ( i - 1 ) <= 10 )
    {
    whichDiagnoses <- rownames( tukeyResults )[2]
    } else if( ( i - 1 ) > 10 ) {
    whichDiagnoses <- rownames( tukeyResults )[3]
    }

  tukeyBoxPlotDataFrame <- rbind( tukeyBoxPlotDataFrame, 
                                  data.frame( 
                                    Pipeline = rep( whichPipeline, nrow( tukeyLeftLog10 ) ),
                                    Diagnoses = rep( whichDiagnoses, nrow( tukeyLeftLog10 ) ),
                                    Hemisphere = rep( 'Left', nrow( tukeyLeftLog10 ) ),
                                    Region = dktBrainGraphRegions[1:31],
                                    pValues = -tukeyLeftLog10[,i]
                                  )  
                                )

  tukeyBoxPlotDataFrame <- rbind( tukeyBoxPlotDataFrame, 
                                  data.frame( 
                                    Pipeline = rep( whichPipeline, nrow( tukeyRightLog10 ) ),
                                    Diagnoses = rep( whichDiagnoses, nrow( tukeyLeftLog10 ) ),
                                    Hemisphere = rep( 'Right', nrow( tukeyRightLog10 ) ),
                                    Region = dktBrainGraphRegions[32:62],
                                    pValues = -tukeyRightLog10[,i]
                                  )  
                                )
  }

tukeyBoxPlotDataFrame$Pipeline <- factor( tukeyBoxPlotDataFrame$Pipeline, levels = corticalThicknessPipelineNames )
tukeyBoxPlotDataFrame$Diagnoses <- factor( tukeyBoxPlotDataFrame$Diagnoses, levels = rownames( tukeyResults ) )

boxPlot <- ggplot( data = tukeyBoxPlotDataFrame, aes( x = Pipeline, y = pValues, fill = Hemisphere ) ) +
              geom_boxplot( notch = FALSE ) +
#               scale_fill_manual( "", values = colorRampPalette( c( "navyblue", "darkred" ) )(3) ) +
              facet_wrap( ~Diagnoses, scales = 'free', ncol = 3 ) +
              theme( axis.text.x = element_text( face="bold", size = 10, angle = 45, hjust = 1 ) ) +
              labs( x = '', y = '-log10( pvalues )' )
ggsave( paste0( plotDir, "/logPvalues.pdf" ), boxPlot, width = 10, height = 4 )




leftFile <- paste0( manuscriptDirectory, "leftAovTable.tex" )
tukeyLeftLog10 %>% 
  # mutate_if( is.numeric, funs( round( ., 2 ) ) ) %>%
  mutate_if( is.numeric, function( x ) {
    cell_spec( x, "latex", bold = F, color = "black", 
    background = spec_color( x, begin = 0.65, end = 1.0, option = "B", 
      alpha = 0.9, na_color = "#FFFFFF", scale_from = c( -10.0, -1.0 ), direction = 1 ) )
    } ) %>%
  kable( format = "latex", escape = F, 
    # col.names = c( "DKT", rep( rownames( tukeyResults ), 5 ) ), linesep = "", 
    col.names = c( "DKT", rep( corticalThicknessPipelineNames, 3 ) ), linesep = "", 
    align = "c", booktabs = T, caption = 
    paste0( "95\\% confidence intervals for the difference in slope values for the ", 
            "three diagnoses (CN, LMCI, AD) of the ADNI-1 data set for each DKT region ",
            "of the left hemisphere.  Each cell is color-coded based on the adjusted log-scaled $p$-value ",
            "significance from dark orange ($p$ < 1e-10) to yellow ($p$ = 0.1). ",
            "Absence of color denotes nonsignificance." ) ) %>%
  column_spec( 1, bold = T ) %>%
  row_spec( 0, angle = 45, bold = F ) %>%
  kable_styling( position = "center", latex_options = c( "scale_down" ) ) %>%
  # add_header_above( c( " ", "FSCross" = 3, "FSLong" = 3, "ANTsCross" = 3, "ANTsNative" = 3, "ANTsSST" = 3 ), bold = T ) %>%
  add_header_above( c( " ", "LMCI-CN" = 5, "AD-CN" = 5, "AD-LMCI" = 5 ), bold = T ) %>%
  cat( file = leftFile, sep = "\n" )

rightFile <- paste0( manuscriptDirectory, "rightAovTable.tex" )
tukeyRightLog10 %>% 
  # mutate_if( is.numeric, funs( round( ., 2 ) ) ) %>%
  mutate_if( is.numeric, function( x ) {
    cell_spec( x, "latex", bold = F, color = "black", 
    background = spec_color( x, begin = 0.65, end = 1.0, option = "B", 
      alpha = 0.9, na_color = "#FFFFFF", scale_from = c( -10.0, -1.0 ), direction = 1 ) )
    } ) %>%
  kable( format = "latex", escape = F, 
    # col.names = c( "DKT", rep( rownames( tukeyResults ), 5 ) ), linesep = "", 
    col.names = c( "DKT", rep( corticalThicknessPipelineNames, 3 ) ), linesep = "", 
    align = "c", booktabs = T, caption = 
    paste0( "95\\% confidence intervals for the difference in slope values for the ", 
            "three diagnoses (CN, LMCI, AD) of the ADNI-1 data set for each DKT region ",
            "of the right hemisphere.  Each cell is color-coded based on the adjusted log-scaled $p$-value ",
            "significance from dark orange ($p$ < 1e-10) to yellow ($p$ = 0.1). ",
            "Absence of color denotes nonsignificance." ) ) %>%
  column_spec( 1, bold = T ) %>%
  row_spec( 0, angle = 45, bold = F ) %>%
  kable_styling( position = "center", latex_options = c( "scale_down" ) ) %>%
  # add_header_above( c( " ", "FSCross" = 3, "FSLong" = 3, "ANTsCross" = 3, "ANTsNative" = 3, "ANTsSST" = 3 ), bold = T ) %>%
  add_header_above( c( " ", "LMCI-CN" = 5, "AD-CN" = 5, "AD-LMCI" = 5 ), bold = T ) %>%
  cat( file = rightFile, sep = "\n" )

## Now replace the adjusted p-values with the actual confidence
## intervals

leftFile2 <- paste0( manuscriptDirectory, "leftAovTable2.tex" )
rightFile2 <- paste0( manuscriptDirectory, "rightAovTable2.tex" )

inputFiles <- c( leftFile, rightFile )
outputFiles <- c( leftFile2, rightFile2 )

tukeyPairResults <- list( tukeyLeftLog10, tukeyRightLog10 )
tukeyPairResultsCI <- list( tukeyLeftCI, tukeyRightCI )

for( i in 1:2 )
  {
  fileId <- file( inputFiles[i], "r" )
  file2Id <- file( outputFiles[i], "w" )

  currentRow <- 1
  fileRow <- 0
  while( TRUE )
    {
    line <- readLines( fileId, n = 1 )
    if( length( line ) == 0 ) 
      {
      break  
      }

    fileRow <- fileRow + 1
    if( fileRow >= 11 && fileRow <= 41 )
      {
      tokens <- unlist( strsplit( line, '&' ) )
      for( j in 2:length( tokens ) )
        {
        tokens[j] <- gsub( tukeyPairResults[[i]][currentRow, j], 
          tukeyPairResultsCI[[i]][currentRow, j-1], tokens[j], fixed = TRUE )  
        }
      currentRow <- currentRow + 1  
      line <- paste( tokens, collapse = " & ")
      }
    writeLines( line, file2Id )
    }
  close( fileId )
  close( file2Id )
  }


##########
#
# Plot the distributions
# 
##########

# pb <- txtProgressBar( min = 0, max = length( thicknessColumns ), style = 3 )

# for( j in 1:length( thicknessColumns ) )
#   {
#   roiThicknessDataFrame <- data.frame( Diagnosis = factor(), 
#     ThicknessSlopes = double(), PipelineType = factor()  )
#   for( i in 1:length( slopeDataList ) )
#     {
#     combinedDiagnosis <- slopeDataList[[i]]$DIAGNOSIS

#     pipelineDataFrame <- data.frame(
#       Diagnosis = factor( combinedDiagnosis, levels = c( 'CN', 'LMCI', 'AD' ) ),
#       ThicknessSlope = slopeDataList[[i]][,thicknessColumns[j]],
#       PipelineType = rep( corticalThicknessPipelineNames[i], length( nrow( slopeDataList[[i]] ) ) )
#       )
#     roiThicknessDataFrame <- rbind( roiThicknessDataFrame, pipelineDataFrame )
#     }

#   roiThicknessPlot <- ggplot( data = roiThicknessDataFrame ) +
#     geom_density( aes( x = ThicknessSlope, fill = Diagnosis ), alpha = 0.5 ) +
#     facet_wrap( ~ PipelineType, ncol = 3 ) +
#     ggtitle( colnames( slopeDataList[[i]] )[thicknessColumns[j]] ) +
#     scale_x_continuous( "Thickness slope" )
#   ggsave( paste0( plotDir, '/', colnames( slopeDataList[[i]] )[thicknessColumns[j]], '.pdf' ),
#           roiThicknessPlot, width = 8, height = 3, unit = 'in' )

#   setTxtProgressBar( pb, j )
#   }




