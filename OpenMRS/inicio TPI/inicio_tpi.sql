select *
from 

(Select 	inicio_tpi.patient_id,
		inicio_tpi.data_inicio_tpi,
		terminou_tpi.data_final_tpi,
		concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) nome,
		pid.identifier as nid,
		seguimento.ultimo_seguimento,
		if(obs.value_coded is not null,if(obs.value_coded=1065,'Sim','Não'),'SI') recebeu_profilaxia,
		date_add(date_add(inicio_tpi.data_inicio_tpi, interval 6 month), interval -1 day) data_completa_6meses,
		inicio_tarv.data_inicio data_inicio_tarv
from 
(	select p.patient_id,max(value_datetime) data_inicio_tpi
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
	where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and :endDate and
			o.voided=0 and o.concept_id=6128 and e.encounter_type in (6,9) and e.location_id=:location
	group by p.patient_id
) inicio_tpi
left join 
(	select p.patient_id,max(value_datetime) data_final_tpi
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
			inner join obs o on o.encounter_id=e.encounter_id
	where 	e.voided=0 and p.voided=0 and o.value_datetime between :startDate and curdate() and
			o.voided=0 and o.concept_id=6129 and e.encounter_type in (6,9) and e.location_id=:location
	group by p.patient_id
) terminou_tpi on inicio_tpi.patient_id=terminou_tpi.patient_id and inicio_tpi.data_inicio_tpi<terminou_tpi.data_final_tpi
left join 
(	Select patient_id,min(data_inicio) data_inicio
		from
			(	
				-- leva a primeira ocorrencia do conceito 1255: Gestão de TARV e que a resposta foi 1256: Inicio
				Select 	p.patient_id,min(e.encounter_datetime) data_inicio
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on o.encounter_id=e.encounter_id
				where 	e.voided=0 and o.voided=0 and p.voided=0 and
						e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and
						e.encounter_datetime<=:endDate and e.location_id=:location
				group by p.patient_id

				union
				
				-- leva a primeira ocorrencia do conceito 1190: Data de Inicio de TARV
				Select 	p.patient_id,min(value_datetime) data_inicio
				from 	patient p
						inner join encounter e on p.patient_id=e.patient_id
						inner join obs o on e.encounter_id=o.encounter_id
				where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and
						o.concept_id=1190 and o.value_datetime is not null and
						o.value_datetime<=:endDate and e.location_id=:location
				group by p.patient_id

				union

				-- leva a primeira ocorrencia da inscricao do paciente no programa de Tratamento ARV
				select 	pg.patient_id,date_enrolled data_inicio
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=:endDate and pg.location_id=:location

				union
				
				-- Leva a data do primeiro levantamento de ARV para cada paciente: Data do primeiro Fila do paciente
				  SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_inicio
				  FROM 		patient p
							inner join encounter e on p.patient_id=e.patient_id
				  WHERE		p.voided=0 and e.encounter_type=18 AND e.voided=0 and e.encounter_datetime<=:endDate and e.location_id=:location
				  GROUP BY 	p.patient_id
			) inicio_real
		group by patient_id
)inicio_tarv on inicio_tpi.patient_id=inicio_tarv.patient_id
inner join 
(	select  p.patient_id,max(encounter_datetime) ultimo_seguimento
	from	patient p
			inner join encounter e on p.patient_id=e.patient_id
	where 	e.voided=0 and p.voided=0 and e.encounter_datetime between :startDate and curdate() and
			e.encounter_type in (6,9) and e.location_id=:location
	group by p.patient_id
) seguimento on inicio_tpi.patient_id=seguimento.patient_id 
left join obs on obs.person_id=seguimento.patient_id and obs.obs_datetime=seguimento.ultimo_seguimento and obs.voided=0 and obs.concept_id=6122 and obs.location_id=:location
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
) pid on pid.patient_id=inicio_tpi.patient_id
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
) pn on pn.person_id=inicio_tpi.patient_id
) tpi
group by patient_id