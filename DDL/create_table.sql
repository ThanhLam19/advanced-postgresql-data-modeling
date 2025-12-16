create table players (
						player_name text,
						height text,
						weight integer,
						college text,
						country text,
						draft_year text,
						draft_round text,
						draft_number text,
						season_stats season_stats[],
						scoring_class scoring_class,
						years_since_last_season integer,
						is_active boolean,
						current_season integer,
						primary key (player_name,current_season)
)



create table players_scd (
	player_name text,
	scoring_class scoring_class,
	is_active boolean,
	start_season integer,
	end_season integer,
	current_season integer,
	primary key ( player_name,start_season)
)

-----------------------------------------------------------------------

create table actors (
					actor text,
					actor_id text,
					quality_class quality_class,
					films films[],
					is_active boolean,
					year integer,
					primary key(actor_id,year)

);



create table actor_scd (
							actor text,
							quality_class quality_class,
							is_active boolean,
							start_season integer,
							end_season integer,
							current_season integer,
							primary key(actor,start_season)
)



-----------------------------------------------------------------------------


create table vertices (
						identifier text,
						type vertext_type,
						properties json,
						primary key(identifier,type)
)



create table edges (
					subject_identifier text,
					subject_type vertext_type,
					object_identifier text,
					object_type vertext_type,
					edge_type edge_type,
					properties json,
					primary key(
								subject_identifier,
								subject_type,
								object_identifier,
								object_type,
								edge_type
								)
)

----------------------------------------------------------------------------------


create table fct_game_details (
	dim_game_date date,
	dim_season integer,
	dim_team_id integer,
	dim_is_playing_at_home boolean,
	dim_player_id integer,
	dim_player_name text,
	dim_start_position text, 
	dim_did_not_play boolean,
	dim_did_not_dress boolean,
	dim_not_with_team boolean, 
	m_minutes real,
	m_fgm integer,
	m_fga integer,
	m_fg3m integer,
	m_fg3a integer,
	m_ftm integer,
	m_fta integer,
	m_oreb integer,
	m_dreb integer,
	m_reb integer,
	m_ast integer,
	m_stl integer,
	m_turnovers integer,
	m_pf integer,
	m_pts integer,
	m_plus_minus integer,
	primary key ( dim_game_date,dim_team_id,dim_player_id)
)



--------------------------------------------------------------------------------------------

create table users_cumulated (
							user_id text,
							date_active date[],
							date date,
							primary key(user_id,date)
)






