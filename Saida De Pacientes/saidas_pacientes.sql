-- Query para monitorar as saidas de pacientes num determinado periodo
-- modificar os 2 paramentros a seguir:
-- endDate e data final do periodo em avaliacao
-- startDate e data inicial do periodo em avaliacao

set @periodo_saida_inicial:='2019-09-21';
set @periodo_saida_final:='2019-10-20';

USE hrv;

SELECT * 
FROM 
(SELECT 	inicio_real.patient_id,
			inicio_real.data_inicio,
			pad3.county_district AS 'Distrito',
			pad3.address5 AS 'Bairro',
			pad3.address1 AS 'PontoReferencia',
			CONCAT(IFNULL(pn.given_name,''),' ',IFNULL(pn.middle_name,''),' ',IFNULL(pn.family_name,'')) AS 'NomeCompleto',
			pid.identifier AS NID,
			p.gender,
			ROUND(DATEDIFF(@periodo_saida_final,p.birthdate)/365) idade_actual,
			visita.encounter_datetime AS ultimo_levantamento,
			visita.value_datetime AS proximo_marcado,
			regime.ultimo_regime,
			regime.data_regime,
		-- IF(programa.patient_id IS NULL,'NAO','SIM') inscrito_programa,
		-- IF(visita.value_datetime IS NOT NULL,IF(DATEDIFF(@periodo_saida_final,visita.value_datetime)>=30,'ABANDONO NAO NOTIFICADO',''),'') estado,
         --  IF(visita.value_datetime IS NOT NULL,IF(DATEDIFF(@periodo_saida_final,visita.value_datetime)>=30,IF( saida.estado ='ABANDONO','ABANDONO NOTIFICADO','ABANDONO NAO NOTIFICADO'),''),'') estado2,
         -- IF(gaaac.member_id IS NULL,'NÃO','SIM') emgaac,
         -- saida.estado as saida,
		    IF(saida.estado is  null,'ABANDONO NAO NOTIFICADO',saida.estado )as saida,
            saida.start_date as data_da_saida
	FROM	
		(	SELECT patient_id,MIN(data_inicio) data_inicio
			FROM
				(	SELECT p.patient_id,MIN(e.encounter_datetime) data_inicio
					FROM 	patient p 
							INNER JOIN encounter e ON p.patient_id=e.patient_id	
							INNER JOIN obs o ON o.encounter_id=e.encounter_id
					WHERE 	e.voided=0 AND o.voided=0 AND p.voided=0 AND 
							e.encounter_type IN (18,6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
							e.encounter_datetime<=@periodo_saida_final 
					GROUP BY p.patient_id
				
					UNION
				
					SELECT p.patient_id,MIN(value_datetime) data_inicio
					FROM 	patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
							INNER JOIN obs o ON e.encounter_id=o.encounter_id
					WHERE 	p.voided=0 AND e.voided=0 AND o.voided=0 AND e.encounter_type IN (18,6,9) AND 
							o.concept_id=1190 AND o.value_datetime IS NOT NULL AND 
							o.value_datetime<=@periodo_saida_final 
					GROUP BY p.patient_id
					
					UNION
					
					SELECT 	pg.patient_id,pg.date_enrolled data_inicio
					FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=@periodo_saida_final 
					
					UNION
						
						
					SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
					FROM 	patient p
							INNER JOIN encounter e ON p.patient_id=e.patient_id
					WHERE	p.voided=0 AND e.encounter_type=18 AND e.voided=0 AND e.encounter_datetime<=@periodo_saida_final 
					GROUP BY p.patient_id
					
					
				) inicio
			GROUP BY patient_id
		) inicio_real
		INNER JOIN person p ON p.person_id=inicio_real.patient_id		
		LEFT JOIN 
			(	SELECT pad1.*
				FROM person_address pad1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_address_id) id 
					FROM person_address
					WHERE voided=0
					GROUP BY person_id
				) pad2
				WHERE pad1.person_id=pad2.person_id AND pad1.person_address_id=pad2.id
			) pad3 ON pad3.person_id=inicio_real.patient_id				
			LEFT JOIN 			
			(	SELECT pn1.*
				FROM person_name pn1
				INNER JOIN 
				(
					SELECT person_id,MIN(person_name_id) id 
					FROM person_name
					WHERE voided=0
					GROUP BY person_id
				) pn2
				WHERE pn1.person_id=pn2.person_id AND pn1.person_name_id=pn2.id
			) pn ON pn.person_id=inicio_real.patient_id			
			LEFT JOIN
			(       SELECT pid1.*
					FROM patient_identifier pid1
					INNER JOIN
									(
													SELECT patient_id,MIN(patient_identifier_id) id
													FROM patient_identifier
													WHERE voided=0
													GROUP BY patient_id
									) pid2
					WHERE pid1.patient_id=pid2.patient_id AND pid1.patient_identifier_id=pid2.id
			) pid ON pid.patient_id=inicio_real.patient_id
		
		LEFT JOIN		
		(	SELECT ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id
			FROM
				(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=18  
							AND e.encounter_datetime<=@periodo_saida_final
					GROUP BY p.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				LEFT JOIN obs o ON o.encounter_id=e.encounter_id AND o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime			
			WHERE  o.voided=0 AND e.encounter_type=18 
		) visita ON visita.patient_id=inicio_real.patient_id
		LEFT JOIN 
		(
			SELECT 	ultimo_lev.patient_id,
					CASE o.value_coded
							when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 1703 then 'AZT+3TC+EFV'
						when 6243 then 'TDF+3TC+NVP'
                        when 6104 then  'ABC+3TC+EFV'
                        when 23784 then 'TDF+3TC+DTG'
                        when 23786 then 'ABC+3TC+DTG'
                        when 1311 then 'ABC+3TC+LPV/r (2ª Linha)'
                        when 6234 then 'ABC+TDF+LPV/r'
                        when 1314 then 'AZT+3TC+LPV/r (2ª Linha)'
						when 6103 then  'D4T+3TC+LPV/r'
                        when 23790 then 'TDF+3TC+LPV/r+RTV'
                        when 6107 then 'TDF+AZT+3TC+LPV/r'
                        when 23791 then 'TDF+3TC+ATV/r'
                        when 23792 then 'ABC+3TC+ATV/r'
                        when 23793 then 'AZT+3TC+ATV/r'
                        when 23797 then 'ABC+3TC+DRV/r+RAL'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23815 then 'AZT+3TC+DTG'
					   when 21163 then 'AZT+3TC+LPV/r (2ª Linha)' -- new
                        when 23803 then 'AZT+3TC+RAL+DRV/r'
                        when 23802 then 'AZT+3TC+DRV/r'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23801 then 'AZT+3TC+RAL'
                        when 23798 then '3TC+RAL+DRV/r'
                        when 1313 then 'ABC+3TC+EFV (2ª Linha)'
                        when 23799 then 'TDF+3TC+DTG (2ª Linha)' 
						when 23800 then 'ABC+3TC+DTG (2ª Linha)'
						when 792 then  'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 6116 then 'AZT+3TC+ABC'
						when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
						when 6100 then 'AZT+3TC+LPV/r'
                        when 6106 then 'ABC+3TC+LPV'
						when 6330 then 'AZT+3TC+RAL+DRV/r (3ª Linha)'
						when 6105 then 'ABC+3TC+NVP'
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
						when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
						when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'
					ELSE 'OUTRO' END AS ultimo_regime,
					ultimo_lev.encounter_datetime data_regime
			FROM 	obs o,				
					(	SELECT p.patient_id,MAX(encounter_datetime) AS encounter_datetime
						FROM 	patient p
								INNER JOIN encounter e ON p.patient_id=e.patient_id								
						WHERE 	encounter_type=18 AND e.voided=0 AND
								encounter_datetime <=@periodo_saida_final  AND p.voided=0
						GROUP BY patient_id
					) ultimo_lev
			WHERE 	o.person_id=ultimo_lev.patient_id AND o.obs_datetime=ultimo_lev.encounter_datetime AND o.voided=0 AND 
					o.concept_id=1088 
		) regime ON regime.patient_id=inicio_real.patient_id
		LEFT JOIN
		(
			SELECT 	pg.patient_id
			FROM 	patient p INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
			WHERE 	pg.voided=0 AND p.voided=0 AND program_id=2 AND date_enrolled<=@periodo_saida_final
		) programa ON programa.patient_id=inicio_real.patient_id
		LEFT JOIN
		(
			SELECT DISTINCT member_id FROM gaac_member WHERE voided=0
		) gaaac ON gaaac.member_id=inicio_real.patient_id
         left join
		(		
			select 	pg.patient_id,ps.start_date encounter_datetime,location_id,ps.start_date,ps.end_date,
					case ps.state
						when 7 then 'TRANSFERIDO PARA'
						when 8 then 'SUSPENSO'
						when 9 then 'ABANDONO'
						when 10 then 'OBITO'
					else 'OUTRO' end as estado
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null  and 
					ps.start_date<=@periodo_saida_final
		
		) saida on saida.patient_id=inicio_real.patient_id 
 	WHERE  inicio_real.patient_id  IN 
		(		
			SELECT 	pg.patient_id					
			FROM 	patient p 
					INNER JOIN patient_program pg ON p.patient_id=pg.patient_id
					INNER JOIN patient_state ps ON pg.patient_program_id=ps.patient_program_id
			WHERE 	pg.voided=0 AND ps.voided=0 AND p.voided=0 AND 
					pg.program_id=2 AND ps.state IN (7,8,9,10) AND 
					ps.end_date IS NULL AND ps.start_date between @periodo_saida_inicial and @periodo_saida_final
			UNION
			
			SELECT 	person_id
			FROM 	person 
					INNER JOIN patient ON person.person_id=patient.patient_id
			WHERE  dead=1 AND death_date between @periodo_saida_inicial and @periodo_saida_final
            
		    UNION
           
           SELECT ultimavisita.patient_id
			FROM
				(	SELECT 	p.patient_id,MAX(encounter_datetime) AS encounter_datetime
					FROM 	encounter e 
							INNER JOIN patient p ON p.patient_id=e.patient_id 		
					WHERE 	e.voided=0 AND p.voided=0 AND e.encounter_type=18  
							AND e.encounter_datetime<=@periodo_saida_final
					GROUP BY p.patient_id
				) ultimavisita
				INNER JOIN encounter e ON e.patient_id=ultimavisita.patient_id
				LEFT JOIN obs o ON o.encounter_id=e.encounter_id AND o.concept_id=5096 AND e.encounter_datetime=ultimavisita.encounter_datetime			
			WHERE  o.voided=0 AND e.encounter_type=18 and  DATEDIFF(@periodo_saida_final,o.value_datetime) between 30 and 40
		    
        
		)
) activos  where data_da_saida is null or data_da_saida > @periodo_saida_inicial
GROUP BY patient_id