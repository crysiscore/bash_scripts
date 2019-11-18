select p.patientid, original_nid, new_nid,nul.status, p.uuid, nul.uuid
from patient p, nid_update_log nul
where p.patientid <> nul.new_nid and p.uuid =nul.uuid



update patient 
set patientid=nul.new_nid 
FROM
nid_update_log nul
where patientid <> nul.new_nid and patient.uuid =nul.uuid and nul.status='ACTUALIZADO';