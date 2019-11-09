select 	inicio_real.patient_id, 
        DATE_FORMAT(inicio_real.data_inicio,'%d/%m/%Y') data_inicio, 
        concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',			
		pid.identifier as NID,
		round(datediff(:endDate,pd.birthdate)/365) idade_actual,
		pd.gender,
		DATE_FORMAT(primeiro_levantamento.data_levantamento,'%d/%m/%Y') lev1, 
		DATE_FORMAT(segundo_levantamento.data_levantamento,'%d/%m/%Y') lev2,
		DATE_FORMAT(terceiro_levantamento.data_levantamento,'%d/%m/%Y') lev3,
		if(inscrito_ptv.date_enrolled is null,'NAO','SIM') inscrito_programa_ptv,
		if(inscrito_tb.date_enrolled is null,'NAO','SIM') inscrito_programa_tb,
		inscrito_ptv.date_enrolled data_inscricao_programa_ptv
from
(	select patient_id,data_inicio
	from
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
	)inicio1
	where data_inicio between date_add(date_add(:endDate, interval -4 month), interval 1 day) and date_add(:endDate, interval -3 month)
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
		select * from person p 
		where voided=0 
		group by person_id
		
	) pd on pd.person_id = pn.person_id

left join 
	(
	SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_levantamento 
				  FROM 		encounter e
				                inner join ( 
                                select patient_id,data_inicio
							     from
								(Select patient_id,min(data_inicio) data_inicio
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
								)inicio1
								where data_inicio between date_add(date_add(:endDate, interval -4 month), interval 1 day) and date_add(:endDate, interval -3 month)
							) inicio_real on inicio_real.patient_id = e.patient_id
				  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime<= :endDate and e.encounter_datetime > inicio_real.data_inicio and e.location_id=:location
				 group by e.patient_id
	
	) primeiro_levantamento on primeiro_levantamento.patient_id = inicio_real.patient_id 
 		

left join 
	(
	SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_levantamento, lev1.data1
				  FROM 		encounter e 
					inner join ( 
						SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data1 
				  		FROM 		encounter e
				                inner join ( select patient_id,data_inicio
							     from
								(Select patient_id,min(data_inicio) data_inicio
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
								)inicio1
								where data_inicio between date_add(date_add(:endDate, interval -4 month), interval 1 day) and date_add(:endDate, interval -3 month)
							) inicio_real on inicio_real.patient_id = e.patient_id
				  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime<= :endDate and e.encounter_datetime > inicio_real.data_inicio and e.location_id=:location
				 group by e.patient_id
				  )lev1 on lev1.patient_id = e.patient_id
				  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime > lev1.data1 and e.location_id=:location
		group by patient_id
	) segundo_levantamento on segundo_levantamento.patient_id = inicio_real.patient_id

left join 
	(
	SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data_levantamento
				  FROM 		encounter e 
				left join 
					(
					SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data2
				  FROM 		encounter e 
					inner join ( 
						SELECT 	e.patient_id, MIN(e.encounter_datetime) AS data1 
				  		FROM 		encounter e
				                inner join ( select patient_id,data_inicio
							     from
								(Select patient_id,min(data_inicio) data_inicio
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
								)inicio1
								where data_inicio between date_add(date_add(:endDate, interval -4 month), interval 1 day) and date_add(:endDate, interval -3 month)
							) inicio_real on inicio_real.patient_id = e.patient_id
				  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime<= :endDate and e.encounter_datetime > inicio_real.data_inicio and e.location_id=:location
				 group by e.patient_id
				  )lev1 on lev1.patient_id = e.patient_id
				  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime > lev1.data1 and e.location_id=:location
		group by patient_id
	) lev2 on lev2.patient_id = e.patient_id
								  WHERE		e.encounter_type = 18 AND e.voided=0 and e.encounter_datetime > lev2.data2 and e.location_id=:location
				  group by e.patient_id
	) terceiro_levantamento on terceiro_levantamento.patient_id = inicio_real.patient_id 
left join 
	(
		select 	pgg.patient_id,pgg.date_enrolled
		from 	patient pt inner join patient_program pgg on pt.patient_id=pgg.patient_id
		where 	pgg.voided=0 and pt.voided=0 and pgg.program_id=3 and pgg.date_enrolled between date_add(date_add(:endDate, interval -4 month), interval 1 day) and :endDate and pgg.location_id=:location
	) inscrito_ptv on inscrito_ptv.patient_id=inicio_real.patient_id

left join 
	(
		select 	pgg.patient_id,pgg.date_enrolled
		from 	patient pt inner join patient_program pgg on pt.patient_id=pgg.patient_id
		where 	pgg.voided=0 and pt.voided=0 and pgg.program_id=5 and pgg.date_enrolled between date_add(date_add(:endDate, interval -4 month), interval 1 day) and :endDate and pgg.location_id=:location
	) inscrito_tb on inscrito_tb.patient_id=inicio_real.patient_id


inner join encounter e on e.patient_id=inicio_real.patient_id
where 	e.voided=0 and e.encounter_type = 18 and e.location_id=:location and
((primeiro_levantamento.data_levantamento > date_add(inicio_real.data_inicio, interval 129 day) OR primeiro_levantamento.data_levantamento IS NULL) OR
(segundo_levantamento.data_levantamento > date_add(inicio_real.data_inicio, interval 129 day) OR segundo_levantamento.data_levantamento IS NULL) OR 
(terceiro_levantamento.data_levantamento > date_add(inicio_real.data_inicio, interval 129 day) OR terceiro_levantamento.data_levantamento IS NULL)) AND
		inicio_real.patient_id not in 
		(
			select 	pg.patient_id
			from 	patient p 
					inner join patient_program pg on p.patient_id=pg.patient_id
					inner join patient_state ps on pg.patient_program_id=ps.patient_program_id
			where 	pg.voided=0 and ps.voided=0 and p.voided=0 and 
					pg.program_id=2 and ps.state=29 and ps.start_date=pg.date_enrolled and 
					ps.start_date between date_add(date_add(:endDate, interval -4 month), interval 1 day) and date_add(:endDate, interval -3 month) and location_id=:location
		)
group by inicio_real.patient_id, primeiro_levantamento.patient_id, segundo_levantamento.patient_id	
having count(distinct e.encounter_datetime)<3