select min(season) from player_seasons;
insert into players
with yesterday as (
	select*from players
	where current_season=2021
),
	today as(
	select*from player_seasons 
	where season=2022
)
select
	coalesce(t.player_name,y.player_name) as player_name,
	coalesce(t.height,y.height) as height,
	coalesce(t.weight,y.weight) as weight,
	coalesce(t.college,y.college) as college,
	coalesce(t.country,y.country) as country,
	coalesce(t.draft_year,y.draft_year) as draft_year,
	coalesce(t.draft_round,y.draft_round) as draft_round,
	coalesce(t.draft_number,y.draft_number) as draft_number,
	case when y.season_stats is null 
	then array[row(
		t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast
	)::season_stats]
	when t.season is not null then y.season_stats || array[row(
		t.season,
		t.gp,
		t.pts,
		t.reb,
		t.ast
	)::season_stats]
	else y.season_stats
	end as season_stats,
	case
		when t.season is not null then 
			case 
				when t.pts>20 then 'star'
				when t.pts>15 then 'good'
				when t.pts>10 then 'average'
				else 'bad'
			end::scoring_class
		else y.scoring_class
	end as scoring_class,
	case when t.season is not null then 0
		else y.years_since_last_season+1
	end as years_since_last_season,
	case when t.season is not null then true
		else false 
	end as is_active,
	coalesce(t.season,y.current_season+1) as current_season
from today t full outer join yesterday y 
	on t.player_name=y.player_name;

select*from players


with unnested as (
	select player_name,
			unnest(season_stats)::season_stats as season_stats
	from players 
	where current_season=2001
	and player_name ='Michael Jordan'

)

select player_name, (season_stats::season_stats).*
from unnested;






insert into players_scd
with with_previous as (
	select 
		current_season,
		player_name , 
		scoring_class, 
		is_active, 
		lag(scoring_class,1) over (partition by player_name order by current_season) as previous_scoring_class,
		lag(is_active,1) over (partition by player_name order by current_season) as previous_is_active
	from players 
	where current_season<=2021
	order by player_name,current_season
),
 	with_indicators as (
	select *,
		case 
			when scoring_class <>previous_scoring_class	then 1
			when is_active <> previous_is_active then 1
			else 0
		end as changed_indicator
	from with_previous
),
	with_streaks as (
	select*,
			sum(changed_indicator) over (partition by player_name order by current_season) as streak_identifier
	from with_indicators
)

select player_name,
	    scoring_class,
		is_active,
		min(current_season) as start_season,
		max(current_season) as end_season,
		2021 as current_season
from with_streaks
group by player_name,streak_identifier,is_active,scoring_class
order by player_name,streak_identifier


select*from players_scd;


with last_season_scd as (
	select * from players_scd 
	where current_season= 2021
	and end_season =2021
),
	historical_scd as(
	select player_name,
		   scoring_class,
		   is_active,
		   start_season,
		   end_season
	from players_scd 
	where current_season=2021
	and end_season<2021
),
	this_season_data as(
	select*from players 
	where current_season=2022
),
	unchanged_records as(
	select ts.player_name ,
		   ts.scoring_class,	   ts.is_active ,
		   ls.start_season,		   ls.current_season as end_season
	from this_season_data ts left join last_season_scd ls
	on ts.player_name =ls.player_name 
	where ts.scoring_class=ls.scoring_class 
	and ts.is_active =ls.is_active 
),
	changed_records as (
	select ts.player_name,
		   unnest(array[
		   		row(
		   				ls.scoring_class,
		   				ls.is_active,
		   				ls.start_season,
		   				ls.end_season		   
		   			)::scd_type,
		   		row(
		   				ts.scoring_class,
		   				ts.is_active,
		   				ts.current_season,
		   				ts.current_season
		   		
		   		)::scd_type
		   	]) as records
	from this_season_data ts left join last_season_scd ls
	on ts.player_name =ls.player_name 
	where (ts.scoring_class<> ls.scoring_class 
	or ts.is_active <>ls.is_active)
)
select *from changed_records

,
	unnested_changed_records as (
	select player_name,
		   (records::scd_type).scoring_class,
		   (records::scd_type).is_active,
		   (records::scd_type).start_season,
		   (records::scd_type).end_season
		   from changed_records	
),
	new_records as(
					select ts.player_name ,
		   			ts.scoring_class,	   ts.is_active ,
		   			ts.current_season as start_season,	   ts.current_season as end_season
	from this_season_data ts left join last_season_scd ls
	on ts.player_name =ls.player_name 
	where ls.scoring_class is null				
)



select*from historical_scd

union all 

select *from unchanged_records

union all

select*from unnested_changed_records

union all 

select*from new_records