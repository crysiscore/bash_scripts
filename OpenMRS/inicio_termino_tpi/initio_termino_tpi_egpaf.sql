select 	
        pid.identifier identifier,
		visita.patient_id,
        iniciaprofilaxiainh.data_consulta_inicio_inh,
	    iniciaprofilaxiainh.inicia_profilaxia_inh,
        terminoprofilaxiainh.data_consulta_fim_inh,
		terminoprofilaxiainh.termino_profilaxia_inh,
		profilaxiainh.numero_profilaxia_inh,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as NomeCompleto,
		pe.gender,
		round(datediff(:endDate,pe.birthdate)/365) idade
from		

(  select 	e.patient_id,
			max(e.encounter_datetime) data_visita
   from 	patient p
			inner join encounter e on e.patient_id=p.patient_id
   where 	e.encounter_datetime between :startDate and :endDate and e.voided=0 and p.voided=0 and 
			e.location_id=:location and e.encounter_type in (5,7,6,9,18,13)
   group by e.patient_id
) visita

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
	) pn on pn.person_id=visita.patient_id	

left join
	(       select pid1.*
			from patient_identifier pid1
			inner join
				(
					select patient_id,min(patient_identifier_id) id
					from patient_identifier
					where voided=0
					group by patient_id
				) pid2
			where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
	) pid on pid.patient_id=visita.patient_id

left join 
	(
		select person_id,gender,birthdate from person 
		where voided=0 
		group by person_id
		
	) pe on pe.person_id = pn.person_id
 	
inner join
	(  select 	e.patient_id, min(o.value_datetime) inicia_profilaxia_inh, e.encounter_datetime as data_consulta_inicio_inh
		   from 	patient p
					inner join encounter e on e.patient_id=p.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
		   where 	o.value_datetime between :startDate and :endDate and e.voided=0 and p.voided=0 and 					
					e.location_id=:location and e.encounter_type in (6,9) and o.concept_id=6128 and o.voided=0					
		   group by e.patient_id
        ) iniciaprofilaxiainh on visita.patient_id=iniciaprofilaxiainh.patient_id
left join
	(  select 	e.patient_id, min(o.value_datetime) termino_profilaxia_inh, e.encounter_datetime as data_consulta_fim_inh
		   from 	patient p
					inner join encounter e on e.patient_id=p.patient_id
					inner join obs o on o.encounter_id=e.encounter_id
		   where e.voided=0 and p.voided=0 and e.location_id=:location 
	           and e.encounter_type in (6,9) and o.concept_id=6129 and o.voided=0	
		   group by e.patient_id
        ) terminoprofilaxiainh on iniciaprofilaxiainh.patient_id=terminoprofilaxiainh.patient_id and terminoprofilaxiainh.termino_profilaxia_inh > iniciaprofilaxiainh.inicia_profilaxia_inh
left join
	(  select 	e.patient_id,
					count(e.encounter_datetime) numero_profilaxia_inh, e.encounter_datetime, terminainh.termino_profilaxia_inh termina
		   from 	patient p
					inner join encounter e on e.patient_id=p.patient_id
					inner join obs o on o.encounter_id=e.encounter_id 
                    left join ( 
								select 	e.patient_id, min(o.value_datetime) termino_profilaxia_inh
								from 	patient p
								inner join encounter e on e.patient_id=p.patient_id
								inner join obs o on o.encounter_id=e.encounter_id
								where e.voided=0 and p.voided=0 and e.location_id=:location and e.encounter_datetime >= :endDate
								and e.encounter_type in (6,9) and o.concept_id=6129 and o.voided=0	
								group by e.patient_id
								) as terminainh on terminainh.patient_id = p.patient_id   
		   where 	e.voided=0 and p.voided=0 and ((e.encounter_datetime >= :startDate and e.encounter_datetime <= terminainh.termino_profilaxia_inh)
													OR (e.encounter_datetime >= :startDate and terminainh.termino_profilaxia_inh IS NULL))
           and		e.location_id=:location and e.encounter_type in (6,9) and o.concept_id=6122 and o.value_coded=1065 and o.voided=0					
		   group by e.patient_id
	) profilaxiainh on visita.patient_id=profilaxiainh.patient_id 

			