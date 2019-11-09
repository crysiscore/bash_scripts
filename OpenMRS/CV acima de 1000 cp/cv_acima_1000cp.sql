select *
from 
(select carga1.patient_id,
		pid.identifier as NID,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
		inicio1.data_inicio,
		carga1.data_ultima_carga,
		carga1.valor_ultima_carga,
		regime.data_regime,
		regime.ultimo_regime,
		pe.gender,
		consulta.data_consulta,
		consulta.data_marcada,
		ultimo_seguimento.data_ultimo_seguimento,
		ultimo_seguimento.data_proximo_seguimento,
		if(gravida.patient_id is not null,'GRAVIDA/LACT',if(tuberculose.patient_id is not null,'TB',null)) referencia,
		round(datediff(:endDate,pe.birthdate)/365) idade_actual
from		
		
		
		(	select patient_id,max(data_ultima_carga) data_ultima_carga,max(value_numeric) valor_ultima_carga
			from	
				(	select 	e.patient_id,
							max(o.obs_datetime) data_ultima_carga
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	e.encounter_type in (13,6,9) and e.voided=0 and p.voided=0 and 
							o.voided=0 and o.concept_id=856 and o.obs_datetime <= :endDate and e.location_id=:location
					group by p.patient_id
				) ultima_carga
				inner join obs o on o.person_id=ultima_carga.patient_id and o.obs_datetime=ultima_carga.data_ultima_carga
			where o.concept_id=856 and o.voided=0 and o.value_numeric>1000
			group by patient_id
		) carga1
		inner join 
		(
			Select 	p.patient_id,
					max(e.encounter_datetime) data_consulta,
					max(o.value_datetime) data_marcada
			from 	patient p
					inner join encounter e on p.patient_id=e.patient_id
					inner join obs o on e.encounter_id=o.encounter_id
			where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
					o.concept_id in (1410,5096) and o.value_datetime is not null and 
					o.value_datetime between date_add(:endDate, interval 7 day) and date_add(:endDate, interval :maxDay day) and o.location_id=:location
			group by p.patient_id
		
		)consulta on carga1.patient_id=consulta.patient_id		
		inner join person pe on pe.person_id=carga1.patient_id and pe.voided=0
		inner join		
		(	Select patient_id,min(data_inicio) data_inicio
			from
				(	Select 	p.patient_id,min(e.encounter_datetime) data_inicio
					from 	patient p 
							inner join encounter e on p.patient_id=e.patient_id	
							inner join obs o on o.encounter_id=e.encounter_id
					where 	e.voided=0 and o.voided=0 and p.voided=0 and 
							e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
							e.encounter_datetime<=:endDate and e.location_id=:location
					group by p.patient_id
			
					union
			
					Select 	p.patient_id,min(value_datetime) data_inicio
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
							o.concept_id=1190 and o.value_datetime is not null and 
							o.value_datetime<=:endDate and e.location_id=:location
					group by p.patient_id

					union

					select 	pg.patient_id,date_enrolled data_inicio
					from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
					where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=:endDate and location_id=:location
					
					union
					
					
					  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio 
					  FROM 		patient p
								inner join encounter e on p.patient_id=e.patient_id
					  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=:endDate and e.location_id=:location
					  GROUP BY 	p.patient_id					
					
				) inicio
				group by patient_id	
		)inicio1 on inicio1.patient_id=carga1.patient_id		
		left join 
		(	select pid1.*
			from patient_identifier pid1
			inner join 
				(
					select patient_id,min(patient_identifier_id) id 
					from patient_identifier
					where voided=0
					group by patient_id
				) pid2
			where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
		) pid on pid.patient_id=carga1.patient_id
		left join 
		(	select pn1.*
			from person_name pn1
			inner join 
				(
					select person_id,min(person_name_id) id 
					from person_name
					where voided=0
					group by person_id
				) pn2
			where pn1.person_id=pn2.person_id and pn1.person_name_id=pn2.id
		) pn on pn.person_id=carga1.patient_id
		left join 
		(	select pad1.*
			from person_address pad1
			inner join 
				(
					select person_id,min(person_address_id) id 
					from person_address
					where voided=0
					group by person_id
				) pad2
			where pad1.person_id=pad2.person_id and pad1.person_address_id=pad2.id
		) pad3 on pad3.person_id=carga1.patient_id
		left join 
		(
			select 	ultimo_lev.patient_id,
					case o.value_coded
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 1703 then 'AZT+3TC+EFV'
						when 6243 then 'TDF+3TC+NVP'
						when 6103 then 'D4T+3TC+LPV/r'
						when 792  then 'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 6116 then 'AZT+3TC+ABC'
						when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
						when 6100 then 'AZT+3TC+LPV/r(2ª Linha)'
						when 6329 then 'TDF+3TC+RAL+DRV/r (3ª Linha)'
						when 6330 then 'AZT+3TC+RAL+DRV/r (3ª Linha)'
						when 6105 then 'ABC+3TC+NVP'
						when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
						when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
						when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'
						when 6110 then 'D4T20+3TC+NVP'
						when 1702 then 'AZT+3TC+NFV'
						when 817  then 'AZT+3TC+ABC'
						when 6104 then 'ABC+3TC+EFV'
						when 6106 then 'ABC+3TC+LPV/r'
						when 6244 then 'AZT+3TC+RTV'
						when 1700 then 'AZT+DDl+NFV'
						when 633  then 'EFV'
						when 625  then 'D4T'
						when 631  then 'NVP'
						when 628  then '3TC'
						when 635  then 'NFV'
						when 797  then 'AZT'
						when 814  then 'ABC'
						when 6107 then 'TDF+AZT+3TC+LPV/r'
						when 6236 then 'D4T+DDI+RTV-IP'
						when 1701 then 'ABC+DDI+NFV'
						when 1311 then 'ABC+3TC+LPV/r (2ª Linha)'
						when 1313 then 'ABC+3TC+EFV (2ª Linha)'
						when 1314 then 'AZT+3TC+LPV (2ª Linha)'
						when 1315 then 'TDF+3TC+EFV (2ª Linha)'
						when 6114 then '3DFC'
						when 6115 then '2DFC+EFV'
						when 6233 then 'AZT+3TC+DDI+LPV'
						when 6234 then 'ABC+TDF+LPV'
						when 6242 then 'D4T+DDI+NVP'
						when 6118 then 'DDI50+ABC+LPV'
					else 'OUTRO' end as ultimo_regime,
					ultimo_lev.encounter_datetime data_regime
			from 	obs o,				
					(	select p.patient_id,max(encounter_datetime) as encounter_datetime
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id								
						where 	encounter_type=18 and e.voided=0 and
								encounter_datetime <=:endDate and e.location_id=:location and p.voided=0
						group by patient_id
					) ultimo_lev
			where 	o.person_id=ultimo_lev.patient_id and o.obs_datetime=ultimo_lev.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 and o.location_id=:location
		) regime on regime.patient_id=carga1.patient_id
		left join 
		(	Select 	ultimavisita.patient_id,ultimavisita.encounter_datetime data_ultimo_seguimento,o.value_datetime data_proximo_seguimento,e.location_id
			from
				(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
					from 	encounter e 
							inner join patient p on p.patient_id=e.patient_id 		
					where 	e.voided=0 and p.voided=0 and e.encounter_type in (6,9) and e.location_id=:location and e.encounter_datetime<=:endDate
					group by p.patient_id
				) ultimavisita
				inner join encounter e on e.patient_id=ultimavisita.patient_id
				inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=1410 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
					e.encounter_type in (6,9) and e.location_id=:location
		) ultimo_seguimento on ultimo_seguimento.patient_id=carga1.patient_id
		left join 
		(
				Select 	p.patient_id
				from 	patient p 
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where 	p.voided=0 and e.voided=0 and o.voided=0 and ((concept_id=1982 and value_coded=44) or o.concept_id=1279 or o.concept_id=1600) and 
						e.encounter_type in (5,6) and e.encounter_datetime between date_add(:endDate, interval -2 year) and :endDate and e.location_id=:location

				union		
						
				Select 	p.patient_id
				from 	patient p inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where 	p.voided=0 and e.voided=0 and o.voided=0 and concept_id=1279 and 
						e.encounter_type in (5,6) and e.encounter_datetime between date_add(:endDate, interval -2 year) and :endDate and e.location_id=:location

				union
						
				select 	pp.patient_id
				from 	patient_program pp 
				where 	pp.program_id=8 and pp.voided=0 and 
						pp.date_enrolled between date_add(:endDate, interval -2 year) and :endDate and pp.location_id=:location
				union		
						
				Select p.patient_id
				from    patient p 
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where   p.voided=0 and e.voided=0 and o.voided=0 and o.concept_id=6332 and value_coded=1065  and 
						e.encounter_type in (5,6) and o.obs_datetime between date_add(:endDate, interval -2 year) and :endDate and e.location_id=:location
				
				union

				select 	p.patient_id
				from 	patient p 
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
						pg.program_id=8 and ps.state=27 and ps.end_date is null and 
						ps.start_date between date_add(:endDate, interval -2 year) and :endDate and location_id=:location
						
		) gravida on gravida.patient_id=carga1.patient_id
		left join 
		(	SELECT 	pg.patient_id
			FROM 	patient p
					inner join patient_program pg on p.patient_id=pg.patient_id
			WHERE 	pg.program_id=5 AND pg.location_id=:location AND pg.voided=0 and p.voided=0 
					AND pg.date_enrolled BETWEEN date_add(:endDate, interval -8 month) and :endDate		

			UNION

			SELECT p.patient_id
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id = e.patient_id             
					INNER JOIN obs o ON e.encounter_id = o.encounter_id        
			WHERE 	o.concept_id=1268 AND o.value_coded=1065  AND e.encounter_type IN (6,9)
					AND e.location_id =:location 
					AND e.encounter_datetime BETWEEN date_add(:endDate, interval -8 month) and :endDate
					AND e.voided=0 AND p.voided=0 and p.voided=0

			UNION

			SELECT p.patient_id
			FROM 	patient p
					INNER JOIN encounter e ON p.patient_id = e.patient_id             
					INNER JOIN obs o ON e.encounter_id = o.encounter_id                
			WHERE 	o.concept_id=1113  AND e.encounter_type IN (6,9)
					AND e.location_id =:location AND o.value_datetime is not null  
					AND o.value_datetime BETWEEN date_add(:endDate, interval -8 month) and :endDate
					AND e.voided=0 AND p.voided=0 AND o.voided=0
		) tuberculose on tuberculose.patient_id=carga1.patient_id		
		
) cargaviral
group by patient_id