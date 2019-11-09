/*
 @startDate & @endDate Representam o perido dos levantamentos de ARVs
 
 */
use openmrs;
set @startDate := '2019-05-01 00:00:00';  
set @endDate := '2019-10-16 00:00:00';

select   distinct	pid.identifier NID,
                    concat(ifnull(pn.given_name,''),' ',ifnull(pn.middle_name,''),' ',ifnull(pn.family_name,'')) as 'NomeCompleto',
                    round(datediff(@endDate,pe.birthdate)/365) idade_actual,
                    pe.birthdate,
           
		           visita.data_levantamento,		
		           regime.ultimo_regime as regime_fila,
                   regime_levantamento.ultimo_regime as regime_ficha_seguimento,
			       dosagem.dosage,
				   peso.peso

	from
		(	select patient_id,encounter_datetime data_levantamento,location_id
			from encounter 
			where encounter_type=18 and voided=0 and encounter_datetime between @startDate and @endDate 
		) visita 	-- Levantamento arv


		left join patient_identifier pid on pid.patient_id=visita.patient_id  and pid.identifier_type=2
		left join person_name pn on pn.person_id=visita.patient_id -- and pn.preferred=1
        left join  person pe on pe.person_id=visita.patient_id
		/*left join (
					Select 	p.patient_id,max(o.value_datetime) dp,o.value_numeric as peso
					from 	patient p
					inner join encounter e on p.patient_id=e.patient_id
			 		inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0 and o.concept_id=5089 and  -- peso
						  e.encounter_datetime <= @endDate 
					group by p.patient_id
			)weight on weight.patient_id = visita.patient_id  -- ultimo peso

         */
		inner join 
		(
			      select 	p.patient_id,
					case o.value_coded
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 1703 then 'AZT+3TC+EFV'
						when 6243 then 'TDF+3TC+NVP'
                        when 6104 then  'ABC+3TC+EFV'
                        when 23784 then 'TDF+3TC+DTG'
						when 21163 then 'AZT+3TC+LPV/r (2ª Linha)' -- new
                        when 23786 then 'ABC+3TC+DTG'
                        when 1311 then 'ABC+3TC+LPV/r (2ª Linha)'
                        when 6234 then 'ABC+TDF+LPV/r'
                        when 1314 then 'AZT+3TC+LPV/r (2ª Linha)'
						when 6103 then  'D4T+3TC+LPV/r'
                        when 23790 then 'TDF+3TC+LPV/r+RTV'
                        when 6107 then 'TDF+AZT+3TC+LPV/r'
                        when 23791 then 'TDF+3TC+ATV/r'
                        when 23792 then 'ABC+3TC+ATV/r'
                        when 23793 then 'AZT+3TC+ATV/r'
                        when 23797 then 'ABC+3TC+DRV/r+RAL'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23815 then 'AZT+3TC+DTG'
                        when 23803 then 'AZT+3TC+RAL+DRV/r'
                        when 23802 then 'AZT+3TC+DRV/r'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23801 then 'AZT+3TC+RAL'
                        when 23798 then '3TC+RAL+DRV/r'
                        when 1313 then 'ABC+3TC+EFV (2ª Linha)'
                        when 23799 then 'TDF+3TC+DTG (2ª Linha)' 
						when 23800 then 'ABC+3TC+DTG (2ª Linha)'
						when 792 then  'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 6116 then 'AZT+3TC+ABC'
						when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
						when 6100 then 'AZT+3TC+LPV/r'
                        when 6106 then 'ABC+3TC+LPV'
						when 6330 then 'AZT+3TC+RAL+DRV/r (3ª Linha)'
						when 6105 then 'ABC+3TC+NVP'
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
						when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
						when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'

					else 'OUTRO' end as ultimo_regime,
					e.encounter_datetime data_regime
                   
			from obs o inner join patient p  on o.person_id=p.patient_id inner join encounter e on e.patient_id=p.patient_id								
					where e.encounter_type=18 and e.voided=0  and
								encounter_datetime <=@endDate  and p.voided=0
					and o.obs_datetime=e.encounter_datetime and o.voided=0 and 
					o.concept_id=1088 
		) regime on regime.patient_id=visita.patient_id and regime.data_regime=visita.data_levantamento
        
        left join 
		(
			      select 	p.patient_id,
                    o.value_coded,
					case o.value_coded
						when 1651 then 'AZT+3TC+NVP'
						when 6324 then 'TDF+3TC+EFV'
						when 1703 then 'AZT+3TC+EFV'
						when 6243 then 'TDF+3TC+NVP'
                        when 6104 then  'ABC+3TC+EFV'
                        when 23784 then 'TDF+3TC+DTG'
                        when 23786 then 'ABC+3TC+DTG'
                        when 1311 then 'ABC+3TC+LPV/r (2ª Linha)'
                        when 6234 then 'ABC+TDF+LPV/r'
                        when 1314 then 'AZT+3TC+LPV/r (2ª Linha)'
						when 6103 then  'D4T+3TC+LPV/r'
                        when 23790 then 'TDF+3TC+LPV/r+RTV'
                        when 6107 then 'TDF+AZT+3TC+LPV/r'
                        when 23791 then 'TDF+3TC+ATV/r'
                        when 23792 then 'ABC+3TC+ATV/r'
                        when 23793 then 'AZT+3TC+ATV/r'
                        when 23797 then 'ABC+3TC+DRV/r+RAL'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23815 then 'AZT+3TC+DTG'
					   when 21163 then 'AZT+3TC+LPV/r (2ª Linha)' -- new
                        when 23803 then 'AZT+3TC+RAL+DRV/r'
                        when 23802 then 'AZT+3TC+DRV/r'
                        when 6329 then 'TDF+3TC+RAL+DRV/r'
                        when 23801 then 'AZT+3TC+RAL'
                        when 23798 then '3TC+RAL+DRV/r'
                        when 1313 then 'ABC+3TC+EFV (2ª Linha)'
                        when 23799 then 'TDF+3TC+DTG (2ª Linha)' 
						when 23800 then 'ABC+3TC+DTG (2ª Linha)'
						when 792 then  'D4T+3TC+NVP'
						when 1827 then 'D4T+3TC+EFV'
						when 6102 then 'D4T+3TC+ABC'
						when 6116 then 'AZT+3TC+ABC'
						when 6108 then 'TDF+3TC+LPV/r(2ª Linha)'
						when 6100 then 'AZT+3TC+LPV/r'
                        when 6106 then 'ABC+3TC+LPV'
						when 6330 then 'AZT+3TC+RAL+DRV/r (3ª Linha)'
						when 6105 then 'ABC+3TC+NVP'
						when 6102 then 'D4T+3TC+ABC'
						when 6325 then 'D4T+3TC+ABC+LPV/r (2ª Linha)'
						when 6326 then 'AZT+3TC+ABC+LPV/r (2ª Linha)'
						when 6327 then 'D4T+3TC+ABC+EFV (2ª Linha)'
						when 6328 then 'AZT+3TC+ABC+EFV (2ª Linha)'
						when 6109 then 'AZT+DDI+LPV/r (2ª Linha)'

					else 'OUTRO' end as ultimo_regime,
					e.encounter_datetime data_regime
                   
			from obs o inner join patient p  on o.person_id=p.patient_id inner join encounter e on e.patient_id=p.patient_id								
					where e.encounter_type=9 and e.voided=0  and
								encounter_datetime <=@endDate  and p.voided=0
					and o.obs_datetime=e.encounter_datetime and o.voided=0 and 
					o.concept_id=1087 
		) regime_levantamento on regime_levantamento.patient_id=visita.patient_id and regime_levantamento.data_regime=visita.data_levantamento

        left  join (
        
        select  o.value_text as dosage,
            	p.patient_id,
              e.encounter_datetime data_dosagem
        from obs o inner join patient p  on o.person_id=p.patient_id inner join encounter e on e.patient_id=p.patient_id								
					where e.encounter_type=18 and e.voided=0  and
								encounter_datetime <=@endDate  and p.voided=0
					and o.obs_datetime=e.encounter_datetime and o.voided=0 and 
					o.concept_id=1711  
        
        ) dosagem on dosagem.data_dosagem=regime.data_regime and dosagem.patient_id=regime.patient_id 
        
    left join (
        
       Select 	p.patient_id,e.encounter_datetime ,o.value_numeric as peso
					from 	patient p
					inner join encounter e on p.patient_id=e.patient_id
			 		inner join obs o on e.encounter_id=o.encounter_id
					where 	p.voided=0 and e.voided=0 and o.voided=0
                     and o.concept_id=5089  
        
        ) peso  on peso.patient_id = visita.patient_id  and   peso.encounter_datetime=visita.data_levantamento --  peso p cada visita
where  round(datediff(@endDate,pe.birthdate)/365) between 0 and 14 
group by  NID, birthdate,data_levantamento,	 regime_fila, peso.peso
order by NID 

