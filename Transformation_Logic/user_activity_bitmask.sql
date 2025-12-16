insert into users_cumulated
with yesterday as (
	select 
			*
	from users_cumulated
	where date=date('2023-01-30')
),
today as (
	select
			cast(user_id as text) ,
			date(event_time) as date_active
	from events
	where date(event_time)=date('2023-01-31')
	and user_id is not null
	group by user_id,date(event_time)
)


select 
		coalesce(t.user_id,y.user_id),
		case 
			when t.date_active is null then y.date_active
			when y.date_active is null then array[t.date_active]
			else y.date_active || array[t.date_active]
		end as date_active,
		coalesce(t.date_active,y.date+ interval '1 day') as date
from today t full outer join yesterday y
on t.user_id=y.user_id;




with users as (
	select * from users_cumulated
),
series as (
	select*from generate_series(date('2023-01-01'),date('2023-01-31'),interval '1 day') as series_date
),
place_holder_ints as(
select
		case when date_active @> array[date(series_date)] then pow(:2,32-(date-date(series_date))) else 0 end as placeholder_int_value,
		*
from users cross join series
)


select 
	user_id,
	cast(cast(sum(placeholder_int_value) as bigint) as bit(32)),
	bit_count(cast(cast(sum(placeholder_int_value) as bigint) as bit(32)))>0 as dim_monthly_active,
	bit_count(cast('11111110000000000000000000000000' as bit(32)) & 
		cast(cast(sum(placeholder_int_value) as bigint) as bit(32)))>0 as dim_weekly_active,
	bit_count(cast('10000000000000000000000000000000' as bit(32)) & 
		cast(cast(sum(placeholder_int_value) as bigint) as bit(32)))>0 as dim_daily_active
from place_holder_ints
group by user_id