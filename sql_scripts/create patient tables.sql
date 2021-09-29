
if object_id('patient_fact', 'u') is not null
	drop table patient_fact;
go

if object_id('race_dim', 'u') is not null
	drop table race_dim;
go

if object_id('marital_status_dim', 'u') is not null
	drop table marital_status_dim;
go

if object_id('language_dim', 'u') is not null
	drop table language_dim;
go





create table race_dim (
	race_id tinyint not null,
	race_name varchar(30) not null,

	constraint pk_race_dim primary key (race_id)
); 
go


create table marital_status_dim (
	marital_status_id tinyint not null,
	marital_status_name varchar(10) not null,

	constraint pk_marital_status_dim primary key (marital_status_id)
);
go


create table language_dim (
	language_id tinyint not null,
	language_name varchar(10) not null,

	constraint pk_language_dim primary key (language_id)
);
go


create table patient_fact (
	patient_id int not null,
	race_id tinyint not null,
	marital_status_id tinyint not null,
	language_id tinyint not null,
	gender_code char(1) not null,
	birth_date date,
	percent_below_poverty decimal(10, 2),

	constraint pk_patient_fact primary key (patient_id),
	constraint fk_patient_fact_race_dim foreign key (race_id) references race_dim(race_id),
	constraint fk_patient_fact_marital_status_dim foreign key (marital_status_id) references marital_status_dim(marital_status_id),
	constraint fk_patient_fact_language_dim foreign key (language_id) references language_dim(language_id)
); 
go