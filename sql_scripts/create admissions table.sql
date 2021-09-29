

if object_id('admission_fact', 'u') is not null
	drop table admission_fact;
go


create table admission_fact (
	admission_id int not null,
	patient_id int not null,
	start_time smalldatetime null,
	end_time smalldatetime null,

	constraint pk_admission_fact primary key (admission_id),
	constraint fk_admission_fact_patient_fact foreign key (patient_id) references patient_fact(patient_id)
);
go
