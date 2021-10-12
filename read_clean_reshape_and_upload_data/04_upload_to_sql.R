

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

# populate lab_type_dim
dbWriteTable(
    sql_connection,
    'lab_type_dim',
    lab_type_dim,
    append=TRUE
)

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

# populate diagnosis_dim
dbWriteTable(
    sql_connection,
    'diagnosis_dim',
    diagnosis_dim,
    append=TRUE
)



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

# populate admission_fact
dbWriteTable(
    sql_connection,
    'admission_fact',
    admission_fact,
    append=TRUE
)

# populate lab_fact
dbWriteTable(
    sql_connection,
    'lab_fact',
    lab_fact,
    append=TRUE
)

# populate diagnosis_fact
dbWriteTable(
    sql_connection,
    'diagnosis_fact',
    diagnosis_fact,
    append=TRUE
)

