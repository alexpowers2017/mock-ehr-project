# Mock EHR Database

&nbsp;

## Contents

1. [About](#about)
2. [Design Data Warehouse](#design-data-warehouse)
   1. [Optimize Data Types](#optimize-data-types)
   2. [Patient Dimension Tables](#patient-dimension-tables)
   3. [Diagnosis Dimension Tables](#diagnosis-dimension-tables)
   4. [Lab Dimension Tables](#lab-dimension-tables)
   5. [Final Entity Relationship Diagram](#final-entity-relationship-diagram)
   6. [Limitations, design decisions, and potential improvements](#limitations-design-decisions-and-potential-improvements)
2. [Create SQL Tables](#create-sql-tables)
   1. [Patient Dimension Tables](#patient-dimension-tables)
   2. [Patient Fact Table](#patient-fact-table)
3. [ETL](#etl) 
   1. [Pull from source file](#pull-from-source-file)
   2. [Replace patient and admission IDs](#replace-patient-and-admission-ids)
   3. [Create Dimension Tables](#create-dimension-tables)
   4. [Upload to SQL](#upload-to-sql)
4. Tableau visualizations/dashboards (in progress)


&nbsp;

## About
This project uses randomized sample EHR data to create an end-to-end business intelligence solution. It was created to serve two purposes:
* A portfolio project for me
* An open-source sample EHR database for me and anyone interested to use while developing healthcare BI or software solutions

&nbsp;

### Source Data
----------------------------
The EHR dummy data is provided by Stockato, LLC at [emrbots.org](http://www.emrbots.org). 
* It contains 10,000 patients with admissions, diagnosis, and labs data for each. 
* The data itself is in tab-delimited text files, which come in a zip folder, downloaded from the above website. 
* The files I used are available in the [input_data](/input_data) folder for reference.

&nbsp;

## Design Data Warehouse

Structure of the input data:
![Input data diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Input%20data%20diagram.JPG?raw=true)

Table | # Rows | Original Name (above)
------|------|------
Patients | 10,000 | PatientCorePopulatedTable
Admissions | 36,143 | AdmissionsCorePopulatedTable
Lab | 100,000 | LabsCorePopulatedTable
Diagnosis | 36,143 | DiagnosisCorePopulatedTable
  
&nbsp;

### Optimize Data Types
----------------------------

```PatientID```
* Each ID is 36 random numbers and letters, and would have to be saved as ```nchar(36)``` in its current form. 
* This field will be used to join many tables with 10K+ rows, so it should to be changed to an ```int``` for efficient indexing. 
* The new ```int``` version will be named ```patient_id```.
* Storage impact: **1.66 MB &#8594; 0.18 MB** overall 
   * 36 bytes &#8594; 4 bytes per ID and it will be in the patients and admissions table - 46,143 total rows

```AdmissionID```
* This field is not a unique identifier but instead counts the admissions a given patient went through. We currently need both ```PatientID``` and ```AdmissionID``` to find information for a specific admission. It is stored as a ```smallint``` (2 bytes per value).
* If we create a unique identifier for each admission, it could link the ```admissions``` table to the ```lab``` and ```diagnosis``` tables without using ```PatientID```, and we could use the ```admissions``` table to link back to ```patients```
* This new field, ```admission_id```, would be an ```int``` and would replace the ```AdmissionID``` and ```PatientID``` in both the ```lab``` and ```diagnosis``` tables.
* Storage impact: **5.17 MB &#8594; 0.54 MB** 
   * 36 + 2 bytes currently stored in 136,149 rows - replaced by 4 bytes in the same number of rows

```AdmissionStartDate```, ```AdmissionEndDate```, and ```LabDateTime```
* All stored as ```datetime```, which includes seconds and milliseconds. 
* It's unlikely that any strategic decisions could be affected by a difference of seconds (but I'd check with the client first)
* So, these will be stored as ```smalldatetime```, which stores date, hours, and minutes in bytes as opposed to 8 bytes for ```datetime``` 
* Storage impact: **1.38 MB &#8594; 0.69 MB** (172,268 values, one for each lab and two for each admission)

```PatientDateOfBirth```
* This field is stored as a ```datetime```, but there is virtually no utility to knowing the hour, minute, and second a person is born
* This will be converted to a ```date```, which uses 3 bytes to ```datetime```'s 8.
* Storage impact: **0.08 MB &#8594; 0.03 MB** 
   * 10K values, one for each patient

```PatientGender```
* The dataset currently stores this as a ```varchar(6)``` with possible values are 'Male' or 'Female'
* We can replace this with ```gender_code```, ```char(1)``` with 'M', 'F', or 'O' for undefined or other values
* Storage impact: **0.06 MB &#8594; 0.01 MB**

Just by changing these data types, we can use **1.45 MB** to store what would have taken **8.35 MB**.

This is the new structure of the datasets.

![column transformation diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/column_transformations_diagram.JPG)
&nbsp;


### Patient Dimension Tables
----------------------
Current structure of the patient data:

![Patient table current state](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/patient_table_columns_transformed.JPG?raw=true)

```PatientRace```, ```PatientMaritalStatus```, and ```PatientLanguage``` each have 4-6 unique text values, each repeated thousands of times. 

Taking the average length of a ```varchar``` field and adding 1 is a close approximation of the # of bytes used per row (1 byte per character + 1 to store the length itself), so these are the estimates for the total memory used in these columns.

   Column | Avg. length | Est. bytes used | # Rows | Total storage used
   -------|-------------|-----------------|---------|----------------
   ```PatientRace``` | 10 | 11 | 10K | 0.11 MB
   ```PatientMaritalStatus``` | 7 | 8 | 10K | 0.08 MB
   ```PatientLanguage``` | 8 | 9 | 10K | 0.09 MB
   **Total** | | | |  **0.28 MB**
 
If we map each of those to a numeric ID, we can create small dimension tables to hold the text values and use ```tinyint``` (1 byte) ID columns in the ```patient``` table to reference those values.

We'll create three tables, each with two columns:
* ```race_dim```: ```race_id``` (```tinyint```), ```race_name``` (```varchar(15)```)
* ```marital_status_dim```: ```marital_status_id``` (```tinyint```), ```marital_status_name``` (```varchar(10)```)
* ```language_dim```: ```language_id``` (```tinyint```), ```language_name``` (```varchar(10)```)

Then in the patient table, we'd make the following replacements:
* ```PatientRace``` &#8594; ```race_id```
* ```PatientMaritalStatus``` &#8594; ```marital_status_id```
* ```PatientLanguage``` &#8594; ```language_id```

   Storage estimates for this method:

   Table | Column | Est. bytes used | # Rows | Total storage used
   ------|--------|-----------------|---------|-------------------
   ```patient_fact``` | ```race_id``` | 1 | 10K | 0.01 MB
   ```patient_fact``` | ```language_id``` | 1 | 10K | 0.01 MB
   ```patient_fact``` | ```marital_status_id``` | 1 | 10K | 0.01 MB
   ```race_dim``` | ```race_id``` | 1 | 4 | 0.000004 MB
   ```race_dim``` | ```race_name``` | 15 | 4 | 0.00006 MB
   ```race_dim``` | table overhead | 276 |  | 0.00028 MB
   ```marital_status_dim``` | ```marital_status_id``` | 1 | 6 | 0.000006 MB
   ```marital_status_dim``` | ```marital_status_name``` | 10 | 6 | 0.00006 MB
   ```marital_status_dim``` | table overhead | 276 |  | 0.00028 MB
   ```language_dim``` | ```language_id``` | 1 | 4 | 0.000004 MB
   ```language_dim``` | ```language_name``` | 10 | 4 | 0.00004 MB
   ```language_dim``` | table overhead | 276 |  | 0.00028 MB
   **Total** | | | | **0.03 MB**
So the total storage difference is **0.28 MB** &#8594; **0.03 MB**
* It may seem like a lot of work to save 0.2 MB, but the new method uses 1/10 the space and this gap will grow as more rows are added

New structure of the patient data:

![Patient table transformation](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/patient_table_transformation.JPG)

&nbsp;

### Diagnosis Dimension Tables
----------------------
Current structure of the diagnosis data:

![Diagnosis table current state](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/diagnosis_table_columns_transformed.JPG?raw=true)

```PrimaryDiagnosisCode``` is a standardized ICD-10 code and a given code will always have the same corresponding description.
There are 36,143 rows in ```Diagnosis``` but only 2,625 unique ```PrimaryDiagnosisCode```:```PrimaryDiagnosisDescription``` pairs

   Storage estimates for the current data:
   Column | Avg. length | Est. bytes used | # rows | Total storage used
   -------|-------------|-----------------|---------|-----------------
   ```PrimaryDiagnosisCode``` | 50 | 51 | 36,143 | 1.8 MB
   ```PrimaryDiagnosisDescription``` | 5 | 6 | 36,143 | 0.22 MB
   **Total** | | | |  **2.02 MB**

We'll then move the descriptions to a dimension table named ```diagnosis_dim```, referenced by the ICD-10 code.
   Storage estimates for this method:
   Table | Column | Est. bytes used | # Rows | Total storage used
   ------|--------|-----------------|---------|-------------------
   ```diagnosis_fact``` | ```icd10_code``` | 6 | 36,143 | 0.22 MB
   ```diagnosis_dim``` | ```icd10_code``` | 6 | 2625 | 0.02 MB
   ```diagnosis_dim``` | ```description``` | 51 | 2625 | 0.13 MB
   ```diagnosis_dim``` | table overhead | 276 |  | 0.00028 MB
   **Total** | | | |  **0.37 MB**
 
The total storage difference is **2.02 MB** &#8594; **0.37 MB**


New structure of the diagnosis data:

![Diagnosis table transformation](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/diagnosis_table_transformation.JPG)

&nbsp;

### Lab Dimension Tables
----------------------
Current structure of the lab data:

![Lab table current state](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/lab_table_columns_transformed.JPG?raw=true)

The ```admission_id```, ```LabValue```, and ```LabDateTime``` fields should be unique to each row, so we'll leave them alone
However, there are only 35 unique values for ```LabName``` and 13 unique values for ```LabUnits```, with the same units always used for the same lab type

   Storage estimates for the current data:
   Column | Avg. length | Est. bytes used | # rows | Total storage used
   -------|-------------|-----------------|---------|-----------------
   ```LabName``` | 19 | 20 | 100K | 2.0 MB
   ```LabUnits``` | 4 | 5 | 100K | 0.5 MB
   **Total** | | | |  **2.5 MB**

We can create a dimension table called ```lab_type_dim``` with one row for each lab type (35 total)
* The unique identifier will be ```lab_type_id```, a ```tinyint``` column which will be added to the ```lab``` table
* The table will also include ```units``` and ```lab_type_name``` from the original ```lab``` table

   Storage estimates for this method:
   Table | Column | Est. bytes used | # Rows | Total storage used
   ------|--------|-----------------|---------|-------------------
   ```lab_fact``` | ```lab_type_id``` | 1 | 100K | 0.1 MB
   ```lab_type_dim``` | ```lab_type_id``` | 1 | 35 | 0.000035 MB
   ```lab_type_dim``` | ```lab_type_name``` | 20 | 35 | 0.0007 MB
   ```lab_type_dim``` | ```units``` | 1 | 5 | 0.000175 MB
   ```race_dim``` | table overhead | 276 |  | 0.00028 MB
   **Total** | | | | **0.101 MB**

The total storage difference is **2.5 MB** &#8594; **0.101 MB**

New structure of the labs data:

![Lab table transformation](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/lab_data_new_structure.JPG?raw=true)

&nbsp;

### Final Entity Relationship Diagram
----------------------

![Final Data Warehouse Diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Final%20DW%20Diagram.JPG?raw=true)

This diagram includes two new lab tables mentioned in the section below

&nbsp;

### Limitations, design decisions, and potential improvements
----------------------

```Diagnosis``` table
* The ICD-10 code isn't necessarily the most efficient field to use as a primary key.
   * We could replace it with a ```smallint``` ID to save some space and slightly speed up joins. 
   * However, it's already a domain-wide unique identifier for diagnoses, so using it as the primary key is intuitive to any new user. 
   * I think that's worth trading a little efficiency for.
* In the data's current state, the most efficient design would be to add the diagnosis code to the ```admission``` table
   * From there, it could directly reference the ```diagnosis_dim``` table
   * I kept them separated because I'd like this design to eventually be able to handle multiple diagnoses per admission
* ICD-10 codes are, by design, grouped into clinically meaningful categories, but we're not leveraging that yet
   * A useful improvement would be to change the source of the ```diagnosis_dim``` table to an official list of ICD-10 codes
   * We could then include columns for chapter, diagnosis group, and other, broader categories that may be more useful for reporting

```Lab``` table
* This exemplifies the difference between *data* and *information*. We have 100K data points showing scores for different labs, but no idea what any of them mean.
   * A new table will be added matching labs to their expected normal ranges, allowing us to glean real insights from the data
* The units are, in their current state, ugly and confusing
   * Some of the abbreviations used are correct, but uncommon and may not be understood at first glance
   *  A small, 13-row table mapping units to their full names could make reports based on this data much easier to understand

&nbsp;
   
## Create SQL Tables

Scripts located in [sql_scripts](/sql_scripts) folder.

These tables were created in an Azure SQL database using SQL Server Management Studio. There is still a relatively small # of tables and no reason to limit access, so no schemas were used and everything will be created in the 'dbo' schema by default. 

We've already gone through the design of all of the tables, so I'll just include one fact/dim group here.

&nbsp;

### Patient Dimension tables
------------------------------
```SQL
-- If the tables already exist in the database and these scripts are being run to replace them  
-- with a new definition, the foreign key referemces could be a problem. We'll drop them first

if object_id('fk_patient_fact_language_dim', 'f') is not null
	alter table [patient_fact]
	drop constraint [fk_patient_fact_language_dim];
go

if object_id('fk_patient_fact_race_dim', 'f') is not null
	alter table [patient_fact] 
	drop constraint [fk_patient_fact_race_dim];
go

if object_id('fk_patient_fact_marital_status_dim', 'f') is not null
	alter table [patient_fact] 
	drop constraint [fk_patient_fact_marital_status_dim];
go



-- Then we'll drop the dimension tables if they exist
if object_id('race_dim', 'u') is not null
	drop table [race_dim];
go

if object_id('marital_status_dim', 'u') is not null
	drop table [marital_status_dim];
go

if object_id('language_dim', 'u') is not null
	drop table [language_dim];
go



-- Now that the coast is clear, we'll create the tables as defined in the Data Warehouse Design section
create table [race_dim] (
	[race_id] (tinyint) not null,
	[race_name] (varchar(30)) not null,

	constraint [pk_race_dim] primary key ([race_id])
); 
go

create table [marital_status_dim] (
	[marital_status_id] (tinyint) not null,
	[marital_status_name] (varchar(10)) not null,

	constraint [pk_marital_status_dim] primary key ([marital_status_id])
);
go

create table [language_dim] (
	[language_id] (tinyint) not null,
	[language_name] (varchar(10)) not null,

	constraint [pk_language_dim] primary key ([language_id])
);
go
```

&nbsp;

### Patient Fact table
------------------------------
```SQL
-- First, drop the table if it exists
-- Once the table is full and in use, an 'alter table' command would be a more appropriate approach

if object_id('patient_fact', 'u') is not null
	drop table [patient_fact];
go


create table [patient_fact] (
	[patient_id] int not null,
	[race_id] tinyint not null,
	[marital_status_id] tinyint not null,
	[language_id] tinyint not null,
	[gender_code] char(1) not null,
	[birth_date] date,
	[percent_below_poverty] decimal(10, 2),

   -- these could be assigned in the column definitions, but this is at an early enough stage where I may need to drop/alter the constraints
   -- naming them makes it way easier to do that
	constraint [pk_patient_fact] primary key ([patient_id]),
	constraint [fk_patient_fact_race_dim] foreign key ([race_id]) references [race_dim]([race_id]),
	constraint [fk_patient_fact_marital_status_dim] foreign key ([marital_status_id]) references [marital_status_dim]([marital_status_id]),
	constraint [fk_patient_fact_language_dim] foreign key ([language_id]) references [language_dim]([language_id])
); 
go

-- if you were wondering, I write my SQL all lowercase because I am a rebel at heart
```


&nbsp;

## ETL

The ETL was implemented in R. Scripts located at [read_clean_reshape_and_upload_data](/read_clean_reshape_and_upload_data).

For brevity, I'll again mostly focus on the patient data.

&nbsp;

### Pull from source file
-------------------------
When reading in the patient data, the existing ```PatientID``` is read in as ```patient_id_old``` and the row number is read in as ```patient_id```.

```R
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

# get initial row counts to watch for duplication or dropping of rows
patients_init_nrows <- nrow(patients_pull)
```

This method really only works for the first transfer.
* If new data were to be uploaded on an ongoing basis, a separate table mapping ```patient_id``` to ```patient_id_old``` would have to be created and saved to SQL.
* Then, new patient records would have to be checked against that table and assigned the appropriate ```patient_id```, or a new one would be added if it doesn't exist.

&nbsp;

### Replace patient and admission IDs
------------------------------------

When reading in the admissions data, I used the same method of reading in the row number as ```admission_id```.

I could then use the original ```patient_id_old``` to add the new ```patient_id``` to the admissions dataset.

From there, I could use the original ```patient_id_old``` and the original ```admission_id_old``` together to add the new ```admission_id``` to the lab and diagnosis datasets.

```R
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
```

&nbsp;

### Create Dimension Tables
---------------------------
Creating a dimension table from scratch is just a matter of taking the unique values and assigning each a numeric id.

This function did most of the work towards creating the dimension tables.

```R
char_vector_to_dim_table <- function(char_vect, var_name) {
    
    #   Takes a character vector and returns a data frame with all unique values 
    #   and an ID field. 
    #
    #   Arguments
    #   ------------
    #   char_vect : character  
    #       All values in the target column in the original data frame
    #   var_name : character  
    #       What you want the final name of the target variable to be.
    #
    #   Return Value
    #   -------------
    #   dim_table : data frame
    #       Dimension table with one row for each unique value in the input 
    #       vector. There will be an ID column and a name column, named
    #       "*var_name*_id" and "*var_name*_name", respectively.
    
    id_colname <- paste(var_name, '_id', sep='')
    
    unique_vect <- unique(char_vect) 
    
    raw_dim_df <- data.frame(unique_vect) %>%
        mutate("{var_name}_name" := unique_vect) %>%
        tibble::rownames_to_column(var=id_colname)
    
    dim_table <- raw_dim_df %>%
        select(-unique_vect)   
    
    return(dim_table)
}
```

The functions were then fed the appropriate vectors and the resultant data frames were joined back to the main patients table.

```R
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
```

&nbsp;

### Upload to SQL
---------------------------
I used the ```ODBC``` package to connect to the database and inserted the values using the ```dbWriteTable``` function.

Dimension tables were populated before Fact tables to avoid issues with the foreign key restraints.

```R
sql_connection <- dbConnect(odbc(),
    Driver = "ODBC Driver 17 for SQL Server",
    Server = "SQL Server url",
    Database = "database",
    UID = "userid",
    PWD = "password",
    Port = 1433)



#########################
#  POPULATE DIM TABLES  #
#########################

# populate race_dim
dbWriteTable(
    sql_connection,
    'race_dim',
    race_dim,
    append=TRUE
)

# populate language_dim
dbWriteTable(
    sql_connection,
    'language_dim',
    language_dim,
    append=TRUE
)

# populate marital_status_dim
dbWriteTable(
    sql_connection,
    'marital_status_dim',
    marital_status_dim,
    append=TRUE
)

# ...



##########################
#  POPULATE FACT TABLES  #
##########################

# populate patient_fact
dbWriteTable(
    sql_connection,
    'patient_fact',
    patient_fact,
    append=TRUE
)
```

&nbsp;
&nbsp;
&nbsp;

## THE END
That's all, folks
