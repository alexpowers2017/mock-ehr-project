
if object_id('lab_fact', 'u') is not null
	drop table lab_fact;
go

if object_id('lab_type_dim', 'u') is not null
	drop table lab_type_dim;
go


create table lab_type_dim (
	lab_type_id tinyint not null,
	lab_type_name nvarchar(40) not null,
	units nvarchar(10) not null,

	constraint pk_lab_type_dim primary key (lab_type_id)
);
go

create table lab_fact (
	lab_id int not null,
	admission_id int not null,
	lab_type_id tinyint not null,
	lab_value decimal(10, 2) not null,
	lab_datetime smalldatetime null,

	constraint pk_lab_fact primary key (lab_id),
	constraint fk_lab_fact_lab_type_dim foreign key (lab_type_id) references lab_type_dim(lab_type_id)
);
go