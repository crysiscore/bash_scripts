select 	pid.identifier as NID,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
		inicio_real.data_inicio,
                pat.value as Telefone,
		seguimento.data_seguimento,
		carga1.data_primeiro_carga,
		carga1.valor_primeira_carga,
		if(carga1.data_primeiro_carga<>carga2.data_ultima_carga,carga2.data_ultima_carga,'') as data_ultima_carga,
if(carga1.data_primeiro_carga<>carga2.data_ultima_carga,carga2.valor_ultima_carga,'') as valor_ultima_carga,		
		regime.data_regime,
		regime.ultimo_regime,
		pe.gender,
		round(datediff(:endDate,pe.birthdate)/365) idade_actual
from		
		
		
		(	select patient_id,min(data_primeiro_carga) data_primeiro_carga,max(value_numeric) valor_primeira_carga
			from	
				(	select 	e.patient_id,
							min(o.obs_datetime) data_primeiro_carga
					from 	encounter e
							inner join obs o on e.encounter_id=o.encounter_id
					where 	e.encounter_type in (13,6,9) and e.voided=0 and
							o.voided=0 and o.concept_id=856 and e.encounter_datetime between :startDate and :endDate and e.location_id=:location
					group by e.patient_id
				) primeiro_carga
				inner join obs o on o.person_id=primeiro_carga.patient_id and o.obs_datetime=primeiro_carga.data_primeiro_carga
			where o.concept_id=856 and o.voided=0
			group by patient_id
		) carga1
		inner join person pe on pe.person_id=carga1.patient_id and pe.voided=0
		left join
		(	select patient_id,max(data_ultima_carga) data_ultima_carga,max(value_numeric) valor_ultima_carga
			from	
				(	select 	e.patient_id,
							max(o.obs_datetime) data_ultima_carga
					from 	encounter e
							inner join obs o on e.encounter_id=o.encounter_id
					where 	e.encounter_type in (13,6,9) and e.voided=0 and
							o.voided=0 and o.concept_id=856 and e.encounter_datetime between :startDate and :endDate and e.location_id=:location
					group by e.patient_id
				) ultima_carga
				inner join obs o on o.person_id=ultima_carga.patient_id and o.obs_datetime=ultima_carga.data_ultima_carga
			where o.concept_id=856 and o.voided=0
			group by patient_id
		) carga2 on carga1.patient_id=carga2.patient_id
		
		left join 		
		(Select patient_id,min(data_inicio) data_inicio
		from
			(	Select 	p.patient_id,
						min(e.encounter_datetime) data_inicio
				from 	patient p 
						inner join encounter e on p.patient_id=e.patient_id	
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and o.voided=0 and p.voided=0 and 
						e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
						e.encounter_datetime<=:endDate and e.location_id=:location
				group by p.patient_id				
				union	
				Select 	p.patient_id,
						min(value_datetime) data_inicio
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
						o.concept_id=1190 and o.value_datetime is not null and o.value_datetime<=:endDate and o.location_id=:location
				group by p.patient_id
			) inicio
		group by patient_id
		) inicio_real on carga1.patient_id=inicio_real.patient_id

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
	) pn on pn.person_id=inicio_real.patient_id	
		left join patient_identifier pid on pid.patient_id=inicio_real.patient_id and pid.identifier_type=2 and pid.voided=0

		left join 
		(
			select 	ultimo_lev.patient_id,
					case o.value_coded						
						when 1311 then 'ABC+3TC+LVP/r(2ª Linha)'
						when 1312 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 1313 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 1314 then 'AZT+3TC+ABC+EFV (2ª Linha),'
						when 1315 then 'TDF+3TC+EFV (2ª Linha)'
						when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
						when 6100 then 'AZT+3TC+LPV/r(2ª Linha)'					
						when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
						when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
						when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'					
					else 'OUTRO' end as ultimo_regime,
					ultimo_lev.encounter_datetime data_regime
			from 	obs o,				
					(	select p.patient_id,min(encounter_datetime) as encounter_datetime
						from 	patient p
								inner join encounter e on p.patient_id=e.patient_id	
								inner join obs o on o.encounter_id=e.encounter_id
						where 	encounter_type=18 and e.voided=0 and o.concept_id=1088 and o.value_coded in (6108,6100,6325,6326,6327,6328,6109) and 
								encounter_datetime <=:endDate and e.location_id=:location and p.voided=0
						group by patient_id
					) ultimo_lev
			where 	o.person_id=ultimo_lev.patient_id and o.obs_datetime=ultimo_lev.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 and o.location_id=:location and o.value_coded in (6108,6100,6325,6326,6327,6328,6109)
		) regime on regime.patient_id=carga1.patient_id
		left join 
		(	select patient_id,max(encounter_datetime) data_seguimento
			from encounter
			where voided=0 and encounter_type in (6,9) and encounter_datetime between :startDate and :endDate
			group by patient_id
		) seguimento on seguimento.patient_id=carga1.patient_id
left join person_attribute pat on pat.person_id=inicio_real.patient_id and pat.person_attribute_type_id=9 and pat.value is not null and pat.value<>'' and pat.voided=0