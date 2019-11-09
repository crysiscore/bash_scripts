select 	pid.identifier nid,
		e.encounter_datetime data_carga_viral, 
		o.value_numeric Valor_carga, 
		et.name encounter_type,
		o.date_created data_registo, 
		u.username registado_por,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) nome

from 	patient p 
		inner join encounter e on p.patient_id=e.patient_id
		inner join obs o on e.encounter_id=o.encounter_id
		inner join encounter_type et on e.encounter_type=et.encounter_type_id
		inner join users u on e.creator=u.user_id
		inner join
		(	select      i.*
			from        person p
						inner join   patient_identifier i on p.person_id = i.patient_id
			where       i.patient_identifier_id = (
						select    i.patient_identifier_id
						from      patient_identifier i
						where     i.voided = 0
									and       i.patient_id = p.person_id
						order by  i.preferred desc, i.date_created desc limit 1)
		)pid on p.patient_id=pid.patient_id
		inner join
		(	select pn.*
			from 	person p 
					inner join person_name pn on pn.person_id=p.person_id
			where 	pn.person_name_id = (
					select person_name_id 
					from person_name pn 
					where pn.voided=0 and pn.person_id=p.person_id
					order by pn.preferred desc,pn.date_created desc limit 1)
		) pn on pn.person_id=p.patient_id
where 	p.voided=0 and e.voided=0 and o.voided=0 and 
		e.encounter_type in (6,9,13) and 
		o.concept_id=856 and o.value_numeric<1000 and o.value_numeric <>-20 and 
		e.encounter_datetime between :startDate and :endDate and e.location_id=:location
order by pid.identifier
