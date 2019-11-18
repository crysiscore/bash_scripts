delete from `openmrs_reports`.`list_db` where provincia='Inhambane';

INSERT INTO `openmrs_reports`.`list_db`
            (id,
			`dbname`,
             `provincia`,
             `distrito`,
             `us`,
             `us_id`,
             `location_id`,
             `tipous`)
SELECT
id,
  `dbname`,
  `provincia`,
  `distrito`,
  `us`,
  `us_id`,
  `location_id`,
  `tipous`
FROM `openmrs_reports`.`db_inhambane`;