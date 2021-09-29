

-- drop patient table constraints
if object_id('fk_patient_fact_language_dim', 'f') is not null
	alter table patient_fact 
	drop constraint fk_patient_fact_language_dim;
go

if object_id('fk_patient_fact_race_dim', 'f') is not null
	alter table patient_fact 
	drop constraint fk_patient_fact_race_dim;
go

if object_id('fk_patient_fact_marital_status_dim', 'f') is not null
	alter table patient_fact 
	drop constraint fk_patient_fact_marital_status_dim;
go


-- drop admission table foreign keys
if object_id('fk_admission_fact_patient_fact', 'f') is not null
	alter table admission_fact 
	drop constraint fk_admission_fact_patient_fact;
go


-- drop diagnosis table foreign keys
if object_id('fk_diagnosis_fact_admission_fact', 'f') is not null
	alter table diagnosis_fact 
	drop constraint fk_diagnosis_fact_admission_fact;
go

if object_id('fk_diagnosis_fact_diagnosis_dim', 'f') is not null
	alter table diagnosis_fact 
	drop constraint fk_diagnosis_fact_diagnosis_dim;
go


-- drop lab table foreign keys
if object_id('fk_lab_fact_lab_type_dim', 'f') is not null
	alter table lab_fact 
	drop constraint fk_lab_fact_lab_type_dim;
go



-- drop tables
if object_id('lab_fact', 'u') is not null drop table lab_fact; 
go
if object_id('lab_type_dim', 'u') is not null drop table lab_type_dim; 
go
if object_id('diagnosis_fact', 'u') is not null drop table diagnosis_fact;
go
if object_id('diagnosis_dim', 'u') is not null drop table diagnosis_dim; 
go
if object_id('admission_fact', 'u') is not null drop table admission_fact; 
go
if object_id('patient_fact', 'u') is not null drop table patient_fact; 
go
if object_id('race_dim', 'u') is not null drop table race_dim; 
go
if object_id('marital_status_dim', 'u') is not null drop table marital_status_dim; 
go
if object_id('language_dim', 'u') is not null drop table language_dim; 
go
