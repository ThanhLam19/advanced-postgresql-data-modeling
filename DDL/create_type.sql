create type season_stats as (
							season integer,
							gp integer,
							pts real,
							reb real,
							ast real

							)

create type scoring_class as enum ('star','good','average','bad');

create type scd_type as (
						scoring_class scoring_class,
						is_active boolean,
						start_season integer,
						end_season integer
)

-----------------------------------------------------------------------------


create type films as (
						film text,
						votes integer,
						rating real,
						filmid text
);
create type quality_class as enum ('star','good','average','bad');



create type scd_actor_type as (
						quality_class quality_class,
						is_active boolean,
						start_season integer,
						end_season integer
)




-----------------------------------------------------------------------------------


create type vertext_type as enum ('player','team','game')


create type edge_type as enum (
								'play_against',
								'shares_team',
								'play_in',
								'play_on'
)

