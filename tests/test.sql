/* full CRUD example */
INSERT INTO `JKUERY`.`JSON` (`SQLstr`, `INSERTstr`, `UPDATEstr`, `DELETEstr`, `QUERY_TYPE`, `NAME`) VALUES ('select * from USER where ID=?', 'insert into USER(USER_NAME, EMAIL, PASSWORD,ROLE_ID) values(?,?,\'*',3)', 'update USER set FULL_NAME where USER_NAME = ?', 'DELETE from USER where ID = ? and USER_NAME = ? ', 'sqlp', 'full crud example');

/* ticket rule */

/* run all rules test */
INSERT INTO `JKUERY`.`JSON` (`HD_TICKET_RULE_ID`, `JDATA`, `SQLstr`, `QUERY_TYPE`, `NAME`) VALUES ('6', '{}', 'select ?, ?', 'runallrules', 'run all rules test');


insert into JKUERY.JSON_ROLE_JT values(0,1,5);
insert into JKUERY.JSON_ROLE_JT values(0,1,6);
insert into JKUERY.JSON_LABEL_JT values(0,1,48);


