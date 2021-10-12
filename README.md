# Mock EHR Database

### About
This project uses randomized sample EHR data to create an end-to-end business intelligence solution. It was created to serve two purposes:
* A portfolio project for me
* An open-source sample EHR database for me and anyone interested to use as a sandbox while developing healthcare BI or software solutions


### Source Data
The EHR dummy data is provided by Stockato, LLC at [emrbots.org](http://www.emrbots.org). This dataset contains 10,000 patients with admissions, diagnosis, and labs data for each. The data itself is in tab-delimited text files, which come in a zip folder, downloaded from the above website. The files I used are available in the [input_data](/input_data) folder for reference.


### Tasks
1. Design Data Warehouse
2. Create SQL Tables
3. Implement ETL 
4. Incorporate additional data sources
5. Create detailed views
6. Create interactive visualizations or dashboards (in progress)


## Design Data Warehouse
Map out the structure of the input data
![Input data diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Input%20data%20diagram.JPG?raw=true)

Table | # Rows | Original Name (above)
------|------|------
Patients | 10,000 | PatientCorePopulatedTable
Admissions | 36,143 | AdmissionsCorePopulatedTable
Lab | 100,000 | LabsCorePopulatedTable
Diagnosis | 36,143 | DiagnosisCorePopulatedTable

#### Identify wasteful storage in the current data types
* ```PatientID```
   * Each ID is 36 random numbers and letters, and would have to be saved as ```nchar(36)``` in its current form. 
   * This field will be used to join many tables with 10K+ rows, so it should to be changed to an ```int``` for efficient indexing. 
   * Storage impact: **1.66MB &#8594; 0.18MB** overall (36 bytes &#8594; 4 bytes per ID and it will be in the patients and admissions table - 46,143 total rows)
* ```AdmissionStartDate```, ```AdmissionEndDate```, and ```LabDateTime```
   * All stored as ```datetime```, which includes seconds and milliseconds. 
   * It's unlikely that any strategic decisions could be affected by a difference of seconds (but I'd check with the client first)
   * So, these will be stored as ```smalldatetime```, which stores date, hours, and minutes in bytes as opposed to 8 bytes for ```datetime``` 
   * Storage impact: **1.38MB &#8594; 0.69MB** (172,268 values, one for each lab and two for each admission)
* ```PatientDateOfBirth```
   * This field is stored as a ```datetime```, but there is virtually no utility to knowing the hour, minute, and second a person is born
   * This will be converted to a ```date```, which uses 3 bytes to ```datetime```'s 8.
   * Storage impact: **0.08MB &#8594; 0.03MB** (10K values, one for each patient)

#### Increase efficiency through *dimension tables*

#### Design Data Warehouse
* Designed as Snowflake Schema DW
* [Diagram of final Data Warehouse Design](/documentation/Final%20Data%20Warehouse%20Diagram.pdf)

   
#### Create SQL Tables
* Designed as Snowflake Schema DW
   * Scripts located in [sql_scripts](/sql_scripts) folder.
#### ETL
* [Diagram of transformations required to_input_data](/documentation/Data%20Transformations.pdf)
   * Tool used: R
   * 
   * Scripts located in the [read_clean_reshape_and_upload_data](/read_clean_reshape_and_upload_data) folder
5. Create reference tables for expected lab values
   * This will allow us to gain real insights from the patients' lab scores
   * High-quality sources were used, but interpreting lab scores requires a physician's expertise. This is for academic purposes only.
   * Script located at [create lab values table.sql](/sql_scripts/create%20lab%20values%20table.sql)
7. Create interactive visualizations with Tableau or Shiny to quickly glean insights from data*
   * ***IN PROGRESS**
