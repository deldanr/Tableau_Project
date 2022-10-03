/*
 * SQL script to consolidate information from various tables of a database in order to respond to investor requirements through a Tableau dashboard.
 * Author: Daniel Eldan R.
 * Date:	October, 2022.
 * Contact: deldanr@gmail.com
 * 
 * This was for the final test of the course "BI Analyst" of Biwiser Academy
 */

with tabla_fechas as ( /* Tabla para generar el rango de fechas solicitado */

select 
fecha::DATE
from 
generate_series( '2021-01-01'::timestamp , '2022-12-31'::timestamp,'1 day'::interval) fecha

)

, tabla_feriados as ( /*Tomamos los feriados y sacamos "todos los días domingo" */

select distinct
nombre,
fecha,
tipo
from
api_feriados af 
where af.nombre <> 'Todos los Días Domingos'
)

, tabla_final as (

select
tabla_fechas.fecha,
case
when tabla_fechas.fecha >= '2020-12-31' and tabla_fechas.fecha<='2021-01-03' then 710
when tabla_fechas.fecha <= (select dolar_diario.fecha from dolar_diario order by dolar_diario.fecha desc limit 1)::DATE then /* Asi tomamos desde el ultimo valor registrado */
coalesce(
coalesce(
coalesce(
coalesce(
coalesce(
coalesce(valor_dolar::numeric,
lag(valor_dolar::numeric,1) over (ORDER BY tabla_fechas.fecha)),
lag(valor_dolar::numeric,2) over (ORDER BY tabla_fechas.fecha)),
lag(valor_dolar::numeric,3) over (ORDER BY tabla_fechas.fecha)),
lag(valor_dolar::numeric,4) over (ORDER BY tabla_fechas.fecha)),
lag(valor_dolar::numeric,5) over (ORDER BY tabla_fechas.fecha)),0)
end as valor_dolar,
case
when tabla_fechas.fecha >= '2020-12-31' and tabla_fechas.fecha<='2021-01-03' then 880.26
when tabla_fechas.fecha <= (select euro_diario.fecha from euro_diario order by euro_diario.fecha desc limit 1)::DATE then
coalesce(
coalesce(
coalesce(
coalesce(
coalesce(
coalesce(valor_euro::numeric,
lag(valor_euro::numeric,1) over (ORDER BY tabla_fechas.fecha)),
lag(valor_euro::numeric,2) over (ORDER BY tabla_fechas.fecha)),
lag(valor_euro::numeric,3) over (ORDER BY tabla_fechas.fecha)),
lag(valor_euro::numeric,4) over (ORDER BY tabla_fechas.fecha)),
lag(valor_euro::numeric,5) over (ORDER BY tabla_fechas.fecha)),0)
end as valor_euro,
/*dolar_diario.valor_dolar::NUMERIC, convertimos a tipo numerico, en sus tablas origen vienen como tipo texto 
euro_diario.valor_euro::NUMERIC, */
case when tabla_fechas.fecha <= current_date then uf_diario.valor_uf::numeric /*Nos pide valor uf solo hasta la fecha actual, nos apoyamos con */
	 when tabla_fechas.fecha > current_date then null                         /* el operador current_date que equivale a now() */
	 end as valor_uf,
utm.valor_utm::NUMERIC,
ipc.valor_ipc::NUMERIC,
coalesce(tabla_feriados.nombre,'No hay feriado') as feriados
from
tabla_fechas
left join dolar_diario on /* Cruce dolares por fecha */
	tabla_fechas.fecha = dolar_diario.fecha::DATE
left join euro_diario on /* Cruce euros por fecha */
	tabla_fechas.fecha = euro_diario.fecha::DATE
left join uf_diario on /* Cruce uf por fecha */
	tabla_fechas.fecha = uf_diario.fecha::DATE
left join utm on  /* Cruzamos la utm comparando el año Y el mes, así repetimos el valor para el mes completo que corresponda */
	extract (year from tabla_fechas.fecha) = extract (year from utm.fecha)
	and
	extract (month from tabla_fechas.fecha) = extract (month from utm.fecha)
left join ipc on /* Lo mismo para el IPC, que es un indicador mensualizado */
	extract (year from tabla_fechas.fecha) = extract (year from ipc.fecha)
	and
	extract (month from tabla_fechas.fecha) = extract (month from ipc.fecha)
left join tabla_feriados on /* Y los feriados */
	tabla_fechas.fecha = tabla_feriados.fecha
)

select * from tabla_final order by fecha desc