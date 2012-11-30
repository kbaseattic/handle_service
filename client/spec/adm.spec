/* Note: this spec was reverse-engineered and is NOT currently used to build the client libraries. It's here for reference only. */
/* Top-level description of service goes here */
module adm {

	/* GENERIC DATA TYPES */

	/* A Boolean data type */
	typedef int Boolean;

	/* A user id */
	typedef string Uuid;

	/* The name of a file including path information */
	typedef string Filename;

	/* The size of a file in bytes */
	typedef int Filesize;

	/* Any error message returned */
	typedef string Error;

	/* The HTTP response code */
	typedef int Httpcode;


	/* 
	   NODE SECTION (THE DEFINITIONS BELOW NEED WORK)
	   WE NEED BASIC DEFINITIONS OF THE FOLLOWING TERMS FOR THE USER
	   1) NODE - A CONCEPT THAT INCLUDES A DATA FILE AND META-DATA.
                     THE META-DATA IS REFERRED TO AS NODE DATA AND DESCRIBES
		     THE DATA FILE AS WELL AS ACCESS CONTROLS, FILE INDEXES,
		     AND VERSION INFO.
	   2) NODE DATA - THE META-DATA THAT DESCRIBES THE DATA FILE
	   3) NODE RESPONSE WRAPPER - A STRUCTURE THAT THE USER
		RECEIVES WHEN QUERYING FOR A NODE. THE STRUCTURE CONTAINS
		THE NODE DATA, ANY ERROR STRINGS, AND THE HTTP RESPONSE CODE.
	*/

	/* The node id */
	typedef string Identifier;

	/*
	   A file fingerprint is a data structure that contains a md5 and/or
	   sha1 digest string for that file.
	*/
	typedef structure {
		string md5;
        	string sha1;
	} Fingerprint;


	/*
	   A file data structure is a data structure that contains the file
	   fingerprint, the file name and the file size.
	*/

	typedef structure {
        	Fingerprint checksum;
        	Filename name;
        	Filesize size;
	} File;

	/*
	   Node data has a field named attributes. The attributes field
	   contains an arbitrary json string that becomes queryable through
	   the API. Because the value of the attribute field is an arbitrary
	   JSON string, the best we can do is declare the value as a string.
	*/
	typedef string Attributes;

	/* A list of users who can delete this node */
	typedef list<Uuid> Delete;

	/* A list of users who can read this node */
	typedef list<Uuid> Read;

	/* A list of users who can write to this node */
	typedef list<Uuid> Write;

	/*
	   The acls are a list of uuids corresponding to read, write and
	   delete access controls on node data. The Uuids found in the list
	   namde delete have delete permissions on the node, Uuids found in
	   the list named read have read permissions on the node, and the
	   same for the list named write.
	*/
	typedef structure {
		list<Uuid> delete;
		list<Uuid> read;
		list<Uuid> write;
	} Acl;

	/* This is a json object for indexes, just a kludge for now */
	typedef string Index;

	/* A version identifier for this node */
	typedef string Version;

	/* Version identifiers for acls, attributes, and file */
	typedef string AclVersion;
	typedef string AttributesVersion;
	typedef string FileVersion;
	typedef structure {
		AclVersion acl_ver;
		AttributesVersion attributes_ver;
		FileVersion file_ver;
	} VersionParts;

	/* OK, we've defined the basic parts of the node data. */

	/*
	   Node data has seven parts that are defined above.They are id,
	   file, attributes, acl, indexes, version, and version_parts.
	   The node data is returned as the data part (D) in the node
	   response wrapper. Node data becomes immutable as the file and
	   attributes fields are set.
	*/
	typedef structure {
		Identifier id;
		File file;
		Attributes attributes;
		Acl acl;
		Index indexes;
		Version version;
		VersionParts version_parts;
	} Nodedata;

	/*
	   This is a response wrapper for node data. The Nodedata structure 
	   described above along with an error string and the http return code
	   are wrapped in the node response wrapper.
	*/
	typedef structure {
		Nodedata D;
		Error E;
		Httpcode S;
	} NodeResponseWrapper;


	/* USER SECTION. */


	/* A user name */
	typedef string Username;

	/* A user password */
	typedef string Password;

	
	/* User data has four parts: uuid, name, passwd, and admin. */
	typedef structure {
		Uuid uuid;
		Username name;
		Password passwd;
		Boolean admin;
	} Userdata;

	/*
	   Ths is the response wrapper for a user. The Userdata described
	   above along with an error string and a http return code are
	   wrapped in the User response wrapper.
	*/
	typedef structure {
		Userdata D;
		Error E;
		Httpcode S;
	} User;


	/* INDEX SECTION */
	
	/* The index type. Currnt types are 'size' */
	typedef string Indextype;
	typedef string Filename;
	typedef string Checksumtype;
	typedef string Version;
	typedef list<string> IndexLocations;

	typedef structure {
		Indextype index_type;
		Filename filename;
		Checksumtype checksum_type;
		Version version;
		IndexLocations index;
	} Index;




	/* Get a resource listing */
	funcdef resourceListing()returns(string listing);
 	

	/* Create a user */
	funcdef createUser(Username n, Password p) returns (User u);


	/*
	   node parameters:
	   - attributes is the name of a file with full path information
	     where the json formatted attributes resides.    
	   - file is the name of the file with full path information where
	     the data to be loaded resides.
	*/

	typedef structure {
		string attributes;
		string file;
	} Nodeparams;

	/* Create a node */
	funcdef createNode(Username n, Password p, Nodeparams np) returns (NodeResponseWrapper n);

	/* Modify a node. */
	funcdef modifyNode(Username n, Password p, Nodeparams np) returns (NodeResponseWrapper n);


	/*
	   node search parameters.       
	   - by adding skip you get the nodes starting at skip+1.              
	   - by adding limit you get a maximum of limit nodes returned.
	   - query must be in the form key=value where key is the name
             of a field in the node's attributes and value is the value
             matched.
	*/
	 
	typedef structure {
		int skip;
		int limit;
		string query;
	} Searchparams;

	/* List nodes */
	funcdef listNodes(Username n, Password p, Searchparams sp) returns (list<NodeResponseWrapper> nodes);


	/*
	  View parameters.
	  - download - default is false. when true the data file is downloaded
	    and sent to stdout.
	  - index - available index values are 'size'. parts is required when
	    index=size
	  - chunksize - default is 1048578 bytes (1Mb), when index=size and
	    parts=1,2 
	  - parts - this should be a comma seperated list of integers. Let's
	    say you set chunksize to 1000 and parts to 1,2,3, then you call
	    viewNodes passing in chucksize and parts, you would receive back
	    the first 1000 bytes of the file and the second 1000 bytes of the
	    file on STDOUT.
	*/
	typedef structure {
		Boolean download;
		string index;
		int chunksize;
		list<int> parts;
	} Viewparams;
	 
	/* View nodes */
	funcdef viewNodes(Username n, Password p, Identifier id, Viewparams v) returns();


};
