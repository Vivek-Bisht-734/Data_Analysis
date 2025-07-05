create database spotify_project;
use spotify_project;
select * from spotify limit 3;

select count(*) from spotify;
describe spotify;

alter table spotify change column `artist(s)_name` artist_name text;

SET SQL_SAFE_UPDATES = 0;
alter table spotify add column released_date date;
update spotify set released_date = str_to_date(concat(released_year, '-', released_month, '-', released_day), '%Y-%m-%d'); 


-- 1. Which artist has released the most tracks?
select artist_name, count(track_name) as total_tracks from spotify 
group by artist_name order by total_tracks desc limit 10;


-- 2. What is the total stream count for each artist? List top 10.
select artist_name, sum(streams) as total_streams from spotify 
group by artist_name order by total_streams desc limit 10;


-- 3. Find the average energy, valence, and danceability for each artist.
select artist_name, avg(`energy_%`) as avg_energy, avg(`valence_%`) as avg_valence, 
avg(`danceability_%`) as avg_danceability from spotify group by artist_name;


-- 4. List the number of tracks released each year.
select released_year, count(track_name) as tracks_released from spotify
group by released_year order by released_year desc;


-- 5. Which month has the highest average number of tracks released?
select released_month, avg(total_tracks) as avg_tracks_released from (
select released_year, released_month, count(track_name) total_tracks from spotify 
group by released_year, released_month) as monthly_release
group by released_month
order by released_month;


-- 6. Which songs appear in all four platforms (Spotify, Apple, Deezer, Shazam)?
select distinct track_name from spotify where in_spotify_charts > 0 and 
in_apple_charts > 0 and in_deezer_charts > 0 and in_shazam_charts > 0;


-- 7. Which tracks have the highest BPM values?
select track_name, bpm from spotify order by bpm desc limit 10;


-- 8. Find the most common musical key used.
select `key`, count(`key`) as most_used_key from spotify 
group by `key` order by most_used_key desc limit 1;



-- 9. What is the average stream count for each release year?
select released_year , avg(streams) as avg_streams from spotify
group by released_year order by released_year desc;


-- 10. Which tracks appear in the highest number of Spotify playlists?
select track_name, in_spotify_playlists from spotify 
order by in_spotify_playlists desc limit 10;


-- 11. Find all tracks with 0 instrumentalness but high danceability.
select track_name, `instrumentalness_%`, `danceability_%` from spotify
where `instrumentalness_%` = 0 order by `danceability_%` desc limit 20;


-- 12. Which artists have the highest average presence in charts (Spotify, Apple, etc.)?
select artist_name, avg(in_spotify_charts) as avg_spotify_presence, avg(in_apple_charts) as avg_apple_presence, 
avg(in_deezer_charts) as avg_deezer_presence, avg(in_shazam_charts) as avg_shazam_presence,
(avg(in_spotify_charts) + avg(in_deezer_charts) + avg(in_shazam_charts) + avg(in_apple_charts)) / 4 as overall_avg_presence
from spotify group by artist_name order by overall_avg_presence desc; 


-- 13. Compare the popularity (streams) of songs in major vs minor mode.
select mode, sum(streams) as streams_popularity from spotify 
group by mode;


-- 14. Find songs with above-average danceability and energy but low acousticness.
with avg_songs as(select avg(`danceability_%`) as avg_danceability, avg(`energy_%`) as avg_energy,
avg(`acousticness_%`) as avg_acousticness from spotify)
select track_name, `danceability_%`, `energy_%`, `acousticness_%` from spotify cross join avg_songs
where `danceability_%` > avg_songs.avg_danceability and `energy_%` > avg_songs.avg_energy and 
`acousticness_%` < avg_songs.avg_acousticness;


-- 15. Rank tracks by combined chart presence across platforms.
select track_name, rank() over(order by overall_avg_presence desc) as Ranking_Avg_Presence, overall_avg_presence from 
(select track_name, round((avg(in_spotify_charts) + avg(in_deezer_charts) + avg(in_shazam_charts) + avg(in_apple_charts)) / 4, 2) as overall_avg_presence
from spotify group by track_name) avg_charts 
where overall_avg_presence > 0;


-- 16. What percentage of songs are released in each key?
select `key`, round(count(track_name) * 100 / (select count(track_name) from spotify), 2) as percentage_of_songs from spotify
where `key` is not null group by `key` order by percentage_of_songs desc;


-- 17. Find the top 5 most “danceable” songs released in 2023.
select track_name, `danceability_%` from spotify where released_year = 2023 
order by `danceability_%` desc limit 5;


-- 18. How many songs have 100% speechiness?
select count(track_name) as `total_songs_with_100%_speechiness` from spotify where `speechiness_%` = 100;


-- 19. Find artists whose songs are in both Spotify and Apple charts.
select artist_name, count(track_name) as songs_in_both_charts from spotify where in_spotify_charts > 0 and 
in_apple_charts > 0 group by artist_name order by songs_in_both_charts desc, artist_name asc;


-- 20. Group songs into energy-level buckets (low, medium, high) and find average streams per bucket.
select energy_level_buckets, round(avg(streams), 2) as avg_streams from
(select track_name, streams, case 
when `energy_%` < 33 then "low_bucket"
when `energy_%` between 33 and 66 then "medium_bucket"
else "high_bucket" end as energy_level_buckets from spotify where streams is not null) as condtions
group by energy_level_buckets order by avg_streams desc;


