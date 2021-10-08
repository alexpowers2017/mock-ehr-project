/*********************************************************

	LAB EXPECTED VALUES

	This table holds the normal range of values for each
	lab test provided, from the lowest normal value to 
	the highest normal value. 
	
	These ranges can vary by gender, so there are unique
	values for both male and female. If the normal range
	is the same for both genders then the same values
	are entered for both male and female.

	These values were taken from a variety of online 
	sources without a physician's input and should 
	not be used to make any clinical decisions.

*********************************************************/


if object_id('lab_expected_values', 'u') is not null
	drop table [lab_expected_values];
go


create table [lab_expected_values] (
	[lab_type_id] tinyint not null,
	[gender_code] char(1) null,
	[lower_limit] decimal(10,2) null,
	[upper_limit] decimal(10,2) null
);
go


insert into [lab_expected_values] ( 
	[lab_type_id], 
	[gender_code],
	[lower_limit],
	[upper_limit] 
)
values 
	(1,'M',18,45),
	(1,'F',18,45),
	(3,'M',0,0.3),
	(3,'F',0,0.3),
	(4,'M',0,0.5),
	(4,'F',0,0.5),
	(5,'M',38.3,48.6),
	(5,'F',35.5,44.9),
	(6,'M',13.2,16.6),
	(6,'F',11.6,15),
	(7,'M',1,4.8),
	(7,'F',1,4.8),
	(8,'M',27,33),
	(8,'F',27,33),
	(9,'M',33.4,35.5),
	(9,'F',34.4,35.5),
	(10,'M',80,96),
	(10,'F',80,96),
	(11,'M',0.1,0.7),
	(11,'F',0.1,0.7),
	(12,'M',2.5,8),
	(12,'F',2.5,8),
	(13,'M',135,317),
	(13,'F',157,371),
	(14,'M',11.8,14.5),
	(14,'F',12.2,16.1),
	(15,'M',4.35,5.65),
	(15,'F',3.92,5.13),
	(16,'M',3.4,9.6),
	(16,'F',3.4,9.6),
	(17,'M',3.5,5.5),
	(17,'F',3.5,5.5),
	(18,'M',44,147),
	(18,'F',44,147),
	(19,'M',7,56),
	(19,'F',7,56),
	(20,'M',3,10),
	(20,'F',3,10),
	(21,'M',8,50),
	(21,'F',8,45),
	(22,'M',0,1.2),
	(22,'F',0,1.2),
	(23,'M',6,24),
	(23,'F',6,24),
	(24,'M',8.5,10.2),
	(24,'F',8.5,10.2),
	(25,'M',23,29),
	(25,'F',23,29),
	(26,'M',96,106),
	(26,'F',96,106),
	(27,'M',0.6,1.1),
	(27,'F',0.7,1.3),
	(28,'M',0,140),
	(28,'F',0,140),
	(29,'M',3.5,5.1),
	(29,'F',3.5,5.1),
	(30,'M',135,145),
	(30,'F',135,145),
	(31,'M',6,8.3),
	(31,'F',6,8.3),
	(32,'M',4.6,8),
	(32,'F',4.6,8),
	(33,'M',0,4),
	(33,'F',0,4),
	(34,'M',1.005,1.03),
	(34,'F',1.005,1.03),
	(35,'M',0,5),
	(35,'F',0,5);

