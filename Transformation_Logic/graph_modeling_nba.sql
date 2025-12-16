insert into vertices
select game_id as identifier,
	   'game'::vertext_type as type,
	   json_build_object(
	   					'pts_home',pts_home,
	   					'pts_away',pts_away,
	   					'winning_team' , case when home_team_wins=1 then home_team_id else visitor_team_id end
	   ) as properties
from games  

insert into vertices
with teams_deduped as (
	select*,row_number() over(partition by team_id) as row_num
	from teams

)
select team_id as identifier,
	   'team'::vertext_type as type,
	   json_build_object(
	   					'abbreviation',abbreviation,
	   					'nickname',nickname,
	   					'yearfounded',yearfounded,
	   					'city',city,
	   					'arena',arena
	   
	   ) as properties
from teams_deduped
where row_num=1

insert into vertices
with player_agg as (
	select player_id as identifier,
		   max(player_name) as player_name,
		   count(1) as number_of_games,
		   sum(pts) as total_points,
		   array_agg(distinct team_id) as teams
	from game_details
	group by player_id
)
select  identifier,
	   'player'::vertext_type as type,
	   json_build_object(
	   					 'player_name',player_name,
	   					 'number_of_games',number_of_games,
	   					 'total_points',total_points,
	   					 'teams',teams
	   
	   )
from player_agg





insert into edges 
with deduped as (
				select*,row_number() over (partition by player_id,game_id) as row_num
				from game_details
),
	filtered as (
				select*from deduped
				where row_num=1
),
	aggregated as (
		select 
			   f1.player_id as subject_identifier,
			   f2.player_id as object_identifier,
			   case when f1.team_abbreviation=f2.team_abbreviation then 'shares_team'::edge_type else 'play_against'::edge_type end as edge_type,
			   count(f1.player_id) as num_games,
			   sum(f1.pts) as left_points,
			   sum(f2.pts) as right_points
		from filtered f1 join filtered f2 
		on f1.game_id = f2.game_id 
		and f1.player_id<>f2.player_id 
		where f1.player_id>f2.player_id
		group by 
			   f1.player_id,
			   f2.player_id,
			   case when f1.team_abbreviation=f2.team_abbreviation then 'shares_team'::edge_type else 'play_against'::edge_type end 
)
select subject_identifier as subject_identifer,
	   'player'::vertext_type,
	   object_identifier as object_identifier,
	   'player'::vertext_type,
	   edge_type as edge_type,
	   json_build_object(
	   					'num_games',num_games,
	   					'left_points',left_points,
	   					'right_points',right_points
	   
	   ) as properties
from aggregated
select player_id as subject_identifer,
	   'player'::vertext_type as subject_type,
	   game_id as object_identifier,
	   'game'::vertext_type as object_type,
	   'play_in'::edge_type as edge_type,
	   json_build_object(
	   						'start_position',start_position,
	   						'pts',pts,
	   						'team_id',team_id,
	   						'team_abbreviation',team_abbreviation
	   
	   ) as properties
from deduped
where row_num=1

select * from edges where "edge_type" ='play_against'



