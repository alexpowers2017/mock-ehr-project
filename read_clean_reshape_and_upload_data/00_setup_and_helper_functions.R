
################################################################################
#
#
#   TITLE:      Sample EHR Data Warehouse
#
#
#   AUTHOR:     Alex Powers
#               alexpowers2017@gmail.com
#  
#
#   SUMMARY:    This program uses dummy EHR data to create an EHR data warehouse.
#  
#                 
#   SOURCE:     The EHR dummy data is provided by Stockato, LLC at
#               http://www.emrbots.org. This dataset contains 10,000 patients,
#               with admissions, diagnosis, and labs data for each. The data 
#               itself is in tab-delimited text files, which come in a zip 
#               folder, downloaded from the above website. 
#
#
#   RECREATION: To run this program, the .txt files from emrbots.org must
#               be placed in a folder titled 'input_data' adjacent to the 
#               folder containing this program. 
#               
#               The following R packages must be installed on the machine being  
#               used: dplyr, stringr, testit, sqldf, odbc.
#
#               The SQL database must be set up on a server accessible to 
#               the user. This can be accomplished by connecting to a SQL 
#               Server database and running all of the scripts in the folder
#               titled 'sql_scripts'. 
#
#
################################################################################



###########
#  SETUP  #
###########

setwd("../input_data")

# load required packages
required_packages <- c('dplyr', 'testit', 'stringr', 'sqldf', 'odbc')
lapply(required_packages, require, character.only = TRUE)

rm(required_packages)


######################
#  HELPER FUNCTIONS  #
######################

date_only <- function(date_char) {
    
    #   Takes a datetime string and converts it to a date
    #
    #   Arguments
    #   --------------
    #   date_char : character (ex. "1975-01-04 14:49:59.587")
    #       datetime as a string, as read in from the raw tsv files
    #
    #   Return Value
    #   --------------
    #   date : POSIXct
    #       Date only as POSIXct (numeric date class)
    
    date_POSIXlt <- strptime(date_char, format="%Y-%m-%d")
    date_POSIXct <- as.POSIXct(date_POSIXlt)
    date <- as.Date(date_POSIXct)
    return(date)
}


datetime_trunc_minutes <- function(date_char) {
    
    #   Takes a datetime string and converts it to a datetime 
    #
    #   Arguments
    #   --------------
    #   date_char : character (ex. "1975-01-04 14:49:59.587")
    #       datetime as a string, as read in from the raw tsv files
    #
    #   Return Value
    #   --------------
    #   datetime : POSIXct
    #       Datetime with seconds and milliseconds removed
    #
    #   This will help the datetimes fit neatly into smalldatetime fields in
    #   SQL Server, cutting the size roughly in half 
    
    date_POSIXlt <- strptime(date_char, format="%Y-%m-%d %H:%M")
    datetime <- as.POSIXct(date_POSIXlt)
    return(datetime)
}


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


get_gender_code <- function(gender_name) {
    
    #   Takes a gender value and outputs a 1-character code
    #
    #   Arguments
    #   ------------
    #   gender_name : character
    #       value in the gender field in the 'patients' table. Usually 'Male'
    #       or 'Female', but I added some validation and other options to be safe
    #
    #   Return Value
    #   -------------
    #   gender_code : character
    #       One-character code for gender, either "M", "F", or "O", with "O" as
    #       a catch-all for any values not mapped to "male" or "female"
    
    gender_cleaned <- tolower(trimws(gender_name))
    
    gender_code <-  ifelse(gender_cleaned == 'male', 'M',
                    ifelse(gender_cleaned == 'm', 'M',
                    ifelse(gender_cleaned == 'female', 'F',
                    ifelse(gender_cleaned == 'f', 'F',  
                    'O')))) 
    
    return(gender_code)
}
