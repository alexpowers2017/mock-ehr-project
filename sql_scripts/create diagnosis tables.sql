
if object_id('diagnosis_fact', 'u') is not null
	drop table diagnosis_fact;
go

if object_id('diagnosis_dim', 'u') is not null
	drop table diagnosis_dim;
go


create table diagnosis_dim (
	icd10_code nvarchar(10) not null,
	description nvarchar(150) not null,

	constraint pk_diagnosis_dim primary key (icd10_code)
);
go

create table diagnosis_fact (
	admission_id int not null,
	icd10_code nvarchar(10) not null,

	constraint fk_diagnosis_fact_admission_fact foreign key (admission_id) references admission_fact(admission_id),
	constraint fk_diagnosis_fact_diagnosis_dim foreign key (icd10_code) references diagnosis_dim(icd10_code)
);
go