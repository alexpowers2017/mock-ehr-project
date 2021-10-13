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
  
&nbsp;
### Identify wasteful storage in the current data types
----------------------------
* ```PatientID```
   * Each ID is 36 random numbers and letters, and would have to be saved as ```nchar(36)``` in its current form. 
   * This field will be used to join many tables with 10K+ rows, so it should to be changed to an ```int``` for efficient indexing. 
   * The new ```int``` version will be named ```patient_id```.
   * Storage impact: **1.66 MB &#8594; 0.18 MB** overall (36 bytes &#8594; 4 bytes per ID and it will be in the patients and admissions table - 46,143 total rows)
* ```AdmissionID```
   * This field is not a unique identifier but instead counts the admissions a given patient went through. We currently need both ```PatientID``` and ```AdmissionID``` to find information for a specific admission. It is stored as a ```smallint``` (2 bytes per value).
   * If we create a unique identifier for each admission, it could link the ```admissions``` table to the ```lab``` and ```diagnosis``` tables without using ```PatientID```, and we could use the ```admissions``` table to link back to ```patients```
   * This new field, ```admission_id```, would be an ```int``` and would replace the ```AdmissionID``` and ```PatientID``` in both the ```lab``` and ```diagnosis``` tables.
   * Storage impact: **5.17 MB &#8594; 0.54 MB** (36 + 2 bytes currently stored in 136,149 rows - replaced by 4 bytes in the same number of rows)
* ```AdmissionStartDate```, ```AdmissionEndDate```, and ```LabDateTime```
   * All stored as ```datetime```, which includes seconds and milliseconds. 
   * It's unlikely that any strategic decisions could be affected by a difference of seconds (but I'd check with the client first)
   * So, these will be stored as ```smalldatetime```, which stores date, hours, and minutes in bytes as opposed to 8 bytes for ```datetime``` 
   * Storage impact: **1.38 MB &#8594; 0.69 MB** (172,268 values, one for each lab and two for each admission)
* ```PatientDateOfBirth```
   * This field is stored as a ```datetime```, but there is virtually no utility to knowing the hour, minute, and second a person is born
   * This will be converted to a ```date```, which uses 3 bytes to ```datetime```'s 8.
   * Storage impact: **0.08 MB &#8594; 0.03 MB** (10K values, one for each patient)
* ```PatientGender```
   * The dataset currently stores this as a ```varchar(6)``` with possible values are 'Male' or 'Female'
   * We can replace this with ```gender_code```, ```char(1)``` with 'M', 'F', or 'O' for undefined or other values
   * Storage impact: **0.06 MB &#8594; 0.01 MB**

Just by changing these data types, we can use **1.45 MB** to store what would have taken **8.35 MB**.

This is the new state of the datasets.

![column transformation diagram](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/column_transformations_diagram.JPG)
&nbsp;
### Save storage with dimension tables
----------------------
```patient``` table
* ```PatientRace```, ```PatientMaritalStatus```, and ```PatientLanguage``` each have 4-6 unique text values, each repeated thousands of times. 
* Taking the average length of a ```varchar``` field and adding 1 is a close approximation of the # of bytes used per row (1 byte per character + 1 to store the length itself), so these are some estimates about the total memory used in these columns.
   Column | Avg. length | Est. bytes used | Total memory used in table
   -------|-------------|-----------------|-------------------------
   ```PatientRace``` | 10 | 11 | 0.11 MB
   ```PatientMaritalStatus``` | 7 | 8 | 0.08 MB
   ```PatientLanguage``` | 8 | 9 | 0.09 MB
   **Total** | | | **0.28 MB**
* If we map each of those to a numeric ID, we can create small dimension tables to hold the text values and use ```tinyint``` (1 byte) ID columns in the ```patient``` table to reference those values.
* We'll create three tables, each with two columns:
   * ```race_dim```: ```race_id``` (```tinyint```), ```race_name``` (```varchar(15)```)
   * ```marital_status_dim```: ```marital_status_id``` (```tinyint```), ```marital_status_name``` (```varchar(10)```)
   * ```language_dim```: ```language_id``` (```tinyint```), ```language_name``` (```varchar(10)```)
* Then in the patient table, we'd make the following replacements:
   * ```PatientRace``` &#8594; ```race_id```
   * ```PatientMaritalStatus``` &#8594; ```marital_status_id```
   * ```PatientLanguage``` &#8594; ```language_id```

   Storage estimates for this method would be:

   Table | Column | Est. bytes used | Total memory used in table
   ------|--------|-----------------|----------------------------
   ```patient``` | ```race_id``` | 1 | 0.01 MB
   ```patient``` | ```language_id``` | 1 | 0.01 MB
   ```patient``` | ```marital_status_id``` | 1 | 0.01 MB
   ```race_dim``` | ```race_id``` | 1 | 0.000004 MB
   ```race_dim``` | ```race_name``` | 15 | 0.00006 MB
   ```race_dim``` | table overhead | 276 bytes | 0.00028 MB
   ```marital_status_dim``` | ```marital_status_id``` | 1 | 0.000006 MB
   ```marital_status_dim``` | ```marital_status_name``` | 10 | 0.00006 MB
   ```marital_status_dim``` | table overhead | 276 bytes | 0.00028 MB
   ```language_dim``` | ```language_id``` | 1 | 0.000004 MB
   ```language_dim``` | ```language_name``` | 10 | 0.00004 MB
   ```language_dim``` | table overhead | 276 bytes | 0.00028 MB
   **Total** | | | **0.03 MB**
* So the total storage difference is **0.28 MB** &#8594; **0.03 MB**
   * It may seem like a lot of work to save 0.2 MB, but the new method uses a 10th the space and this gap will grow continuously larger as more rows are added to the ```patient``` table
   

   

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
