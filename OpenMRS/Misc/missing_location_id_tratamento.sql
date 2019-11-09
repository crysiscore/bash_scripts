set @startDate := '2016-11-21 00:00:00';
set @endDate := '2019-03-20 00:00:00';
set @location := 418;


select *
from
	(select 	inscricao.patient_id,
	    concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
			pid.identifier as NID,
	  	pad3.county_district as 'Distrito',
		--	pad3.address2 as 'PAdministrativo',
		-- 	pad3.address6 as 'Localidade',
			pad3.address5 as 'Bairro',
			pad3.address1 as 'PontoReferencia',

			inscricao.data_abertura,
			inscricao.gender,
			inscricao.dead,
			inscricao.death_date,
			-- inscricao.idade_abertura,
			-- inscricao.idade_actual,
			-- transferido.data_transferido_de,
			if(transferido.program_id is null,null,if(transferido.program_id=1,'PRE-TARV','TARV')) as transferido_de,
			-- inicio_real.data_inicio,
			if(inscrito_cuidado.date_enrolled is null,'NAO','SIM') inscrito_cuidado,
	    inscrito_cuidado.date_enrolled data_inscricao_cuidado,
	    if(activo_pre_tarv.program_id is null ,null ,'activo no progrmama') estado_pre_tarv,
	    if(inscrito_tratameto.date_enrolled is null,'NAO','SIM') inscrito_tratamento,
	    inscrito_tratameto.date_enrolled data_inscricao_tratamento,
	    if(activo_tarv.program_id is null ,null ,'activo no progrmama') estado_tarv,
	    if(abandono.program_id is null,null,'SIM') abandono_or_transferido,
	      inscrito_tratameto.location_id
	from
			(Select 	e.patient_id,
					min(encounter_datetime) data_abertura,
					gender,
					dead,
					death_date,
					round(datediff(e.encounter_datetime,pe.birthdate)/365) idade_abertura,
					round(datediff(@endDate,pe.birthdate)/365) idade_actual,
					e.location_id
			from 	patient p
					inner join encounter e on e.patient_id=p.patient_id
					inner join person pe on pe.person_id=p.patient_id
			where 	p.voided=0 and e.encounter_type in (5,7) and e.voided=0 and pe.voided=0 and
					e.encounter_datetime between @startDate and @endDate and e.location_id=@location
			group by p.patient_id
			) inscricao
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
			) pad3 on pad3.person_id=inscricao.patient_id
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
			) pn on pn.person_id=inscricao.patient_id
			left join
			( select pid1.*
					from patient_identifier pid1
					inner join
									(
													select patient_id,min(patient_identifier_id) id
													from patient_identifier
													where voided=0
													group by patient_id
									) pid2
					where pid1.patient_id=pid2.patient_id and pid1.patient_identifier_id=pid2.id
			) pid on pid.patient_id=inscricao.patient_id

			left join
			(
				select 	pg.patient_id,max(ps.start_date) data_transferido_de,pg.program_id
				from 	patient p
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
						pg.program_id in (1,2) and ps.state in (28,29) and
						ps.start_date between @startDate and @endDate and location_id=@location
				group by pg.patient_id

			) transferido on transferido.patient_id=inscricao.patient_id and transferido.data_transferido_de<=inscricao.data_abertura

			left join
			(
				select 	pg.patient_id,max(ps.start_date) data_abandono,pg.program_id
				from 	patient p
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
						pg.program_id in (1,2) and ps.state in (2,3,5,7,9,10) and
						ps.start_date between @startDate and @endDate and location_id=@location
				group by pg.patient_id

			) abandono on abandono.patient_id=inscricao.patient_id -- and abandono.data_abandono<=inscricao.data_abertura


			left join
			(
				select 	pg.patient_id,max(ps.start_date) data_activo_pre_tarv,pg.program_id
				from 	patient p
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
						pg.program_id =1 and ps.state =1 and
						ps.start_date between @startDate and @endDate and location_id=@location
				group by pg.patient_id

			) activo_pre_tarv on activo_pre_tarv.patient_id=inscricao.patient_id and activo_pre_tarv.data_activo_pre_tarv<=inscricao.data_abertura

			left join
			(
				select 	pg.patient_id,max(ps.start_date) data_activo_tarv,pg.program_id, pg.location_id
				from 	patient p
						inner join patient_program pg on p.patient_id=pg.patient_id
						inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
				where 	pg.voided=0 and ps.voided=0 and p.voided=0 and
						pg.program_id =2 and ps.state =6 and
						ps.start_date between @startDate and @endDate -- and location_id=@location
				group by pg.patient_id

			) activo_tarv on activo_tarv.patient_id=inscricao.patient_id and activo_tarv.data_activo_tarv<=inscricao.data_abertura


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
							e.encounter_datetime between @startDate and @endDate and e.location_id=@location
					group by p.patient_id
					union
					Select 	p.patient_id,
							min(value_datetime) data_inicio
					from 	patient p
							inner join encounter e on p.patient_id=e.patient_id
							inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and e.encounter_type in (18,6,9) and
							o.concept_id=1190 and o.value_datetime is not null and o.value_datetime between @startDate and @endDate and o.location_id=@location
					group by p.patient_id
				) inicio
			group by patient_id
			) inicio_real on inscricao.patient_id=inicio_real.patient_id

		/*	left join
			(	select patient_id,min(encounter_datetime) data_seguimento
				from encounter
				where voided=0 and encounter_type in (6,9) and encounter_datetime between @startDate and @endDate
				group by patient_id
			) seguimento on seguimento.patient_id=inscricao.patient_id*/

			left join
			(
				select 	pg.patient_id,date_enrolled
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=1 and date_enrolled <= @endDate and location_id=@location
			) inscrito_cuidado on inscrito_cuidado.patient_id=inscricao.patient_id

			left join
			(
				select 	pg.patient_id,date_enrolled, pg.location_id
				from 	patient p inner join patient_program pg on p.patient_id=pg.patient_id
				where 	pg.voided=0 and p.voided=0 and program_id=2 and date_enrolled <=  @endDate -- and location_id=@location
			) inscrito_tratameto on inscrito_tratameto.patient_id=inscricao.patient_id

	)inscritos  where   inscritos.inscrito_cuidado = 'SIM' and inscritos.inscrito_tratamento='SIM'  and inscritos.location_id is null  -- and  inscritos.abandono_or_transferido is null
group by patient_id