# mock-ehr-project
 This project uses randomized sample EHR data to create an end-to-end business intelligence solution.


##### Source Data
The EHR dummy data is provided by Stockato, LLC at http://www.emrbots.org. This dataset contains 10,000 patients with admissions, diagnosis, and labs data for each. The data itself is in tab-delimited text files, which come in a zip folder, downloaded from the above website. 


### Tasks
1. Understand source data structure and design efficient data warehouse to hold the information
   * [Diagram of input data structure](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Input%20Data%20Diagram.pdf)
   * [Diagram of final Data Warehouse Design](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Final%20Data%20Warehouse%20Diagram.pdf)
   * [Diagram of transformations required to_input_data](https://github.com/alexpowers2017/mock-ehr-project/blob/main/documentation/Data%20Transformations.pdf)
3. Create the tables in SQL Server
   * Designed as Snowflake Schema DW
   * Scripts located in [sql_scripts](https://github.com/alexpowers2017/mock-ehr-project/tree/main/sql_scripts) folder.
4. Bring data from flat files into database
   * Accomplished with R
   * Scripts located in the [read_clean_reshape_and_upload_data](https://github.com/alexpowers2017/mock-ehr-project/tree/main/read_clean_reshape_and_upload_data) folder
5. Create interactive visualizations with Tableau or Shiny to quickly glean insights from data*
   * ***IN PROGRESS**
