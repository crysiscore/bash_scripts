create database temp;
cd /opt/data/Massinga
ls
 
create database temp ; use temp; source mozart_sp_rmdups.sql; create database openmrs; use openmrs; source mabil.sql;


use openmrs;
select location_id, count(*) from openmrs.encounter group by location_id;
create index epts_obs_person_concept on obs(person_id, concept_id);

mysql -uroot -ppassword < schema_sp_export_modified.sql    
mysql -uroot -ppassword



update patient_identifier 
set identifier = '09990912/13/73'
where patient_id= '330';


update patient_identifier 
set identifier = '09990912/13/0074'
where patient_id= '331';

update patient_identifier 
set identifier = '09990912/13/0072'
where patient_id= '329';


select patient_id, identifier
from patient_identifier
where identifier = '0109990912/2013/00072';
