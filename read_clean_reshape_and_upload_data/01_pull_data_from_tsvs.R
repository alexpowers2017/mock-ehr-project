
# files that we expect to be in the data folder
expected_filenames <- c(
  "AdmissionsCorePopulatedTable.txt",
  "AdmissionsDiagnosesCorePopulatedTable.txt",
  "LabsCorePopulatedTable.txt",
  "PatientCorePopulatedTable.txt" 
)

# character vector of filenames in data folder, in alphabetical order
actual_filenames <- str_sort(list.files())

# throws error if contents of 'data' folder don't match what is expected - does nothing if test passes
assert("All required files are present in 'data' folder",{
  identical(expected_filenames, actual_filenames)
})

# remove variables that won't be used in the future
rm(actual_filenames)
rm(expected_filenames)



############################
##  READ DATA FROM FILES  ##
############################

# The 'tibble::rownames_to_column' function pulls the row numbers into a column
#   This will be used as the primary key when necessary
#   Then, the columns are renamed for brevity, clarity, or my own preference

patients_pull <- read.delim("PatientCorePopulatedTable.txt", stringsAsFactors = FALSE) %>%
  tibble::rownames_to_column(var="patient_id") %>%
  rename( patient_id_old = ï..PatientID,
          gender = PatientGender,
          birth_date = PatientDateOfBirth,
          race = PatientRace,
          marital_status = PatientMaritalStatus,
          language = PatientLanguage,
          percent_below_poverty = PatientPopulationPercentageBelowPoverty ) 


admissions_pull <- read.delim("AdmissionsCorePopulatedTable.txt", stringsAsFactors = FALSE) %>%
  tibble::rownames_to_column(var="admission_id") %>%
  rename( patient_id_old = ï..PatientID,
          admission_id_old = AdmissionID,
          start_time = AdmissionStartDate,
          end_time = AdmissionEndDate ) 

# select statement used because some blank columns are read into this data frame 
diagnoses_pull <- read.delim("AdmissionsDiagnosesCorePopulatedTable.txt", stringsAsFactors = FALSE) %>%
  rename(
    patient_id_old = PatientID,
    admission_id_old = AdmissionID,
    icd10_code = PrimaryDiagnosisCode,
    description = PrimaryDiagnosisDescription
  ) %>%
  select (
    patient_id_old,
    admission_id_old,
    icd10_code,
    description
  ) 

# Taking 100K rows out of 10M for convenience/speed because this is just a demo
labs_pull <- read.delim("LabsCorePopulatedTable.txt", nrows = 100000, stringsAsFactors = FALSE) %>%
  tibble::rownames_to_column(var="lab_id") %>%
  rename(
    patient_id_old = ï..PatientID,
    admission_id_old = AdmissionID,
    name = LabName,
    lab_value = LabValue,
    units = LabUnits,
    lab_datetime = LabDateTime
  )


# get initial row counts to watch for duplication or dropping of rows
patients_init_nrows <- nrow(patients_pull)
admissions_init_nrows <- nrow(admissions_pull)
diagnoses_init_nrows <- nrow(diagnoses_pull)
labs_init_nrows <- nrow(labs_pull)

