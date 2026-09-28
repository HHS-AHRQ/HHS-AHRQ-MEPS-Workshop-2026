# -----------------------------------------------------------------------------
# This program shows how to link the MEPS-HC Medical Conditions file 
# to the Office-based medical visits file for data year 2023 to estimate:
#   - Total number of people w/ office-based visit for cancer
#   - Total number of office visits for cancer
#   - Total expenditures on office visits for cancer 
#   - Percent of people with an office visit for cancer
#   - Average per-person expense for office visits for cancer
#
# Input files:
#   - h248g.dta        (2023 Office-based medical visits file)
#   - h249.dta         (2023 Conditions file)
#   - h248if1.dta      (2023 CLNK: Condition-Event Link file)
#   - h251.dta         (2023 Full-Year Consolidated file)
# 
# Resources:
#   - CCSR codes: 
#   https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_ccsr_conditions.csv
# 
#   - MEPS-HC Public Use Files: 
#   https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp
# 
#   - MEPS-HC online data tools: 
#   https://datatools.ahrq.gov/meps-hc
#
# -----------------------------------------------------------------------------


# Install/load packages and set global options --------------------------------

# Can skip this part if already installed

# Can skip this part if already installed

# install.packages("survey")    # for survey analysis
# install.packages("haven")     # for loading Stata (.dta) files
# install.packages("tidyverse") # for data manipulation
# install.packages("devtools")  # for loading "MEPS" package from GitHub

# To install MEPS package, un-comment below and run

# library(devtools)
# install_github("e-mitchell/meps_r_pkg/MEPS")


# Load libraries (run this part each time you restart R)




# Set survey option for lonely PSUs




# Additional option for adjusting variance for lonely PSUs within a domain
#  - More info at https://r-survey.r-forge.r-project.org/survey/html/surveyoptions.html
#  - Not running in these exercises, so SEs will match Stata
#
# options(survey.adjust.domain.lonely = TRUE) 
  

# Load datasets ---------------------------------------------------------------
  
#  OB   = Office-based medical visits file (record = medical visit)
#  COND = Medical conditions file (record = medical condition)
#  CLNK = Conditions-event link file (crosswalk between conditions and 
#             events, including PMED events)
#  FYC  = Full-year-consolidated file (record = MEPS sample person)
  
### Option 1 - Load data files using read_MEPS from the MEPS package





### Option 2 - Load Stata data files using read_dta from the haven package 

# ob23   <- read_dta("C:/MEPS/h248g.dta") 
# cond23 <- read_dta("C:/MEPS/h249.dta")
# clnk23 <- read_dta("C:/MEPS/h248if1.dta")
# fyc23  <- read_dta("C:/MEPS/h251.dta")


# Keep only needed variables ------------------------------------------------

#  Browse variables using MEPS-HC data tools variable explorer: 
#  -> http://datatools.ahrq.gov/meps-hc#varExp





# Prepare data for estimation -------------------------------------------------

# Subset condition records to CANCER (any CCSR = "NEO...") 
#  + FAC006 (Encounters for antineoplastic therapies)
#  - NEO073 (Benign neoplasms)









# view ICD10-CCSR combinations for cancer





# >> Note that the same person can have multiple cancers, and can even have 
# multiple conditions with the same ICD10CDX and CCSR values

# >> Example: DUPERSID == '2790405102'





# Merge cancer conditions with OB event file, using CLNK as crosswalk
#  >> use multiple = "all" option for many-to-many merge




# QC: check that EVENTYPE = 1 (OB) for all rows in cancer_merged





# >> Example of same event (EVNTIDX) for treating multiple cancers for same
# person
     



     
# De-duplicate on EVNTIDX so we don't count the same event twice
     




# >> Check example person (DUPERSID == '2790405102'):





# Aggregate to person-level --------------------------------------------------
     




# Add person-level indicator variable
     



# Revisiting our example case at the person level



# Merge onto FYC file ---------------------------------------------------------
#  >> Need to capture all Strata (VARSTR) and PSUs (VARPSU) for all MEPS sample 
#     persons for correct variance estimation




# QC: should have same number of rows as FYC file




# QC: There should be no records where any_OB=0 and (pers_ob_exp> 0 or ob_visits > 0)


 
    
# Define the survey design ----------------------------------------------------





# Calculate estimates ---------------------------------------------------------

# Turn off scientific notation
  


  
# National Totals:
  




# Percent of people with office visit for cancer



  
# Average per-person expense for office visits for cancer among people with an
# an office visit for cancer 
  




