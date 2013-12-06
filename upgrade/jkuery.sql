CREATE DATABASE IF NOT EXISTS `JKUERY` /*!40100 DEFAULT CHARACTER SET utf8 */;
CREATE TABLE IF NOT EXISTS  `JKUERY`.`JSON` (
  `ID` tinyint(4) NOT NULL AUTO_INCREMENT,
  `ORG` tinyint(4) unsigned NOT NULL DEFAULT '1',
  `HD_TICKET_RULE_ID` tinyint(3) unsigned DEFAULT NULL,
  `JDATA` mediumtext,
  `SQLstr` text,
  `PURPOSE` varchar(200) NOT NULL DEFAULT '',
  `CREATED` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `MODIFIED` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `ORG_IDX` (`ORG`)
) ENGINE=MyISAM AUTO_INCREMENT=100 DEFAULT CHARSET=utf8;

ALTER TABLE `JKUERY`.`JSON` CHANGE COLUMN `ID` `ID` INT UNSIGNED  NOT NULL AUTO_INCREMENT;
ALTER TABLE `JKUERY`.`JSON` CHANGE COLUMN `ORG` `ORG` INT UNSIGNED NOT NULL DEFAULT '1' ;
ALTER TABLE `JKUERY`.`JSON` CHANGE COLUMN `HD_TICKET_RULE_ID` `HD_TICKET_RULE_ID` INT UNSIGNED NULL DEFAULT NULL ;
ALTER TABLE `JKUERY`.`JSON` CHANGE COLUMN `JDATA` `JDATA` VARCHAR(30) NULL DEFAULT '{}';
-- this could throw an exception so make sure to continue on error (i.e. force) wherever you care calling it from
ALTER TABLE `JKUERY`.`JSON` ADD COLUMN `QUERY_TYPE` VARCHAR(30) NOT NULL DEFAULT 'sqlp'  AFTER `MODIFIED` ;

-- this could throw an exception so make sure to continue on error (i.e. force) wherever you care calling it from
/* add a NAME column to JSON table for reference by name support */
ALTER TABLE `JKUERY`.`JSON` ADD COLUMN `NAME` VARCHAR(45) NOT NULL DEFAULT ''  AFTER `QUERY_TYPE` ;

DELIMITER //
DROP TRIGGER IF EXISTS JKUERY.ceationtimeJSON//
CREATE TRIGGER JKUERY.ceationtimeJSON
BEFORE INSERT ON JSON
FOR EACH ROW
BEGIN
	IF NEW.CREATED = '0000-00-00 00:00:00' THEN
	   SET NEW.CREATED = NOW();
        END IF;
	IF NEW.JDATA IS NULL THEN
	   SET NEW.JDATA = '{}';
	END IF;
	/* add a trigger to make new row for `NAME` unique by default when specified in an INSERT implicitly */
	if new.NAME = '' then
	   set new.NAME  =  LAST_INSERT_ID() + 1;
        end if;	  
END
//
DELIMITER ;
/* make sure that legacy entries have a default unique value for NAME by setting them to the PK */
update JKUERY.JSON set NAME = cast(ID as char) where NAME = '';

/* now we can alter the table to make NAME unique */ 
ALTER TABLE `JKUERY`.`JSON` 
ADD UNIQUE INDEX `NAME_UNIQUE` (`NAME` ASC) ;

replace into `JKUERY`.`JSON`(`NAME`,`SQLstr`,`PURPOSE`, CREATED,) values
 ('jKuery Version','select ''version'' as VERSION, VALUE from KBSYS.SETTINGS where NAME = ''JKUERY_VERSION'' ', 'Demo script for jkuery. Example URL would be jkuery/jKuery+Version', now());


/* add TOKENS table */
CREATE TABLE IF NOT EXISTS `JKUERY`.`TOKENS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TOKEN` varchar(45) NOT NULL,
  `ORIGIN` varchar(255) NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `TOKEN_UNIQUE` (`TOKEN`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

REPLACE INTO JKUERY.TOKENS(ID,TOKEN,ORIGIN)
select * from JKUERY.TOKENS UNION ALL select 1,'nothing','https?://nowhere.comfooey' limit 1;

