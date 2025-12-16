insert into actors
with yesterday as (
					select*from actors
					where year=1979

),	today as (
				select*from actor_films
				where year=1980
),
combined as (
	select 
		coalesce(t.actor,y.actor) as actor,
		coalesce(t.actorid,y.actor_id) as actor_id,
		case 
			when y.films is null then
				array[row(
							t.film,
							t.votes,
							t.rating,
							t.filmid
				)::films]
			when t.film is not null then y.films || array[row(
							t.film,
							t.votes,
							t.rating,
							t.filmid
				)::films]
			else y.films
		end as films,
		
		case
			when t.year is not null then true
			else false
		end as is_active,
		coalesce(t.year,y.year+1) as current_year
	from today t full outer join yesterday y 
		on t.actorid=y.actor_id
)
select 
	actor,
	actor_id,
	case
		when avg(f.rating)>8 then 'star'
		when avg(f.rating)>7 and avg(f.rating)<=8 then 'good'
		when avg(f.rating)>6 and avg(f.rating)<=7 then 'average'
		else 'bad'
	end ::quality_class as quality_class,
	array_agg(f) as films,
	is_active,
	current_year
from combined
cross join unnest(films) as f
group by 
	actor,
	actor_id,
	is_active,
	current_year;
		
		
		

insert into actor_scd
with with_previous as (
	select year,
		   actor,
		   quality_class,
		   is_active,
		   lag(quality_class,1) over (partition by actor order by year) as previous_quality_class,
		   lag(is_active,1) over (partition by actor order by year) as previous_is_active
	from actors
	where year<=1979
	order by actor,year
),
	with_indicators as (
		select*,
			case 
				when quality_class<>previous_quality_class then 1
				when is_active<>previous_is_active then 1
				else 0
			end as changed_indicator
		from with_previous

),
	with_streak as (
	select*,
			sum(changed_indicator) over (partition by actor order by year) as streak
	from with_indicators	
)
select actor,
	   quality_class,
	   is_active,
	   min(year) as start_season,
	   max(year) as end_season,
	   1979 as current_season
from with_streak
group by actor,quality_class,is_active,streak
order by actor,streak


with last_season_scd as (
	select*from actor_scd
	where end_season=1979
),
	historical_season_scd as (
	select*from actor_scd 
	where end_season<1979
),
	this_season_data as (
	select*from actors	
	where year=1980
),
	unchanged_records as (
	select ts.actor,
		   ts.quality_class,
		   ts.is_active,
		   ls.start_season,
		   ls.end_season
	from this_season_data ts left join last_season_scd ls on ts.actor=ls.actor
	where ts.quality_class=ls.quality_class and ts.is_active = ls. is_active
),
	changed_records as (
	select ts.actor,
		   unnest(array[
		   		  row(
		   		  	  ts.quality_class,
		   		  	  ts.is_active,
		   		  	  ts.year,
		   		  	  ts.year
		   		  )::scd_actor_type,
		   		  row(
		   		  	  ls.quality_class,
		   		  	  ls.is_active,
		   		  	  ls.start_season,
		   		  	  ls.end_season
		   		  )::scd_actor_type
		   ]) as record
	from this_season_data ts left join last_season_scd ls on ts.actor=ls.actor
	where ts.quality_class<>ls.quality_class  or ts.is_active <> ls. is_active	
)
select*from changed_records
,
	unnested_changed_records as (
	select actor,
		   (record::scd_actor_type).quality_class,
		   (record::scd_actor_type).is_active,
		   (record::scd_actor_type).start_season,
		   (record::scd_actor_type).end_season
	from changed_records
)
select*from unnested_changed_records
