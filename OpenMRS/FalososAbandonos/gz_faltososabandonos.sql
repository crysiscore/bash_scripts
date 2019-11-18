DELIMITER $$

USE `openmrs_reports`$$

DROP PROCEDURE IF EXISTS `gz_faltososAbandonos`$$

CREATE DEFINER=`admin`@`%` PROCEDURE `gz_faltososAbandonos`()
BEGIN
	DECLARE done INT DEFAULT FALSE;
        DECLARE V_dbname,V_provincia,V_distrito,V_us,tstring VARCHAR(45);
        DECLARE start_date_2months,end_date_2months,start_date_4months,end_date_4months VARCHAR(10);
        DECLARE lev,seg VARCHAR(15);
        DECLARE tint INT(4);
        DECLARE tdate1,tdate2 VARCHAR(45);
        -- DECLARE cur CURSOR FOR SELECT dbname,provincia,distrito,us FROM openmrs_reports.db_list;
        DECLARE cur CURSOR FOR SELECT dbname,provincia,distrito,us FROM openmrs_reports.db_inhambane;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	SET start_date_2months ='2018-09-21',end_date_2months = '2019-09-20';
	/*SET start_date_4months ='2018-01-21',end_date_4months = '2018-02-20';*/
	/*SET lev='Levantamento',seg='Seguimento';*/
	
	DROP TABLE IF EXISTS openmrs_reports.cd4;
	CREATE TABLE openmrs_reports.cd4 (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`nid` VARCHAR(50) NOT NULL DEFAULT '',
	`cd4_val` DOUBLE NOT NULL DEFAULT '0',
	`dataresultado` DATETIME DEFAULT NULL
		) ENGINE=INNODB DEFAULT CHARSET=utf8;
		
	DROP TABLE IF EXISTS openmrs_reports.DataUltimoCD4;
	CREATE TABLE openmrs_reports.DataUltimoCD4 (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`MaxDataResultado` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.UltimoCD4;
	CREATE TABLE openmrs_reports.UltimoCD4 (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`cd4_val` DOUBLE NOT NULL DEFAULT '0'
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.DataUltimaConsulta;
	CREATE TABLE openmrs_reports.DataUltimaConsulta (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`MaxDataConsulta` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.levantamentos;
	CREATE TABLE openmrs_reports.levantamentos (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`datalevantamento` DATETIME DEFAULT NULL,
	`dataproximolevantamento` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.DataUltimoLevantamento;
	CREATE TABLE openmrs_reports.DataUltimoLevantamento (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`MaxDataLevantamento` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.cargaviral;
	CREATE TABLE openmrs_reports.`cargaviral` (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`carga_viral` BIGINT(20) NOT NULL DEFAULT '0',
	`dataresultado` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.UltimoCV;
	CREATE TABLE openmrs_reports.UltimoCV (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`carga_viral` BIGINT(20) NOT NULL DEFAULT '0'
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.DataUltimoCV;
	CREATE TABLE openmrs_reports.DataUltimoCV (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`MaxDataCV` DATETIME DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.inicio_tarv_patient_id_cohort;
	CREATE TABLE openmrs_reports.`inicio_tarv_patient_id_cohort` (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`datainiciotarv` DATETIME DEFAULT NULL
		) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	   DROP TABLE IF EXISTS openmrs_reports.patient_list;	
	   CREATE TABLE openmrs_reports.`patient_list` (
	   `site` VARCHAR(50) NOT NULL DEFAULT '',
	  `patient_id` INT(11) NOT NULL DEFAULT '0',
	  `nid` VARCHAR(50) NOT NULL DEFAULT '',
	  `dataabertura` DATETIME DEFAULT NULL,
	  `contacto` VARCHAR(50) DEFAULT '',
	  `Nome` VARCHAR(50) DEFAULT NULL,
	  `apelido` VARCHAR(50) DEFAULT NULL,
	  `sexo` VARCHAR(50) DEFAULT '',
	  `datanasc` DATE DEFAULT NULL,
	  `idade` DECIMAL(9,0) DEFAULT NULL,
	  `proveniencia` VARCHAR(22) DEFAULT NULL,
	  `estadopaciente` VARCHAR(16) NOT NULL DEFAULT '',
	  `dataestado` DATE DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	
	DROP TABLE IF EXISTS openmrs_reports.gz_faltososAbandonos;	
	   CREATE TABLE openmrs_reports.`gz_faltososAbandonos` (
	   `site` VARCHAR(50) NOT NULL DEFAULT '',
	  `patient_id` INT(11) NOT NULL DEFAULT '0',
	  `nid` VARCHAR(50) NOT NULL DEFAULT '',
	  `dataabertura` DATETIME DEFAULT NULL,
	  `datainiciotarv` DATETIME DEFAULT NULL,
	   `sexo` VARCHAR(50) DEFAULT '',
	   `idade` DECIMAL(9,0) DEFAULT NULL,
	   `gravida` VARCHAR(50) DEFAULT '',
	   `UltimaCargaViral` INT(11) DEFAULT NULL,
	   `UltimoCD4` INT(11) DEFAULT NULL,
	   `dataultimolevantamento` DATETIME DEFAULT NULL,
	   `dataproximolevantamento` DATETIME DEFAULT NULL,
	  `diasfalta` INT(5) NOT NULL DEFAULT '0',
	  `dataultimaconsulta` DATE DEFAULT NULL,
	  `estadopaciente` VARCHAR(16) NOT NULL DEFAULT '',
	  `dataestado` DATE DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	
	DROP TABLE IF EXISTS openmrs_reports.gravidas_cohort;
	CREATE TABLE openmrs_reports.`gravidas_cohort` (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL,
	DataGravida DATE DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.gravidas;
	CREATE TABLE openmrs_reports.`gravidas` (
	`site` VARCHAR(50) NOT NULL DEFAULT '',
	`patient_id` INT(11) NOT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	DROP TABLE IF EXISTS openmrs_reports.consultas_clinicas;
	CREATE TABLE openmrs_reports.`consultas_clinicas` (
	`patient_id` INT(11) NOT NULL DEFAULT '0',
	`dataconsulta` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00'
	) ENGINE=INNODB DEFAULT CHARSET=utf8;
	
	
	
	OPEN cur;
	
	curLoop: LOOP
         FETCH  cur INTO V_dbname,V_provincia,V_distrito,V_us;
	/*FETCH NEXT FROM cur INTO dbname;*/
        IF done THEN
	  SELECT 'FIM';
         LEAVE curLoop;
	  CLOSE cur;
    
	ELSE
		
	/* INICIOS DE TARV NO PERIODO DE REPORT */
		DELETE FROM openmrs_reports.inicio_tarv_patient_id_cohort;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.inicio_tarv_patient_id_cohort ', 
		'SELECT DISTINCT "',TRIM(V_us),'" AS site , patient_id,datainiciotarv FROM
 
		(SELECT DISTINCT patient_id,MIN(datainiciotarv) datainiciotarv
		FROM
			( 
			
			SELECT    e.patient_id,MIN(e.encounter_datetime) datainiciotarv
			FROM     ',TRIM(V_dbname),'.encounter e INNER JOIN ',TRIM(V_dbname),'.obs o ON o.encounter_id=e.encounter_id
			WHERE   e.voided=0 AND o.voided=0 AND 
											e.encounter_type IN (6,9) AND o.concept_id=1255 AND o.value_coded=1256 AND 
											e.encounter_datetime <=  "',TRIM(end_date_2months),'"
			GROUP BY e.patient_id
			UNION
			
			SELECT    e.patient_id,MIN(o.value_datetime) datainiciotarv
			FROM      ',TRIM(V_dbname),'.encounter e INNER JOIN ',TRIM(V_dbname),'.obs o ON e.encounter_id=o.encounter_id
			WHERE     e.voided=0 AND o.voided=0 AND e.encounter_type IN (6,9) AND 
											o.concept_id=1190 AND o.value_datetime <=  "',TRIM(end_date_2months),'"
			GROUP BY e.patient_id
			UNION
			 
			SELECT    patient_id,date_enrolled datainiciotarv
			FROM      ',TRIM(V_dbname),'.patient_program
			WHERE   voided=0 AND program_id=2 AND date_enrolled <=  "',TRIM(end_date_2months),'"
						
			UNION
						
						
			SELECT        patient_id, MIN(encounter_datetime) AS datainiciotarv 
			FROM          ',TRIM(V_dbname),'.encounter 
			WHERE          encounter_type=18 AND voided=0 
			GROUP BY      patient_id HAVING MIN(encounter_datetime) <= "',TRIM(end_date_2months),'"
		) inicios
	GROUP BY patient_id 
    
	) iniciotarv');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
		
		/* CONSULTAS CLINICAS */
		DELETE FROM openmrs_reports.consultas_clinicas;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.consultas_clinicas(patient_id,dataconsulta)
SELECT DISTINCT consultas.patient_id, dataconsulta FROM
(
			 /* Data da consulta*/			
			SELECT        patient_id, encounter_datetime dataconsulta 
			FROM          ',TRIM(V_dbname),'.encounter 
			WHERE          encounter_type IN (5,6,7,9) AND voided=0 
			AND encounter_datetime BETWEEN "',TRIM(start_date_2months),'" AND "',TRIM(end_date_2months),'"
   ) consultas		
INNER JOIN
openmrs_reports.inicio_tarv a
 ON (consultas.patient_id = a.patient_id)
 ORDER BY consultas.patient_id, dataconsulta');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
			/* CD4 */
			DELETE FROM openmrs_reports.cd4;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.cd4(SITE, patient_id,nid,cd4_val,dataresultado)
SELECT DISTINCT "',TRIM(V_us),'" AS site ,
        o1.person_id AS patient_id,
        `pi`.`identifier` AS `nid`,
       
        `o2`.`value_numeric` AS `cd4_val`,
        CAST(`o1`.`value_datetime` AS DATE) AS `dataresultado`
    FROM
        (((',TRIM(V_dbname),'.`person` `pe`
        JOIN ',TRIM(V_dbname),'.`patient_identifier` `pi` ON ((`pe`.`person_id` = `pi`.`patient_id`)))
        JOIN ',TRIM(V_dbname),'.`obs` `o1` ON ((`pi`.`patient_id` = `o1`.`person_id`)))
        JOIN ',TRIM(V_dbname),'.`obs` `o2` ON (((`o1`.`person_id` = `o2`.`person_id`)
            AND (`o1`.`encounter_id` = `o2`.`encounter_id`)
            AND (`o1`.`concept_id` <> `o2`.`concept_id`)
            AND (`o1`.`concept_id` = 6256)
            AND ((`o2`.`concept_id` = 1695)
            OR (`o2`.`concept_id` = 5497)))))
    WHERE
        (',TRIM(V_dbname),'.`pi`.`identifier_type` = 2)
    ORDER BY ',TRIM(V_dbname),'.`pi`.`identifier` , `o1`.`value_datetime`');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	
/* DataUltimoCD4 */
DELETE FROM openmrs_reports.DataUltimoCD4;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.DataUltimoCD4(SITE, patient_id,MaxDataResultado)
SELECT site,patient_id, MAX(dataresultado) AS MaxDataResultado FROM openmrs_reports.cd4 GROUP BY site,patient_id');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
		
				/* DataUltimoCD4 */
				DELETE FROM openmrs_reports.DataUltimaConsulta;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.DataUltimaConsulta(SITE, patient_id,MaxDataConsulta)
SELECT site,patient_id, MAX(dataseguimento) AS MaxDataConsulta FROM (
SELECT DISTINCT "',TRIM(V_us),'" AS site ,
	pe.person_id AS `patient_id`,
         CAST(`e`.`encounter_datetime` AS DATE) AS `dataseguimento`,
         CAST(`o1`.`value_datetime` AS DATE) AS `dataproximaconsulta`
        
    FROM
        ((',TRIM(V_dbname),'.`person` `pe`
        JOIN ',TRIM(V_dbname),'.`encounter` `e` ON (((`pe`.`person_id` = `e`.`patient_id`)
            AND (`e`.`encounter_type` IN (5,6,7,9))
            AND (`e`.`voided` = 0))))
	LEFT JOIN ',TRIM(V_dbname),'.`obs` `o1` ON (((`pe`.`person_id` = `o1`.`person_id`)
            AND (`e`.`encounter_id` = `o1`.`encounter_id`)
            AND (`o1`.`concept_id` = 1410))))
     WHERE    CAST(`e`.`encounter_datetime` AS DATE)<= "',TRIM(end_date_2months),'"  AND o1.voided=0 
      ) X GROUP BY site,patient_id ');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
/* CV */
DELETE FROM openmrs_reports.levantamentos;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.levantamentos(SITE, patient_id,datalevantamento,dataproximolevantamento)
SELECT DISTINCT "',TRIM(V_us),'" AS site ,
       	`pi`.patient_id,
	 CAST(`e`.`encounter_datetime` AS DATE) AS `datalevantamento`,
         CAST(`o2`.`value_datetime` AS DATE) AS `dataproximolevantamento`
     FROM
        ((',TRIM(V_dbname),'.`patient_identifier` `pi` 
        JOIN ',TRIM(V_dbname),'.`encounter` `e` ON (((`pi`.`patient_id` = `e`.`patient_id`)
            AND (`e`.`encounter_type` = 18) AND (`pi`.`identifier_type` = 2)
            AND (`e`.`voided` = 0))))
	LEFT JOIN ',TRIM(V_dbname),'.`obs` `o2` ON (((`e`.`patient_id` = `o2`.`person_id`)
            AND (`e`.`encounter_id` = `o2`.`encounter_id`)
            AND (`o2`.`concept_id` = 5096))))
         WHERE  CAST(`e`.`encounter_datetime` AS DATE)<= "',TRIM(end_date_2months),'"  AND o2.voided=0 
         ORDER BY `pi`.patient_id, CAST(`e`.`encounter_datetime` AS DATE)');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;		
	
	
/* DataUltimoLevantamento */
DELETE FROM openmrs_reports.DataUltimoLevantamento;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.DataUltimoLevantamento(SITE, patient_id,MaxDataLevantamento)
SELECT site ,patient_id, MAX(datalevantamento) AS MaxDataLevantamento FROM openmrs_reports.levantamentos GROUP BY site,patient_id');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
			
/* CV */
DELETE FROM openmrs_reports.cargaviral;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.cargaviral(SITE, patient_id,carga_viral,dataresultado)
SELECT "',TRIM(V_us),'" AS site ,e.patient_id, o.`value_numeric` AS carga_viral,e.encounter_datetime AS dataresultado  FROM ',TRIM(V_dbname),'.encounter e INNER JOIN ',TRIM(V_dbname),'.obs o ON (e.patient_id=o.person_id AND e.encounter_id=o.encounter_id)
 WHERE e.encounter_type IN (6,9) AND e.voided=0 AND o.concept_id=856 AND o.voided=0 AND e.encounter_datetime <= "',TRIM(end_date_2months),'"');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
/* DataUltimoCV */
DELETE FROM openmrs_reports.DataUltimoCV;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.DataUltimoCV(SITE, patient_id,MaxDataCV)
SELECT site,patient_id, MAX(dataresultado) AS MaxDataCV FROM openmrs_reports.cargaviral GROUP BY site,patient_id');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
		
/*patient_list*/
DELETE FROM openmrs_reports.patient_list;
SET @SQL := CONCAT('INSERT INTO openmrs_reports.patient_list
     SELECT DISTINCT
	"',TRIM(V_us),'" AS site ,
	`pe`.`person_id` AS `patient_id`,
        `pi`.`identifier` AS `nid`,
         IF(`e`.`encounter_datetime` IS NOT NULL,`e`.`encounter_datetime`, `pp1`.`date_enrolled`) AS `dataabertura`,
        `pt`.`value` AS `contacto`,
        `pn`.`given_name` AS `Nome`,
        `pn`.`family_name` AS `apelido`,
        `pe`.`gender` AS `sexo`,
        `pe`.`birthdate` AS `datanasc`,
        ROUND(((TO_DAYS(`pp1`.`date_enrolled`) - TO_DAYS(`pe`.`birthdate`)) / 365.25),
                0) AS `idade`,
         (CASE `prov`.`value_coded`
            WHEN 1595 THEN ','"INTERNAMENTO"','
            WHEN 1386 THEN ','"CLINICA MOVEL"','
            WHEN 1599 THEN ','"PROVEDOR PRIVADO"','
            WHEN 1939 THEN ','"PTV"','
            WHEN 1414 THEN ','"PNCTL"','
            WHEN 1596 THEN ','"CONSULTA EXTERNA"','
            WHEN 844 THEN ','"HDD"','
            WHEN 5622 THEN ','"OUTRO"','
            WHEN 978 THEN ','"PROPRIO"','
            WHEN 1984 THEN ','"UNIDADE SANITARIA"','
            WHEN 1987 THEN ','"GATV/SAAJ"','
            WHEN 1932 THEN ','"PROFISSIONAL DE SAUDE"','
            WHEN 1275 THEN ','"CENTRO DE SAUDE"','
            WHEN 1872 THEN ','"CCR"','
            WHEN 1044 THEN ','"ENF. PEDIATRIA"','
            WHEN 1986 THEN ','"SEGUNDO SITIO"','
            WHEN 1369 THEN ','"TRANSFERIDO DE"','
            WHEN 1699 THEN ','"CUIDADOS DOMICILIARIOS"','
            WHEN 2160 THEN ','"VISITA DE BUSCA"','
            WHEN 6288 THEN ','"SMI"','
            WHEN 5484 THEN ','"APOIO NUTRICIONAL"','
            WHEN 6245 THEN ','"ATSC"','
            WHEN 1598 THEN ','"MEDICO TRADICIONAL"','
            ELSE ','"Outro"','
        END) AS `proveniencia`,
		(CASE `ps`.`state`
			WHEN 2 THEN ','"ABANDONO"','
			WHEN 3 THEN ','"TRANSFERIDO PARA"','
			WHEN 5 THEN ','"OBITO"','
			WHEN 7 THEN ','"TRANSFERIDO PARA"','
			WHEN 8 THEN ','"SUSPENSO"','
			WHEN 9 THEN ','"ABANDONO"','
			WHEN 10 THEN ','"OBITO"','
			WHEN 20 THEN ','"ABANDONO"','
			WHEN 22 THEN ','"OBITO"','
			WHEN 21 THEN ','"TRANSFERIDO PARA"','
            ELSE ','"ACTIVO"','
           
        END) AS `estadopaciente`,
	`ps`.`start_date` AS dataestado	
    FROM
        (((((((((',TRIM(V_dbname),'.`person` `pe`
        JOIN ',TRIM(V_dbname),'.`patient_identifier` `pi` ON (((`pe`.`person_id` = `pi`.`patient_id`)
            AND (`pi`.`identifier_type` = 2) AND (pi.voided=0))))
	LEFT JOIN ',TRIM(V_dbname),'.`person_attribute` `pt` ON (((`pt`.`person_id` = `pe`.`person_id`)
            AND (`pt`.`person_attribute_type_id` = 9) AND (pt.voided=0))))
        LEFT JOIN ',TRIM(V_dbname),'.`person_name` `pn` ON (((`pe`.`person_id` = `pn`.`person_id`)
            AND (`pn`.`voided` = 0))))
        LEFT JOIN ',TRIM(V_dbname),'.`encounter` `e` ON (((`pe`.`person_id` = `e`.`patient_id`)
            AND (`e`.`voided` = 0) AND (e.encounter_type IN (5,7)))))
       LEFT JOIN ',TRIM(V_dbname),'.`patient_program` `pp1` ON (((`pe`.`person_id` = `pp1`.`patient_id`)
            AND (`pp1`.`voided` = 0)
            AND (`pp1`.`program_id` = 1))))
	LEFT JOIN ',TRIM(V_dbname),'.`patient_program` `pp2` ON (((`pe`.`person_id` = `pp2`.`patient_id`)
            AND (`pp2`.`program_id` = 2)
            AND (`pp2`.`voided` = 0))))
	LEFT JOIN ',TRIM(V_dbname),'.`obs` `prov` ON (((`pe`.`person_id` = `prov`.`person_id`)
            AND (`prov`.`concept_id` = 1594)))))
        left JOIN ',TRIM(V_dbname),'.`patient_state` `ps` ON (((IF(`pp2`.`patient_program_id` IS NOT NULL,`pp2`.`patient_program_id`,`pp1`.`patient_program_id`) = `ps`.`patient_program_id`)
            AND (`ps`.`voided` = 0) AND (ps.end_date IS NULL)))) 
       WHERE pe.person_id IN (SELECT DISTINCT patient_id FROM openmrs_reports.consultas_clinicas)        
       ORDER BY `pi`.`identifier`');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
	
	
/* gravidas NO PERIODO DE REPORT */
DELETE FROM openmrs_reports.gravidas_cohort;
   SET @SQL := CONCAT('INSERT INTO openmrs_reports.gravidas_cohort(site,patient_id,DataGravida)
   SELECT DISTINCT "',TRIM(V_us),'" AS site ,
       o.person_id AS patient_id,
       CAST(e.encounter_datetime AS DATE) as DataGravida
    FROM
         (',TRIM(V_dbname),'.`encounter` `e`	
         INNER JOIN ',TRIM(V_dbname),'.`obs` `o` ON ((`e`.`encounter_id` = `o`.`encounter_id`)
            AND (`o`.`voided` = 0)
            AND (`o`.`concept_id` = 1982)
			AND (`o`.`value_coded` = 44)))
   WHERE CAST(e.encounter_datetime AS DATE) <="',TRIM(end_date_2months),'"
   UNION
   SELECT DISTINCT "',TRIM(V_us),'" AS site ,
       pp.patient_id,pp.date_enrolled as DataGravida
    FROM
         ',TRIM(V_dbname),'.`patient_program` `pp`	
         
   WHERE pp.voided=0 AND program_id=3 AND CAST(pp.date_enrolled AS DATE) <= "',TRIM(end_date_2months),'"');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
/* preencher o campo Province */
DELETE FROM openmrs_reports.UltimoCD4;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.UltimoCD4
        SELECT a.site, a.patient_id, a.cd4_val FROM openmrs_reports.cd4 a INNER JOIN openmrs_reports.DataUltimoCD4 b ON a.site=b.site
	AND a.patient_id=b.patient_id AND a.dataresultado=b.MaxDataResultado AND Trim(a.site)="',TRIM(V_us),'"');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
/* valor CV */
	DELETE FROM openmrs_reports.UltimoCV;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.UltimoCV
        SELECT a.site, a.patient_id, a.carga_viral FROM openmrs_reports.cargaviral a INNER JOIN openmrs_reports.DataUltimoCV b ON a.site=b.site
	AND a.patient_id=b.patient_id AND a.dataresultado=b.MaxDataCV AND Trim(a.site)="',TRIM(V_us),'"');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
		
 /* Gravidas */
 DELETE FROM openmrs_reports.gravidas;
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.gravidas
        SELECT a.site,a.patient_id FROM openmrs_reports.inicio_tarv_patient_id_cohort a INNER JOIN openmrs_reports.gravidas_cohort b 
	ON a.site=b.site AND a.patient_id=b.patient_id AND TIMESTAMPADD(DAY,15,a.datainiciotarv) >= b.DataGravida AND Trim(a.site)="',TRIM(V_us),'"');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
		
		
	/* faltososAbandonos */
		SET @SQL := CONCAT('INSERT INTO openmrs_reports.gz_faltososAbandonos
        SELECT pl.site,
		pl.patient_id,
		pl.nid,
		pl.dataabertura,
		it.datainiciotarv,
		pl.sexo,
		pl.idade,
		IF(gr.patient_id IS NOT NULL,','"SIM",','"NAO"',') AS gravida,
		ucv.carga_viral as UltimaCargaViral,
		ucd4.cd4_val as UltimoCD4,
		ulev.MaxDataLevantamento,
		lev.dataproximolevantamento,
		(TO_DAYS("',TRIM(end_date_2months),'") - TO_DAYS(`lev`.`dataproximolevantamento`)) AS diasfalta,
		ucons.MaxDataConsulta,
		pl.estadopaciente,
		pl.dataestado
		
	FROM
		((((((openmrs_reports.patient_list pl INNER JOIN openmrs_reports.inicio_tarv_patient_id_cohort it
			ON (pl.site=it.site AND pl.patient_id=it.patient_id AND pl.site="',TRIM(V_us),'"))
		LEFT JOIN openmrs_reports.gravidas gr ON (pl.site=gr.site AND pl.patient_id=gr.patient_id AND pl.site="',TRIM(V_us),'"))
		LEFT JOIN openmrs_reports.UltimoCV ucv ON (pl.site=ucv.site AND pl.patient_id=ucv.patient_id AND pl.site="',TRIM(V_us),'"))
		LEFT JOIN openmrs_reports.UltimoCD4 ucd4 ON (pl.site=ucd4.site AND pl.patient_id=ucd4.patient_id AND pl.site="',TRIM(V_us),'"))
		INNER JOIN openmrs_reports.DataUltimoLevantamento ulev ON (pl.site=ulev.site AND pl.patient_id=ulev.patient_id AND pl.site="',TRIM(V_us),'"))
		INNER JOIN openmrs_reports.levantamentos lev ON (pl.site=lev.site AND pl.patient_id=lev.patient_id AND pl.site="',TRIM(V_us),'"))
		LEFT JOIN openmrs_reports.DataUltimaConsulta ucons ON (pl.site=ucons.site AND pl.patient_id=ucons.patient_id AND pl.site="',TRIM(V_us),'")
	WHERE (((TO_DAYS("',TRIM(end_date_2months),'") - TO_DAYS(`lev`.`dataproximolevantamento`))>=15 AND `lev`.`dataproximolevantamento` IS NOT NULL ) OR
		((TO_DAYS("',TRIM(end_date_2months),'") - TO_DAYS(`lev`.`datalevantamento`))>=45 AND `lev`.`dataproximolevantamento` IS NULL ))
		AND ulev.MaxDataLevantamento=lev.datalevantamento');
		PREPARE stmt FROM @SQL;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;					
		END IF;
 END LOOP;
 CLOSE cur;				
    END$$

DELIMITER ;