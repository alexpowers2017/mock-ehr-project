
###############################
##  MATCH NEW INT ID FIELDS  ##
###############################


# add int patient ID to admissions data frame
admissions <- left_join(admissions_pull, patients_pull, by='patient_id_old') %>%
    select( admission_id,
            patient_id,
            start_time,
            end_time,
            admission_id_old,
            patient_id_old )

# Now the admissions data frame has both patient and admission IDs, and can be used 
# to add both IDs to the diagnoses and labs data frames


# add patient IDs and admission IDs to diagnoses data frame
diagnoses <- left_join(diagnoses_pull, admissions, by=c('patient_id_old', 'admission_id_old')) %>%
    select( admission_id,
            icd10_code,
            description )


# add patient IDs and admission IDs to labs data frame
labs <- left_join(labs_pull, admissions, by=c('patient_id_old', 'admission_id_old')) %>%
    select( lab_id,
            patient_id,
            admission_id,
            name,
            lab_value,
            units,
            lab_datetime )

# replace gender with gender code and remove old patient id field
patients <- patients_pull %>%
    mutate(gender_code=get_gender_code(gender)) %>%
    select(-c(gender, patient_id_old))

# replace old admission and patient ids in admissions data frame
admissions <- admissions %>%
    select(-c(admission_id_old, patient_id_old))



#####################
#  DATES AND TIMES  #
#####################

# change birth date column from datetime to date
patients <- patients %>% 
    mutate(birth_date = date_only(birth_date))

# remove seconds and milliseconds from admission start/end time columns 
admissions <- admissions %>% 
    mutate(start_time = datetime_trunc_minutes(start_time)) %>%
    mutate(end_time = datetime_trunc_minutes(end_time))

# remove seconds and milliseconds from lab datetime column
labs <- labs %>% 
    mutate(lab_datetime = datetime_trunc_minutes(lab_datetime))



################
#  VALIDATION  #
################


# make sure no duplicates were added in these joins
assert("No duplicates added to patients",{
    identical(patients_init_nrows, nrow(patients))
})

assert("No duplicates added to admissions",{
    identical(admissions_init_nrows, nrow(admissions))
})

assert("No duplicates added to diagnoses",{
    identical(diagnoses_init_nrows, nrow(diagnoses))
})

assert("No duplicates added to labs",{
    identical(labs_init_nrows, nrow(labs))
})


# delete initial pull dataframes to save space 
rm(patients_pull)
rm(admissions_pull)
rm(diagnoses_pull)
rm(labs_pull)



