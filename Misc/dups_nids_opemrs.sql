use openmrs;
-- select now() into @enddate;
SELECT  pid.identifier Nid, pe.uuid uuidopenmrs, pn.given_name,pn.middle_name,pn.family_name,
	round(datediff(now(),pd.birthdate)/365) idade_actual,
      DATE_FORMAT(pa.data_inicio,'%d/%m/%Y') inicio_tarv,
      if(inscrito_pretarv.date_enrolled is null,'NAO','SIM') inscrito_programa_pretarv,
            if(inscrito_tarv.date_enrolled is null,'NAO','SIM') inscrito_programa_tarv,
             saida.estado AS saida,
            saida.start_date AS data_da_saida
  FROM  patient pat INNER JOIN  openmrs.patient_identifier pid ON pat.patient_id =pid.patient_id
  INNER JOIN person pe ON pat.patient_id=pe.person_id
  INNER JOIN person_name pn ON pe.person_id=pn.person_id

  left join 
	(
		select person_id,gender,birthdate from person 
		where voided=0 
		group by person_id
		
	) pd on pd.person_id = pn.person_id
left join 
(select 	pg.patient_id,date_enrolled data_inicio
					from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
					where 	pg.voided=0 and p.voided=0 and program_id=2 
					) pa on pa.patient_id= pat.patient_id
left join 
			(
				select 	pgg.patient_id,pgg.date_enrolled
				from 	patient pt inner join patient_program pgg on pt.patient_id=pgg.patient_id
				where 	pgg.voided=0 and pt.voided=0 and pgg.program_id=1 
			) inscrito_pretarv  on inscrito_pretarv.patient_id=pat.patient_id
left join 
			(
				select 	pgg.patient_id,pgg.date_enrolled
				from 	patient pt inner join patient_program pgg on pt.patient_id=pgg.patient_id
				where 	pgg.voided=0 and pt.voided=0 and pgg.program_id=2
			) inscrito_tarv  on inscrito_tarv.patient_id=pat.patient_id

   LEFT JOIN
		(		
			SELECT 	pg.patient_id,ps.start_date encounter_datetime,ps.start_date,ps.end_date,
					CASE ps.state
						WHEN 7 THEN 'TRANSFERIDO PARA'
						WHEN 8 THEN 'SUSPENSO'
						WHEN 9 THEN 'ABANDONO'
						WHEN 10 THEN 'OBITO'
					ELSE 'OUTRO' END AS estado
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,9,10) AND ps.end_date IS NULL  
		
		) saida ON saida.patient_id=pat.patient_id 

WHERE pid.identifier 
in( SELECT  pid.identifier 
  FROM openmrs.patient_identifier pid 
  GROUP BY identifier
HAVING COUNT(*)>=2 ) order by  pid.identifier 