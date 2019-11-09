select 	inicio_real.patient_id,
			inicio_real.data_inicio,
			pe.county_district as 'Distrito',
			pe.address2 as 'PAdministrativo',
			pe.address6 as 'Localidade',
			pe.address5 as 'Bairro',
			pe.address1 as 'PontoReferencia',
			concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
			pid.identifier as NID,
			p.gender,
			round(datediff(:endDate,p.birthdate)/365) idade_actual,
			saida.encounter_datetime as data_saida,
			saida.estado as tipo_saida,
			visita.encounter_datetime as ultimo_levantamento,
			visita.value_datetime as proximo_marcado,
			regime.ultimo_regime,
			regime.data_regime,
			if(programa.patient_id is null,'NAO','SIM') inscrito_programa,
			inicio_segunda.data_inicio_segunda
	from	
		(	Select patient_id,min(data_inicio) data_inicio
			from
				(	Select p.patient_id,min(e.encounter_datetime) data_inicio
					from 	patient p 
							inner join encounter e on p.patient_id=e.patient_id	
							inner join obs o on o.encounter_id=e.encounter_id
					where 	e.voided=0 and o.voided=0 and p.voided=0 and 
							e.encounter_type in (18,6,9) and o.concept_id=1255 and o.value_coded=1256 and 
							e.encounter_datetime<=:endDate and e.location_id=:location
					group by p.patient_id
				
					union
				
					Select p.patient_id,min(value_datetime) data_inicio
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and 
							o.concept_id=1190 and o.value_datetime is not null and 
							o.value_datetime<=:endDate and e.location_id=:location
					group by p.patient_id
					
					union
					
					select 	pg.patient_id,ps.start_date data_inicio
					from 	patient p 
							inner join patient_program pg on p.patient_id=pg.patient_id
							inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
					where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
							pg.program_id=1 and ps.state=4 and  
							ps.start_date<=:endDate and location_id=:location
					

					union
					
					select 	pg.patient_id,pg.date_enrolled 	data_inicio				
					from 	patient p 
							inner join patient_program pg on p.patient_id=pg.patient_id
							inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
					where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
							pg.program_id=2 and ps.state=29 and ps.start_date=pg.date_enrolled and 
							ps.start_date<=:endDate and location_id=:location
					
				) inicio
			group by patient_id
		) inicio_real
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

left join 
	(
		select person_id,gender,birthdate from person 
		where voided=0 
		group by person_id
		
	) p on p.person_id = pn.person_id
	left join person_address pe on pe.person_id=inicio_real.patient_id and pe.preferred=1
	left join
		(		
			select 	pg.patient_id,ps.start_date encounter_datetime,location_id,
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
					pg.program_id=2 and ps.state in (7,8,9,10) and ps.end_date is null and location_id=:location and 
					ps.start_date<=:endDate
		
		) saida on saida.patient_id=inicio_real.patient_id
		left join 
		(Select ultimavisita.patient_id,ultimavisita.encounter_datetime,o.value_datetime,e.location_id
		from

			(	select 	p.patient_id,max(encounter_datetime) as encounter_datetime
				from 	encounter e 
						inner join patient p on p.patient_id=e.patient_id 		
				where 	e.voided=0 and p.voided=0 and e.encounter_type=18 and e.location_id=:location and 
						e.encounter_datetime<=:endDate
				group by p.patient_id
			) ultimavisita
			inner join encounter e on e.patient_id=ultimavisita.patient_id
			inner join obs o on o.encounter_id=e.encounter_id			
			where o.concept_id=5096 and o.voided=0 and e.encounter_datetime=ultimavisita.encounter_datetime and 
			e.encounter_type=18 and e.location_id=:location
		) visita on visita.patient_id=inicio_real.patient_id
		inner join 
		(
			select 	ultimo_lev.patient_id,
					case o.value_coded
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 1703 then 'AZT+3TC+EFV'
						when 6243 then 'TDF+3TC+NVP'
						when 6103 then 'D4T+3TC+LPV/r'
						when 792 then 'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 6116 then 'AZT+3TC+ABC'
						when 6108 then 'TDF+3TC+LPV/r'
						when 1311 then 'ABC+3TC+LPV/r'
						when 1312 then 'ABC+3TC+NVP'
						when 1313 then 'ABC+3TC+EFV'
						when 1314 then 'AZT+3TC+LPV/r'
						when 1315 then 'TDF+3TC+EFV'
						when 6100 then 'AZT+3TC+LPV/r'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
						when 6330 then 'AZT+3TC+RAL+DRV/r'
						when 6105 then 'ABC+3TC+NVP'
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r'
						when 6326 then 'AZT+3TC+ABC+LPV/r'
						when 6327 then 'D4T+3TC+ABC+EFV'
						when 6328 then 'AZT+3TC+ABC+EFV'
						when 6109 then 'AZT+DDI+LPV/r'
						when 6329 then 'TDF+3TC+RAL+DRV/r'
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
			where 	o.person_id=ultimo_lev.patient_id and 
					o.obs_datetime=ultimo_lev.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 and o.location_id=:location and o.value_coded in (6108,1311,1312,1313,1314,1315,6109,6325,6326,6327,6328)
		) regime on regime.patient_id=inicio_real.patient_id
		left join
		(
			select 	pg.patient_id
			from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
			where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled<=:endDate and location_id=:location
		) programa on programa.patient_id=inicio_real.patient_id
		left join
		(	select 	person_id, min(obs_datetime) data_inicio_segunda
			from 	obs 
			where 	concept_id=1088 and value_coded in (6108,1311,1312,1313,1314,1315,6109,6325,6326,6327,6328) and 
					voided=0 and obs_datetime<=:endDate
			group by person_id
		) inicio_segunda on inicio_real.patient_id=inicio_segunda.person_id