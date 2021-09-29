
################################
##  PATIENT TABLE DIMENSIONS  ##
################################

# For the patient table, we'll make dimension tables for the race, gender, 
#   marital status, and language columns.
race_dim <- char_vector_to_dim_table(patients$race, 'race')
marital_status_dim <- char_vector_to_dim_table(patients$marital_status, 'marital_status')
language_dim <- char_vector_to_dim_table(patients$language, 'language')


# creating the patient fact table by replacing the full names with ids
patient_fact <- sqldf('
    select pat.patient_id
        , race.race_id
        , mar.marital_status_id
        , lang.language_id
        , pat.gender_code
        , pat.birth_date
        , pat.percent_below_poverty
    from patients as pat 
    left join race_dim as race
        on pat.race = race.race_name
    left join marital_status_dim as mar
        on pat.marital_status = mar.marital_status_name
    left join language_dim as lang
        on pat.language = lang.language_name
')


# double-check that the join went as expected
assert("No duplicates added to patients",{
    identical(patients_init_nrows, nrow(patient_fact))
})

assert("All race_ids successfully matched", {
    identical(sum(is.na(patient_fact$race_id)), as.integer(0))
})

assert("All marital_status_ids successfully matched", {
    identical(sum(is.na(patient_fact$marital_status_id)), as.integer(0))
})

assert("All language_ids successfully matched", {
    identical(sum(is.na(patient_fact$language_id)), as.integer(0))
})




############################
##  LAB TABLE DIMENSIONS  ##
############################

# create table with all unique tests and units
#   this could be broken down further, but there's only 35 so any marginal  
#   performance improvement would be outweighed by the added complexity
lab_type_dim <- labs %>% 
    select(name, units) %>% 
    distinct() %>% 
    arrange(name) %>%
    tibble::rowid_to_column("lab_type_id") %>%
    rename(lab_type_name = name)

# replace names and units with 'lab_type_id' in the main labs table
lab_fact <- sqldf('
    select labs.lab_id
        , labs.admission_id
        , types.lab_type_id
        , labs.lab_value
        , labs.lab_datetime
    from labs
    left join lab_type_dim types
        on labs.name = types.lab_type_name
')

# double-check that the join went as expected
assert("No duplicates added to labs",{
    identical(labs_init_nrows, nrow(lab_fact))
})

assert("All lab_type_ids successfully matched", {
    identical(sum(is.na(lab_fact$lab_type_id)), as.integer(0))
})




##################################
##  DIAGNOSIS TABLE DIMENSIONS  ##
##################################

# create table with all unique diagnoses, ordered by icd code
diagnosis_dim <- diagnoses %>%
    select(icd10_code, description) %>%
    distinct() %>%
    arrange(icd10_code) 

# the primary key will be the icd10 code, so all we need to do here is remove the 'description'
diagnosis_fact <- diagnoses %>%
    select(-description)




########################
##  ADMISSIONS TABLE  ##
########################

admission_fact <- admissions




#############
#  CLEANUP  #
#############

rm(patients)
rm(labs)
rm(diagnoses)
rm(admissions)
