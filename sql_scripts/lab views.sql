/****************************************************

	LAB VIEW

	Combine information from all lab-related tables
	for a single view providing all relevant details
	from each lab collected.

****************************************************/

create view [v_lab_view_detail] as
	with [all_labs] as (
		select top 1000 [lab].[admission_id]
			, [pat].[patient_id]
			, [type].[lab_type_name]
			, [lab].[lab_value]
			, [unit].[units_full_name]
			, [vals].[lower_limit]
			, [vals].[upper_limit]
			, [pat].[gender_code]
			, [lab].[lab_datetime]
			, row_number() over(
				partition by [lab].[admission_id], [lab].[lab_type_id]
				order by [lab].[lab_datetime] asc
			) [lab_order_type]
			, row_number() over(
				partition by [lab].[admission_id]
				order by [lab].[lab_datetime] asc
			) [lab_order_all]
	
		from [lab_fact] [lab]
		inner join [admission_fact] [adm]
			on [lab].[admission_id] = [adm].[admission_id]
		inner join [patient_fact] [pat]
			on [adm].[patient_id] = [pat].[patient_id]
		inner join [lab_type_dim] [type]
			on [lab].[lab_type_id] = [type].[lab_type_id]
		inner join [lab_units_dim] [unit]
			on [type].[units] = [unit].[units]
		inner join [lab_expected_values] [vals]
			on [type].[lab_type_id] = [vals].[lab_type_id]
			and [pat].[gender_code] = [vals].[gender_code]
	)

	select *
		, case when [lab_value] >= [lower_limit] and [lab_value] <= [upper_limit]
			then 1
			else 0
			end as [within_normal_range]
	from [all_labs]


