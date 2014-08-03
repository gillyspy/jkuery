-- some constants
set @'jkver':='jKuery Version';
set @jkorg:=(select min(ID) from KBSYS.ORGANIZATION);
set @jkrole:=1;
set @'kver':='K1000 Version';
set @'sessionval':='Session Value';

CREATE DATABASE IF NOT EXISTS `JKUERY` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `JKUERY`;
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
) ENGINE=MyISAM AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;

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
	   set new.NAME  =  concat('jkuery',floor(rand(1000)*1000) );
        end if;	  
END
//
DELIMITER ;
/* make sure that legacy entries have a default unique value for NAME by setting them to the PK */
update JKUERY.JSON set NAME = cast(ID as char) where NAME = '';

/* now we can alter the table to make NAME unique */ 
ALTER TABLE `JKUERY`.`JSON` 
ADD UNIQUE INDEX `NAME_UNIQUE` (`NAME` ASC) ;



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

-- what users are allowed based upon label associations
CREATE TABLE IF NOT EXISTS `JSON_LABEL_JT` (
  `JSON_ID` int(11) NOT NULL,
  `ORG_ID` int(11) NOT NULL,
  `LABEL_ID` int(11) NOT NULL,
  PRIMARY KEY (`JSON_ID`,`ORG_ID`,`LABEL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- what users are allowed based upon role associations
CREATE TABLE IF NOT EXISTS `JSON_ROLE_JT` (
  `JSON_ID` int(11) NOT NULL,
  `ORG_ID` int(11) NOT NULL,
  `ROLE_ID` int(11) NOT NULL,
  PRIMARY KEY (`JSON_ID`,`ORG_ID`,`ROLE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- mapping of given token for a remote connection to use an existing user 
CREATE TABLE IF NOT EXISTS `JSON_TOKENS_JT` (
  `JSON_ID` int(10) unsigned NOT NULL, /* not used as of 2.2 */
  `ORG_ID` int(10) unsigned NOT NULL,
  `TOKENS_ID` int(10) unsigned NOT NULL,
  `USER_ID` int(10) unsigned NOT NULL,
  PRIMARY KEY (`JSON_ID`,`ORG_ID`,`TOKENS_ID`,`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- insert demo query
replace into `JKUERY`.`JSON`(`NAME`,`SQLstr`,`PURPOSE`, CREATED) values
 (@jkver,
 'select ''version'' as VERSION, VALUE from KBSYS.SETTINGS where NAME = ''JKUERY_VERSION'' ',
 'Demo script for jkuery. Example URL would be jkuery/jKuery+Version', now());

-- by default only the admin user in ORG1 can access it
replace into JKUERY.JSON_ROLE_JT(JSON_ID, ORG_ID, ROLE_ID) select ID, @jkorg, @jkrole from JSON 
where JSON.NAME=@jkver;


replace into JKUERY.JSON(SQLstr,PURPOSE,QUERY_TYPE,NAME,CREATED)
	values (
	       'select "version", concat(MAJOR,''.'',MINOR,''.'',BUILD) KVERSION from JKUERY.KBOX_VERSION ',
	       'return K1000 version',
	       'sqlp',
	       @kver,
	       now()
	);

replace into JKUERY.JSON_ROLE_JT(JSON_ID, ORG_ID, ROLE_ID) select ID, @jkorg, @jkrole from JSON 
where JSON.NAME=@kver;

-- OEM service
replace into JKUERY.JSON(SQLstr,PURPOSE,QUERY_TYPE,NAME,CREATED)
	values (
	       'select "value", ?',
	       'return the first paramater provided',
	       'sqlp',
	       @sessionval,
	       now()
	);
			
-- create a view for version since OEM version shows the license key
create view JKUERY.KBOX_VERSION as select MAJOR, MINOR,BUILD from KBSYS.KBOX_VERSION where ID=1;

-- 
ALTER TABLE `JKUERY`.`JSON` ADD COLUMN `INSERTstr` text NULL AFTER `SQLstr` ;
ALTER TABLE `JKUERY`.`JSON` ADD COLUMN `UPDATEstr` text NULL AFTER `INSERTstr`;
ALTER TABLE `JKUERY`.`JSON` ADD COLUMN `DELETEstr` text NULL AFTER  `UPDATEstr` ;

/* allow all roles to access some default servies */
replace into `JKUERY`.`JSON_ROLE_JT` (`JSON_ID`, `ORG_ID`, `ROLE_ID`)
	select ID, 0, 0
	from JKUERY.JSON
	where NAME in (@jkver, @kver, @sessionval);


	
/* a new column to allow default parms in the service definition
e.g. :USER_ID as a server-side parm */
ALTER TABLE `JKUERY`.`JSON` 
ADD COLUMN `SQLParms` VARCHAR(255) NOT NULL DEFAULT '' AFTER `SQLstr`;

ALTER TABLE `JKUERY`.`JSON` 
ADD COLUMN `INSERTParms` VARCHAR(255) NOT NULL DEFAULT '' AFTER `INSERTstr`;

ALTER TABLE `JKUERY`.`JSON` 
ADD COLUMN `UPDATEParms` VARCHAR(255) NOT NULL DEFAULT '' AFTER `UPDATEstr`;

ALTER TABLE `JKUERY`.`JSON` 
ADD COLUMN `DELETEParms` VARCHAR(255) NOT NULL DEFAULT '' AFTER `DELETEstr`;

