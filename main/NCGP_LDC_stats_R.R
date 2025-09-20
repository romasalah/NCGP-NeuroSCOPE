stattype  <- "LLM"
maskname <-  "localizer"
hemi <- "R"
wf <- list()
wf$glmresiduals <- 1
wf$hemis <- hemis
wf$pre <- "fmriprep"
wf$decoding <- "Cosmo_surfdecoding"
wf$stats <- "perm_stats"
wf$glm <- "SPM_GLM"
wf$mcc <- "FDR_MCC"
wf$radius <- 10
wf$classifier <- "libsvm"
wf$mainpath <- "C:\\Users\\CENs-Admin\\Documents\\Omar\\NCGP"
wf$t1folder <- paste0(wf$mainpath, wf$pre, "\\fsaverage6\\T1\\")
wf$runs <- c("run-01", "run-02", "run-04", "run-05", "run-06")
wf$sessions <- c("ses-02", "ses-03")
wf$task <- "faces"
wf$modeltype <- "regperidentity"
wf$alignment <- "hpal"
wf$refsub <- "fsaverage6"
wf$subs <- "group"
wf$volskip <- 0
wf$hemis <- hemi
# Initialize the lists
bres <- vector("list", length = length(wf$hemis))
wres <- vector("list", length = length(wf$hemis))
slnames <- vector("list", length = length(wf$hemis))

curhemi <- wf$hemis

outputfolder <- paste0(wf$mainpath, "\\LDC\\", wf$subs[subi], "\\", wf$pre, "\\", wf$glm, "\\")
fnprefix <- paste0(outputfolder, "sub-", wf$subs[subi], "_task-", wf$task, "_hemi-", curhemi, "_mask-", maskname, "_ses-all")
llmdesfn <- paste0(fnprefix, "_prepost_LLM_crctd.csv")
preposttbl <- read.csv(llmdesfn)
# Specify the model
if (stattype == "LLM") {
  # Fit the linear mixed model
  # Note: Fitting LMM in R requires the 'lme4' package
  lme_sl <- lmer(LDCvalue ~ Session + Contrast + Session:Contrast + (1 | Searchlight), data = preposttbl)
  
  # Identify significant interactions
  # Note: This section might require adjustment based on specific needs
} else if (stattype == "rmANOVA") {
  # Note: Repeated measures ANOVA in R can be performed using the 'ez' package
  allsls <- unique(preposttbl$Searchlight)
  bres <- vector("list", length = length(wf$allsls))
  wres <- vector("list", length = length(wf$allsls))
  slnames <- vector("list", length = length(wf$allsls))
  anovatbl <- vector("list", length = length(wf$allsls))
  rmanova_sl <- vector("list", length = length(wf$allsls))
  # Assuming curtbl is a data.frame in R
  prew <- curtbl$LDCvalue[curtbl$Contrast == 'Within-group' & curtbl$Session == 'ses-02']
  postw <- curtbl$LDCvalue[curtbl$Contrast == 'Within-group' & curtbl$Session == 'ses-03']
  preb <- curtbl$LDCvalue[curtbl$Contrast == 'Between-group' & curtbl$Session == 'ses-02']
  postb <- curtbl$LDCvalue[curtbl$Contrast == 'Between-group' & curtbl$Session == 'ses-03']
  
  # Creating a new data frame
  anovatbl[[sli]] <- data.frame(pre_b = preb, post_b = postb, 
                                pre_w = c(prew, rep(NA, 4)), 
                                post_w = c(postw, rep(NA, 4)))
  
  # Setting up within-subject factors for ANOVA
  TimePoint <- c('pre', 'post', 'pre', 'post')
  MeasurementType <- c('b', 'b', 'w', 'w')
  WithinStructure <- data.frame(TimePoint, MeasurementType)
  rrANOVAdesfn <- paste0(fnprefix, "_prepost_rmANOVA_sample.csv")
  write.csv(anovatbl[[sli]], rrANOVAdesfn)
  # Fit the repeated measures ANOVA
  # This part will depend on the specific R package you are using for ANOVA
  # Example with ezANOVA (from ez package):
  library(ez)
  rmanova_sl[[sli]] <- ezANOVA(data = anovatbl[[sli]], 
                               dv = .(pre_b, post_b, pre_w, post_w), 
                               wid = .(YourSubjectIDColumn), 
                               within = .(TimePoint, MeasurementType), 
                               type = 1) # Replace YourSubjectIDColumn with your actual subject ID column
  
  for (cursl in allsls) {
    print(cursl)
    curtbl <- subset(preposttbl, preposttbl$Searchlight == cursl)
    # Assuming curtbl is a data.frame in R
    prew <- curtbl$LDCvalue[curtbl$Contrast == 'Within-group' & curtbl$Session == 'ses-02']
    postw <- curtbl$LDCvalue[curtbl$Contrast == 'Within-group' & curtbl$Session == 'ses-03']
    preb <- curtbl$LDCvalue[curtbl$Contrast == 'Between-group' & curtbl$Session == 'ses-02']
    postb <- curtbl$LDCvalue[curtbl$Contrast == 'Between-group' & curtbl$Session == 'ses-03']
    
    # Creating a new data frame
    anovatbl[[sli]] <- data.frame(pre_b = preb, post_b = postb, 
                                  pre_w = c(prew, rep(NA, 4)), 
                                  post_w = c(postw, rep(NA, 4)))
    
    # Setting up within-subject factors for ANOVA
    TimePoint <- c('pre', 'post', 'pre', 'post')
    MeasurementType <- c('b', 'b', 'w', 'w')
    WithinStructure <- data.frame(TimePoint, MeasurementType)
    
    # Fit the repeated measures ANOVA
    # This part will depend on the specific R package you are using for ANOVA
    # Example with ezANOVA (from ez package):
    library(ez)
    rmanova_sl[[sli]] <- ezANOVA(data = anovatbl[[sli]], 
                                 dv = .(pre_b, post_b, pre_w, post_w), 
                                 wid = .(YourSubjectIDColumn), 
                                 within = .(TimePoint, MeasurementType), 
                                 type = 1) # Replace YourSubjectIDColumn with your actual subject ID column
    
    # Perform rmANOVA
    # Note: This requires detailed implementation based on the specific data structure
  }
  # FDR correction of post-hoc tests
  # Note: FDR correction can be done using the 'p.adjust' function in R
  # Example: breswres_pFDR <- p.adjust(c(bres, wres), method = "fdr")
}
list(slnames = slnames, bres = bres, wres = wres)

