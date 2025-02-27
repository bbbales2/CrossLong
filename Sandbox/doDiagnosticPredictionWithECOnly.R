library( reshape2 )
library( ggplot2 )
library( caret )
library( e1071 )
library( grid )
library( xgboost )
library( randomForest )
library( plyr )



originalDataFileSubEc <- 'adniLongitudinalNativeSpaceSubEcAntsMergeSubset_WithScr.csv'

dataWithEc <- read.csv( 'adniLongitudinalNativeSpaceAntsMergeSubset_WithScr.csv' )
ecData <- read.csv( 'adniEntorhinalAntsMergeSubsetAtith_WithScr.csv' )

dataWithEc$thickness.left.entorhinal <- ecData$left.EC
dataWithEc$thickness.right.entorhinal <- ecData$right.EC

write.csv( dataWithEc, originalDataFileSubEc, quote = FALSE, row.names = FALSE )

##
#
#  Create the "slope" files from the original cortical thickness files.  Each
#
#

originalDataFiles <- c( 'adniCrossSectionalAntsMergeSubset_WithScr.csv',
                        'adniLongitudinalAntsMergeSubset_WithScr.csv',
                        'adniLongitudinalNativeSpaceAntsMergeSubset_WithScr.csv',
                        originalDataFileSubEc,
                        'adniCrossSectionalFreeSurferMergeSubset_WithScr.csv',
                        'adniLongitudinalFreeSurferMergeSubset_WithScr.csv'
                       )
slopeFiles <- c( 'adniCrossSlopeData_WithScr.csv',
                 'adniLong1SlopeData_WithScr.csv',
                 'adniLong2SlopeData_WithScr.csv',
                 'adniLong2SlopeDataSubEc_WithScr.csv',
                 'adniCrossFreeSurferSlopeData_WithScr.csv',
                 'adniLongFreeSurferSlopeData_WithScr.csv'
               )
slopeDataList <- list()

for( i in 1:length( slopeFiles ) )
  {
  if( ! file.exists( slopeFiles[i] ) )
    {
    cat( "Creating ", slopeFiles[i], "\n" )

    originalData <- read.csv( originalDataFiles[i] )
    crossData <- read.csv( originalDataFiles[1] )

    visit <- crossData$VISIT
    diagnosis <- crossData$DIAGNOSIS
    age <- crossData$AGE
    sex <- crossData$SEX
    subjects <- unique( crossData$ID )

    originalData <- originalData[,grep( "thickness", colnames( originalData ) )]
    if( 'total.mean.thickness' %in% colnames( originalData ) )
      {
      originalData <- originalData[,-grep( "total.mean.thickness", colnames( originalData ) )]
      }
    originalData$ID <- crossData$ID
    originalData$VISIT <- visit
    originalData$DIAGNOSIS <- diagnosis
    originalData$AGE <- age
    originalData$SEX <- sex

#     timePointsString <- c( 'scr', 'bl', 'm06', 'm12', 'm18', 'm24', 'm36' )
#     timePointsNumeric <- c( 0, 0, 6, 12, 18, 24, 36 )
#
#     numericVisit <- rep( 'NA', length( originalData$VISIT ) )
#     for( m in 1:length( timePointsString ) )
#       {
#       numericVisit[originalData$VISIT == timePointsString[m]] <- timePointsNumeric[m]
#       }
#     originalData$VISIT <- as.numeric( numericVisit )

    thicknessColumns <- grep( "entorhinal", colnames( originalData ) )
    slopeDataList[[i]] <- matrix( NA, nrow = length( subjects ), ncol = length( thicknessColumns ) )

    pb <- txtProgressBar( min = 0, max = nrow( slopeDataList[[i]] ) * ncol( slopeDataList[[i]] ), style = 3 )

    sexes <- rep( NA, length( subjects ) )
    diagnoses <- rep( NA, length( subjects ) )
    averageAges <- rep( NA, length( subjects ) )
    for( j in 1:length( subjects ) )
      {
      subject <- subjects[j]
      subjectData <- originalData[which( originalData$ID == subject ),]

      diagnoses[j] <- subjectData$DIAGNOSIS[1]
      sexes[j] <- subjectData$SEX[1]
      averageAges[j] <- mean( subjectData$AGE, na.rm = TRUE )

      for( k in 1:length( thicknessColumns ) )
        {
        if( prod( is.na( subjectData[,k]  ) ) == 0 )
          {
          lmResults <- lm( subjectData[,k] ~ subjectData$AGE, na.action=na.omit )
          slopeDataList[[i]][j, k] <- lmResults$coefficients[2]
          }
        setTxtProgressBar( pb, j * length( thicknessColumns ) + k )
        }
      }
    cat( "\n" )

    slopeDataList[[i]] <- as.data.frame( slopeDataList[[i]] )

    colnames( slopeDataList[[i]] ) <- colnames( originalData )[thicknessColumns]

    slopeDataList[[i]]$DIAGNOSIS <- diagnoses
    slopeDataList[[i]]$AverageAge <- averageAges

    write.csv( slopeDataList[[i]], slopeFiles[i], quote = FALSE, row.names = FALSE )
    } else {
    cat( "Reading ", slopeFiles[i], "\n" )
    slopeDataList[[i]] <- read.csv( slopeFiles[i] )
    }
  }


##
#
#  Do prediction
#
#

nPermutations <- 1000

trainingPortions <- c( 0.6, 0.7, 0.8, 0.9 )


slopeTypes <- c( "ANTs cross", "ANTs SST", "ANTs native", "ANTs native (EC)", "FreeSurfer cross", "FreeSurfer long", "Random" )

count <- 1
for( p in trainingPortions )
  {
  trainingPortion <- p
  cat( "trainingPortion = ", trainingPortion, "\n", sep = '' )

  resultsData <- data.frame( Pipeline = character( 0 ), Accuracy = numeric( 0 ) )

  featureImpMean <- list()
  featureImpSd <- list()
  for( n in seq( 1, nPermutations, by = 1 ) )
    {
    cat( "  Permutation ", n, "\n", sep = '' )

    trainingIndices <- createDataPartition( slopeDataList[[1]]$DIAGNOSIS, p = trainingPortion, list = FALSE, times = 1 )

    for( d in 1:length( slopeTypes ) )
      {

      if( slopeTypes[d] == "Random" )
        {

        # do Random case
        testingData <- slopeDataList[[1]][-trainingIndices,]
        testingData <- testingData[complete.cases( testingData ),]
        predictedDiagnosis <- sample.int( n = 4,  size = length( testingData$DIAGNOSIS ), replace = TRUE )

        } else {

        trainingData <- slopeDataList[[d]][trainingIndices,]
        trainingData <- trainingData[complete.cases( trainingData ),]
        testingData <- slopeDataList[[d]][-trainingIndices,]
        testingData <- testingData[complete.cases( testingData ),]

        predictorColumns <-   sort( c( grep( "entorhinal", colnames( trainingData ) ) ) )

        # modelDataXgb <- xgb.DMatrix( as.matrix( trainingData[, predictorColumns] ),
        #                                      label = trainingData$DIAGNOSIS - 1 )
        # paramXgb <- list( max.depth = 9, eta = 0.1, silent = 0, objective = "multi:softmax", num_class = 4 )
        # modelXgb <- xgb.train( paramXgb, modelDataXgb, nrounds = 100, nthread = 8, verbose = 0 )
        # predictedDiagnosis <- predict( modelXgb, as.matrix( testingData[, !( names( testingData ) %in% c( "DIAGNOSIS" ) )] ) ) + 1
        #
        # xgbImp <- xgb.importance( model = modelXgb )
        # sorted <- sort( as.numeric( xgbImp$Feature ), index.return = TRUE )
        # if( n == 1 )
        #   {
        #   featureImpMean[[d]] <- xgbImp$Gain[sorted$ix]
        #   featureImpSd[[d]] <- 0.0
        #   } else {
        #   featureImpPreviousMean <- featureImpMean[[d]]
        #   featureImpMean[[d]] <- featureImpPreviousMean + ( xgbImp$Gain[sorted$ix] - featureImpPreviousMean ) / ( n - 1 )
        #   featureImpSd[[d]] <- featureImpSd[[d]] + ( xgbImp$Gain[sorted$ix] - featureImpPreviousMean ) * ( xgbImp$Gain[sorted$ix] - featureImpMean[[d]] )
        #  }

        diagnosisRF <- randomForest( x = trainingData[, predictorColumns],
                                     y = as.factor( trainingData$DIAGNOSIS ), importance = TRUE,
                                     na.action = na.omit, replace = FALSE, ntree = 500 )
        predictedDiagnosis <- predict( diagnosisRF, testingData[, predictorColumns] )
        if( n == 1 )
          {
          featureImpMean[[d]] <- importance( diagnosisRF, type = 1 )
          featureImpSd[[d]] <- 0.0
          } else {
          featureImpPreviousMean <- featureImpMean[[d]]
          imp <-  importance( diagnosisRF, type = 1 )
          featureImpMean[[d]] <- featureImpPreviousMean + ( imp - featureImpPreviousMean ) / ( n - 1 )
          featureImpSd[[d]] <- featureImpSd[[d]] + ( imp - featureImpPreviousMean ) * ( imp - featureImpMean[[d]] )
          }
        }

      cMatrix <- confusionMatrix( predictedDiagnosis, testingData$DIAGNOSIS, mode = "everything" )
      cat( "    ", slopeTypes[d], ": accuracy = ", cMatrix$overall[[1]], "\n", sep = '' )

      oneData <- data.frame( Pipeline = slopeTypes[d],
                             Accuracy = cMatrix$overall[[1]] )
      resultsData <- rbind( resultsData, oneData )
      }

    if( n %% 10 == 0 )
      {
      rmsePlot <- ggplot( resultsData, aes( x = Accuracy, fill = Pipeline ) ) +
                          scale_y_continuous( "Density" ) +
                          scale_x_continuous( "Accuracy" ) +
                         geom_density( alpha = 0.5 )
      ggsave( filename = paste( "~/Desktop/accuracy", p, "_WithScr.png", sep = "" ), plot = rmsePlot, width = 6, height = 6, units = 'in' )

      resultsDataBarPlot <- ddply( resultsData, "Pipeline", summarise, meanAccuracy = mean( Accuracy ), sdAccuracy = sd( Accuracy ) )
      rmseBarPlot <- ggplot( resultsDataBarPlot, aes( x = Pipeline, y = meanAccuracy ) ) +
                     geom_bar( aes( fill = Pipeline ), stat = "identity" ) +
                     geom_errorbar( aes( ymin = meanAccuracy - sdAccuracy, ymax = meanAccuracy + sdAccuracy ), width = 0.35 ) +
                     scale_y_continuous( "Accuracy" ) +
                     theme( legend.position = "none" )
      ggsave( filename = paste( "~/Desktop/accuracyBarPlot", p, "_WithScr.png", sep = "" ), plot = rmseBarPlot, width = 8, height = 5, units = 'in' )
      }


    }

  for( n in 1:length( slopeTypes ) )
    {
    if( slopeTypes[n] == "Random" )
      {
      next
      }
    predictorColumns <- sort( c( grep( "entorhinal", colnames( slopeDataList[[i]] ) ) ) )

    featureImp.df <- data.frame( Statistic = colnames( slopeDataList[[i]] )[predictorColumns],
                                 Importance = featureImpMean[[n]],
                                 ImportanceSd = featureImpSd[[n]] )

    # featureImp.df <- data.frame( Statistic = names( featureImpMean[[n]][,1] ),
    #                              Importance = as.numeric( featureImpMean[[n]][,1] ),
    #                              ImportanceSd = as.numeric( featureImpSd[[n]] ) )

    colnames( featureImp.df ) <- c( "Statistic", "Importance", "ImportanceSd" )
    featureImp.df <- featureImp.df[order( featureImp.df$Importance ),]

    modifiedStatistic <- gsub( 'thickness.', '', featureImp.df$Statistic )

    featureImp.df$Statistic <- factor( x = modifiedStatistic, levels = modifiedStatistic )

    vPlot <- ggplot( data = featureImp.df, aes( x = Importance, y = Statistic ) ) +
             geom_point( aes( color = Importance ) ) +
            #  geom_errorbarh( aes( xmax = Importance + ImportanceSd, xmin = Importance - ImportanceSd, color = Importance ) ) +
             ylab( "" ) +
             scale_x_continuous( "MeanDecreaseAccuracy" ) +
#              scale_color_continuous( low = "navyblue", high = "darkred" ) +
             theme( axis.text.y = element_text( size = 8 ) ) +
             theme( plot.margin = unit( c( 0.1, 0.1, 0.1, -0.5 ), "cm" ) ) +
             theme( axis.title = element_text( size = 9 ) ) +
             theme( legend.position = "none" )

    ggsave( file = paste( "~/Desktop/importanceCombined", slopeTypes[n], p, "_WithScr.png", sep = "" ), plot = vPlot, width = 4, height = 8 )
    }

  myAov <- aov( Accuracy ~ Pipeline, data = resultsData )
  TukeyHSD( myAov, c( "Pipeline" ) )
  }
