select *
from 

(select 	inicio_real.patient_id,
			inicio_real.data_inicio,
			pad3.county_district as 'Distrito',
			pad3.address2 as 'PAdministrativo',
			pad3.address6 as 'Localidade',
			pad3.address5 as 'Bairro',
			pad3.address1 as 'PontoReferencia',			
			concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
			pid.identifier as NID,
			p.gender,
			round(datediff(:endDate,p.birthdate)/365) idade_actual	
	from	
		(	Select patient_id,min(data_inicio) data_inicio
			from
				(	Select p.patient_id,
							min(e.encounter_datetime) data_inicio
					from 	patient p 
							inner join encounter e on p.patient_id=e.patient_id	
							inner join obs o on o.encounter_id=e.encounter_id
					where 	e.voided=0 and o.voided=0 and p.voided=0 and 
							e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
							e.encounter_datetime between :startDate and :endDate and e.location_id=:location
					group by p.patient_id	
					
					union
					
					Select 	p.patient_id,min(value_datetime) data_inicio
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
							o.concept_id=1190 and o.value_datetime is not null and 
							o.value_datetime between :startDate and :endDate and e.location_id=:location
					group by p.patient_id
				) inicio
			group by patient_id
		) inicio_real
		inner join person p on p.person_id=inicio_real.patient_id
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
			) pad3 on pad3.person_id=inicio_real.patient_id				
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
			) pid on pid.patient_id=inicio_real.patient_id			
		where inicio_real.patient_id not in 
		(	select distinct patient_id
			from encounter 
			where voided=0 and encounter_type=18
		)
) filas
group by patient_id