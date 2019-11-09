Select gaac.*,nid.identifier NID,lev.ultimo_lev 'ULTIMO LEVANTAMENTO',lev.proximo_lev 'PROXIMO LEVANTAMENTO',seg.ultimo_seg 'ULTIMO SEGUIMENTO',seg.proximo_seg 'PROXIMO SEGUIMENTO',cd4.value_numeric 'CD4',cd4.obs_datetime 'DATA CD4'
from
	(	Select 	g.name 'DESIGNACAO', g.gaac_identifier 'IDENTIFICACAO',ga.name 'AFINIDADE',
				g.start_date 'DATA DE REGISTO',if(g.crumbled=1,'SIM','') 'DESINTEGRADO',g.reason_crumbled 'MOTIVO DESINTEGRACAO',
				g.date_crumbled 'DATA DE DESINTEGRACAO',gm.member_id,
				gm.start_date 'DATA DE INICIO',gm.end_date 'DATA SAIDA',rl.name 'MOTIVO SAIDA',gm.restart_date 'DATA DE REINICIO'
		from 	gaac g
				inner join gaac_member gm on g.gaac_id=gm.gaac_id
				left join gaac_affinity_type ga on ga.gaac_affinity_type_id=g.affinity_type
				left join gaac_reason_leaving_type rl on rl.gaac_reason_leaving_type_id=gm.reason_leaving_type
		where 	g.voided=0 and gm.voided=0 and gm.start_date between :startDate and :endDate and g.location_id=:location
	) gaac 
	left join 
	(	select lev1.patient_id,lev1.encounter_datetime ultimo_lev,obs.value_datetime proximo_lev
		from
		(select 	e.patient_id,max(encounter_datetime) as encounter_datetime
		from 	encounter e 		
		where 	encounter_type=18 and e.voided=0 and e.location_id=:location and  
				e.encounter_datetime<=:dataFinal
		group by e.patient_id) lev1
		left join obs on obs.person_id=lev1.patient_id and obs.obs_datetime=lev1.encounter_datetime and obs.voided=0 and obs.concept_id=5096 and obs.location_id=:location
	) lev on lev.patient_id=gaac.member_id 
	left join 
	(	select seg1.patient_id,seg1.encounter_datetime ultimo_seg,obs.value_datetime proximo_seg
		from
		(select 	e.patient_id,max(encounter_datetime) as encounter_datetime
		from 	encounter e 		
		where 	encounter_type in (6,9) and e.voided=0 and 
				e.encounter_datetime<=:dataFinal and e.location_id=:location
		group by e.patient_id) seg1
		left join obs on obs.person_id=seg1.patient_id and obs.obs_datetime=seg1.encounter_datetime and obs.voided=0 and obs.concept_id=1410 and obs.location_id=:location
	) seg on seg.patient_id=gaac.member_id 
	left join
	(	select obs.person_id, obs.concept_id,obs.value_numeric,obs.obs_datetime
		from 	obs,
			(	select encounter_id,d.encounter_datetime
				from 	encounter,
						(	select 	patient.patient_id,max(encounter_datetime) as encounter_datetime
							from 	encounter
									inner join patient on patient.patient_id=encounter.patient_id
									inner join obs on obs.encounter_id=encounter.encounter_id
							where 	encounter_type=13 and encounter.voided=0 and
									encounter_datetime <=:dataFinal and encounter.location_id=:location
									and patient.voided=0 and obs.voided=0
									and obs.concept_id=5497
							group by patient_id
						) d
				where 	encounter.encounter_datetime=d.encounter_datetime and encounter.encounter_type=13 and 
						d.patient_id=encounter.patient_id and encounter.voided=0
			) e
		where 	obs.encounter_id=e.encounter_id and
				obs.concept_id=5497 and obs.voided=0
	) cd4 on gaac.member_id=cd4.person_id
	left join
	(	select 	patient_id,max(identifier) identifier
		from 	patient_identifier 
		where 	voided=0 and identifier_type=2
		group by patient_id
	) nid on nid.patient_id=gaac.member_id