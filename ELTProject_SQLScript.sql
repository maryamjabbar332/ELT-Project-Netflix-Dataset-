select * from dbo.netflix_raw;

select count(*) from dbo.netflix_raw;

select * from netflix_raw order by title;


Drop Table dbo.netflix_raw;

create TABLE [dbo].[netflix_raw](
	[show_id] [varchar](10) Primary Key,
	[type] [varchar](10) NULL,
	[title] [nvarchar](1000) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [int] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
) 
GO

select * from netflix_raw order by title;

select * from netflix_raw
where show_id = 's5023';

------------------------------------DATA CLEANING--------------
--removing duplicates

select show_id, count(*)
from netflix_raw
group by show_id
having count(*)>1  -- no duplicates in show_id as it is unique so we created show_id as PK



select * from netflix_raw
where lower(title) in (
select lower(title)
from netflix_raw
group by lower(title)
having count(*)>1
)
order by title


select * from netflix_raw
where concat(lower(title), type) in (
select concat(lower(title), type)
from netflix_raw
group by lower(title), type
having count(*)>1            -- we cannot have multiple column inside IN therefore we will use CONCAT 
)
order by title


with cte as (
select *
, ROW_NUMBER() over(partition by title, type order by show_id) as rn
from netflix_raw
)
select *
from cte
where rn=1   --previously we had 8807 rows , now we have 8804 rows eliminating the duplicates 
             --based on the title and type grouped rows



--new table for listed in, director, country, cast


--for directors
select show_id, trim(value) as director
into netflix_director
from netflix_raw
cross apply string_split(director, ',')


select * from netflix_director



--for country
select show_id, trim(value) as country
into netflix_country
from netflix_raw
cross apply string_split(country, ',')


select * from netflix_country



--for cast
select show_id, trim(value) as cast
into netflix_cast
from netflix_raw
cross apply string_split(cast, ',')


select * from netflix_cast


--for listed_in
select show_id, trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in, ',')


select * from netflix_genre


--Data type conversion for date_added

with cte as (
select *
, ROW_NUMBER() over(partition by title, type order by show_id) as rn
from netflix_raw
)
select show_id, type, title, cast(date_added as date) as date_added, release_year
,rating, case when duration is null then rating else duration end as duration, description
from cte
where rn=1 and date_added is null



--Populating missing values in columns where values are NULL/Missing


select * 
from netflix_raw
where country is null


select * from netflix_raw where director = 'Ahmed Al-Badry'

--------------------------
----------------------------------for null values in country
insert into netflix_country
select show_id, m.country
from netflix_raw as nr
inner join (
select director, country
from netflix_country as nc
inner join netflix_director as nd on nc.show_id = nd.show_id
group by director, country
) m on nr.director=m.director
where nr.country is null

select * from netflix_country

------------------------------

-----------------FINAL CLEAN TABLE CREATED---------


------for null values in duration using CASE Statement and data types conversion using CAST--

with cte as (
select *
, ROW_NUMBER() over(partition by title, type order by show_id) as rn
from netflix_raw
)
select show_id,type,title,cast(date_added as date) as date_added,release_year,rating, 
		case when duration is null 
		then rating 
		else duration 
		end as duration,
		description

into netflix_stage
from cte

select * from netflix_stage


						--------------------------NETFLIX DATA ANALYSIS-----------------

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */


select nd.director, count(distinct n.type) as distinct_type
from netflix_stage n
inner join netflix_director nd on n.show_id=nd.show_id
group by nd.director
having count(distinct n.type) > 1       --checking how many directors have both movies and tv shows




---- this query answer the first question that is for each director count the no of movies and tv shows
select nd.director,
count(distinct case when n.type='Movie' then n.show_id end) as no_of_movies
, count(distinct case when n.type='TV Show' then n.show_id end) as no_of_tvshows
from netflix_stage n
inner join netflix_director nd on n.show_id=nd.show_id
group by nd.director
--having  count(distinct n.type) > 1 
order by no_of_movies, no_of_tvshows


----this query answer 2nd thing for directors who have created both movies and tv shows using having condition at the end
select nd.director,
count(distinct case when n.type='Movie' then n.show_id end) as no_of_movies
,count(distinct case when n.type='TV Show' then n.show_id end) as no_of_tvshows
from netflix_stage n
inner join netflix_director nd on n.show_id=nd.show_id
group by nd.director
having  count(distinct n.type) > 1 




--2 which country has the highest number of comedy movies---

select top 1 nc.country, count(distinct ng.show_id) as count_of_comedyMovies  --we used top 1 as we just need one country with highest rate
from netflix_genre ng
inner join netflix_country nc on ng.show_id=nc.show_id
inner join netflix_stage n on ng.show_id=nc.show_id
where ng.genre = 'Comedies' and n.type = 'Movie'
group by nc.country
order by count_of_comedyMovies desc



--3 for each year(as per movie date added to netflix which is date_added), which director has maximum number of movies released

with cte as (
select nd.director,YEAR(date_added) as date_year,count(n.show_id) as no_of_movies
from netflix_stage n
inner join netflix_director nd on n.show_id=nd.show_id
where type='Movie'
group by nd.director,YEAR(date_added)
)
, cte2 as (
select *
, ROW_NUMBER() over(partition by date_year order by no_of_movies desc, director) as rn
from cte
--order by date_year, no_of_movies desc
)
select * from cte2 where rn=1


--4 what is average duration of movies in each genre

select ng.genre, avg(cast(REPLACE(duration, ' min', '') as int)) as avg_duration
from netflix_stage ns
inner join netflix_genre ng on ns.show_id=ng.show_id
where type='Movie'
group by ng.genre



--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them 


select nd.director
,count(distinct case when ng.genre='Comedies' then ns.show_id end) as no_of_comedy 
,count(distinct case when ng.genre='Horror Movies' then ns.show_id end) as no_of_horror
from netflix_stage ns
inner join netflix_genre ng on ns.show_id=ng.show_id
inner join netflix_director nd on ns.show_id=nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director
having count(distinct ng.genre) >1



select nd.director, ng.genre
from netflix_director nd
inner join netflix_genre ng on nd.show_id=ng.show_id
where ng.genre in ('Comedies','Horror Movies')

select genre from netflix_genre where show_id in
(select show_id from netflix_director where director= 'Dibakar Banerjee')


Dibakar Banerjee	3	1










