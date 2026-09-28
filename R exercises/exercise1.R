# -----------------------------------------------------------------------------
# This program generates the following estimates for national health care for 
# the U.S. civilian non-institutionalized population, 2023:
#  - Overall expenses (National totals)
#  - Percentage of persons with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group
#
# Input file:
#  - C:/MEPS/h251.dta (2023 Full-year file - Stata format)
#
# -----------------------------------------------------------------------------

# Install/load packages and set global options --------------------------------

# Can skip this part if already installed

# install.packages("survey")    # for survey analysis
# install.packages("haven")     # for loading Stata (.dta) files
# install.packages("tidyverse") # for data manipulation
# install.packages("devtools")  # for loading "MEPS" package from GitHub
  
# To install MEPS package, un-comment below and run

# library(devtools)
# install_github("e-mitchell/meps_r_pkg/MEPS")
  
# Load packages (run this part each time you restart R)

library(MEPS)
library(survey)
library(haven)
library(tidyverse)


# Set survey option for lonely PSUs
  
options(survey.lonely.psu='adjust')
  
# Additional option for adjusting variance for lonely PSUs within a domain
#  - More info at https://r-survey.r-forge.r-project.org/survey/html/surveyoptions.html
#  - Not running in these exercises, so SEs will match Stata
#
# options(survey.adjust.domain.lonely = TRUE) 
  

# Load datasets ---------------------------------------------------------------

### Option 1 - load data files using read_MEPS from the MEPS package

fyc23 <- read_MEPS(year = 2023, type = "FYC")


### Option 2 - load Stata data files using read_dta from the haven package 

#  >> Replace "C:/MEPS" below with the directory you saved the files to.

fyc23_v2 <- read_dta("C:/MEPS/h251.dta")

  
# Using tidyverse syntax. The '%>%' is a pipe operator, which inverts
# the order of the function call. For example, mean(x) becomes x %>% mean

# Keep only needed variables --------------------------------------------------
# - codebook: 
#  https://meps.ahrq.gov/mepsweb/data_stats/download_data_files_codebook.jsp?PUFId=H251
  
fyc23_sub <- fyc23 %>%
              select(AGELAST, TOTEXP23, DUPERSID, VARSTR, VARPSU, PERWT23F) 
  

# Construct flags for whether a person has any expense and age group ----------

fyc23x <- fyc23_sub %>%
              mutate(has_exp = (TOTEXP23 > 0), 
              age_cat = ifelse(AGELAST < 65, "<65", "65+"))  
    
  
head(fyc23x)


# QC new flag variables
  
fyc23x %>% 
    count(has_exp, age_cat)
  
fyc23x %>%
    group_by(has_exp) %>%
    summarise(
      min = min(TOTEXP23), 
      max = max(TOTEXP23))
  
fyc23x %>%
    group_by(age_cat) %>%
    summarise(
      min = min(AGELAST), 
      max = max(AGELAST))


# Define the survey design ----------------------------------------------------
    
meps_dsgn = svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWT23F,
    data = fyc23x,
    nest = TRUE)

  
# Calculate estimates ---------------------------------------------------------
#  - Overall expenditures (National totals)
#  - Percentage of people with an expense
#  - Mean expense per person
#  - Mean/median expense per person with an expense:
#    - Mean expense per person with an expense
#    - Mean expense per person with an expense, by age group
#    - Median expense per person with an expense, by age group

  
# Turn off scientific notation

options(digits = 10)
  
  
# Overall expenses (National totals)
  
svytotal(~TOTEXP23, design = meps_dsgn) 

# Percentage of persons with an expense
  
svymean(~has_exp, design = meps_dsgn)

# Mean expense per person
  
svymean(~TOTEXP23, design = meps_dsgn) 
  
  
# Mean/median expense per person with an expense --------------------
  
# Subset design object to people with expense:
  
has_exp_dsgn <- subset(meps_dsgn, has_exp)
  
# Mean expense per person with an expense
  
svymean(~TOTEXP23, design = has_exp_dsgn)

# Mean expense per person with an expense, by age category
  
svyby(~TOTEXP23, by = ~age_cat, FUN = svymean, design = has_exp_dsgn)

# Median expense per person with an expense, by age category
  
svyby(~TOTEXP23, by  = ~age_cat, FUN = svyquantile, design = has_exp_dsgn,
    quantiles = c(0.5))
