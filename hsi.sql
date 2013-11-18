#	typedef structure {
#		string file_name;
#		string id;
#		string type;
#		string url;
#		string remote_md5;
#		string remote_sha1;
#	} Handle;

DROP TABLE IF EXISTS `Handle`;
CREATE TABLE IF NOT EXISTS `Handle` (
	`id`	  	varchar(256) NOT NULL DEFAULT '',
	`file_name`     varchar(256),
	`type` 		varchar(256),
	`url` 		varchar(256),
	`remote_md5` 	varchar(256),
	`remote_sha1`	varchar(256),
	PRIMARY KEY (`id`)
); 
DROP USER 'hsi'@'localhost';
GRANT SELECT,INSERT,UPDATE,DELETE 
	ON hsi.*
	TO 'hsi'@'localhost'
	IDENTIFIED BY 'hsi-pass';
