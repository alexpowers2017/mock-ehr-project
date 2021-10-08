/*************************************************	

	LAB UNITS DIMENSION TABLE

	This table maps the abbreviated units 
	provided in the original labs data to 
	full names for better readability.

*************************************************/	

if object_id('lab_units_dim', 'u') is not null
	drop table [lab_units_dim];
go


create table [lab_units_dim] (
	[units] nvarchar(10),
	[units_full_name] varchar(40),

	constraint [pk_lab_units_dim] primary key ([units])
);
go

insert into [lab_units_dim] (
	[units],
	[units_full_name]
)
values
	('%', '%'),
	('fl', 'femtoliters'),
	('g/dl', 'grams per deciliter'),
	('gm/dl', 'grams per deciliter'),
	('k/cumm', 'thousand per microliter'),
	('m/cumm', 'million per microliter'),
	('mg/dL', 'milligrams per deciliter'),
	('mmol/L', 'millimoles per liter'),
	('no unit', ''),
	('pg', 'picograms'),
	('rbc/hpf', 'red blood cells per high power field'),
	('U/L', 'international units per liter'),
	('wbc/hpf', 'white blood cells per high power field');
