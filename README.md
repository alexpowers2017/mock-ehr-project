# Mock EHR Database

&nbsp;

## Contents

1. [About](#about)
2. [Design Data Warehouse](#design-data-warehouse)
3. [Create SQL Tables](#create-sql-tables)
   1. [Patient Dimension Tables](#patient-dimension-tables)
   2. [Patient Fact Table](#patient-fact-table)
4. [ETL](#etl) 
   1. [Pull from source file](#pull-from-source-file)
   2. [Replace patient and admission IDs](#replace-patient-and-admission-ids)
   3. [Create Dimension Tables](#create-dimension-tables)
   4. [Upload to SQL](#upload-to-sql)
5. Tableau visualizations/dashboards (in progress)


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

### Final Entity Relationship Diagram
----------------------

![Final Data Warehouse Diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Final%20DW%20Diagram.JPG?raw=true)

Detailed overview of optimization located in [database optimization](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/database%20optimization.md) file.
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
-- with a new definition, the foreign key references could be a problem. We'll drop them first

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
