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
  
#  OB   = Office-based medical visits file (record = medical visit)
#  COND = Medical conditions file (record = medical condition)
#  CLNK = Conditions-event link file (crosswalk between conditions and 
#             events, including PMED events)
#  FYC  = Full-year-consolidated file (record = MEPS sample person)
  
### Option 1 - Load data files using read_MEPS from the MEPS package

ob23 <- read_MEPS(year = 2023, type = "OB")
cond23 <- read_MEPS(year = 2023, type = "Conditions")
clnk23 <- read_MEPS(year = 2023, type = "CLNK")
fyc23 <- read_MEPS(year = 2023, type = "FYC")

### Option 2 - Load Stata data files using read_dta from the haven package 

# ob23   <- read_dta("C:/MEPS/h248g.dta") 
# cond23 <- read_dta("C:/MEPS/h249.dta")
# clnk23 <- read_dta("C:/MEPS/h248if1.dta")
# fyc23  <- read_dta("C:/MEPS/h251.dta")


# Keep only needed variables ------------------------------------------------

#  Browse variables using MEPS-HC data tools variable explorer: 
#  -> http://datatools.ahrq.gov/meps-hc#varExp

ob23x <- ob23 %>% 
         select(DUPERSID, EVNTIDX, OBXP23X)

cond23x <- cond23 %>% 
           select(DUPERSID, CONDIDX, ICD10CDX, CCSR1X:CCSR4X)

fyc23x <- fyc23 %>% 
          select(DUPERSID, AGELAST, PERWT23F, VARSTR, VARPSU)


# Prepare data for estimation -------------------------------------------------

# Subset condition records to CANCER (any CCSR = "NEO...") 
#  + FAC006 (Encounters for antineoplastic therapies)
#  - NEO073 (Benign neoplasms)


cond_combos <- cond23 %>% 
               count(CCSR1X, CCSR2X, CCSR3X, CCSR4X)

View(cond_combos)


cancer <- cond23x %>% 
  filter(
    grepl("NEO", CCSR1X) |
      grepl("NEO", CCSR2X) |
      grepl("NEO", CCSR3X) |
      grepl("NEO", CCSR4X) |
      
      CCSR1X == "FAC006" |
      CCSR2X == "FAC006" |
      CCSR3X == "FAC006" |
      CCSR4X == "FAC006") %>% 
  
  filter(CCSR1X != "NEO073" &
             CCSR2X != "NEO073" &
             CCSR3X != "NEO073" &
             CCSR4X != "NEO073") 


# view ICD10-CCSR combinations for cancer

cancer %>% 
  count(ICD10CDX, CCSR1X, CCSR2X, CCSR3X, CCSR4X)


# >> Note that the same person can have multiple cancers, and can even have 
# multiple conditions with the same ICD10CDX and CCSR values

# >> Example: DUPERSID == '2790405102'

cancer %>% filter(DUPERSID == '2790405102')


# Merge cancer conditions with OB event file, using CLNK as crosswalk
#  >> use multiple = "all" option for many-to-many merge

cancer_merged <- cancer %>%
  inner_join(clnk23, by = c("DUPERSID", "CONDIDX"), multiple = "all") %>% 
  inner_join(ob23x, by = c("DUPERSID", "EVNTIDX"), multiple = "all") %>% 
  mutate(ob_visit = 1)

# QC: check that EVENTYPE = 1 (OB) for all rows in cancer_merged

clnk23 %>% count(EVENTYPE)
cancer_merged %>% count(EVENTYPE)


# >> Example of same event (EVNTIDX) for treating multiple cancers for same
# person
     
cancer_merged %>% filter(DUPERSID == '2790405102')

     
# De-duplicate on EVNTIDX so we don't count the same event twice
     
cancer_unique <- cancer_merged %>% 
  distinct(DUPERSID, EVNTIDX, .keep_all = T)


# >> Check example person (DUPERSID == '2790405102'):

cancer_unique %>% filter(DUPERSID == '2790405102')


# Aggregate to person-level --------------------------------------------------
     
pers <- cancer_unique %>% 
        group_by(DUPERSID) %>% 
        summarize(pers_ob_exp = sum(OBXP23X), # total person exp. for cancer office visits
        ob_visits = sum(ob_visit))  # total number of cancer office visits
  
# Add person-level indicator variable
     
pers <- pers %>% 
        mutate(any_OB = 1)

# Revisiting our example case at the person level

pers %>% filter(DUPERSID == '2790405102')

# Merge onto FYC file ---------------------------------------------------------
#  >> Need to capture all Strata (VARSTR) and PSUs (VARPSU) for all MEPS sample 
#     persons for correct variance estimation

fyc_cancer <- fyc23x %>% 
  left_join(pers, by = "DUPERSID")  %>% 
  replace_na(list(ob_visits = 0, any_OB = 0, pers_ob_exp = 0)) # replace NA with 0


# QC: should have same number of rows as FYC file

nrow(fyc23x) == nrow(fyc_cancer)

# QC: There should be no records where any_OB=0 and (pers_ob_exp> 0 or ob_visits > 0)

fyc_cancer %>% filter(any_OB==0 & (pers_ob_exp>0 | ob_visits>0))
  
    
# Define the survey design ----------------------------------------------------

meps_dsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT23F,
  data = fyc_cancer,
  nest = TRUE) 


# Calculate estimates ---------------------------------------------------------

# Turn off scientific notation
  
options(digits=15)
  
# National Totals:
  
svytotal(~ any_OB +      # Total people w/ office visit for cancer 
           ob_visits +   # Total number of office visits for cancer 
           pers_ob_exp,  # Total expenditures for office visits for cancer
           design = meps_dsgn)


# Percent of people with office visit for cancer

svymean( ~any_OB,  design = meps_dsgn)  
  
# Average per-person expense for office visits for cancer among people with an
# an office visit for cancer 
  
cancer_ob_dsgn <- subset(meps_dsgn, any_OB == 1)

svymean(~pers_ob_exp, design = cancer_ob_dsgn)


