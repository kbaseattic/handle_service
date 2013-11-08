/* The AbstractHandle module provides a programmatic
   access to a remote file store.
*/
module AbstractHandle {

	/* Handle provides a unique reference that enables
	   access to the data files through functions
	   provided as part of the HandleService. In the case of using
	   shock, the id is the node id. In the case of using
	   shock the value of type is shock. In the future 
	   these values should enumerated. The value of url is
	   the http address of the shock server, including the
	   protocol (http or https) and if necessary the port.
	   The values of remote_md5 and remote_sha1 are those
	   computed on the file in the remote data store. These
	   can be used to verify uploads and downloads.
	*/
	typedef structure {
		string file_name;
		string id;
		string type;
		string url;
		string remote_md5;
		string remote_sha1;
	} Handle;

	
	/* new_handle returns a Handle object with a url and a node id */
	funcdef new_handle() returns (Handle h) authentication required;

	/* The localize_handle function attempts to locate a shock server near
 	   the service. The localize_handle function must be called before the
	   Handle is initialized becuase when the handle is initialized, it is
	   given a node id that maps to the shock server where the node was
	   created.
	 */
	funcdef localize_handle(Handle h1, string service_name)
		returns (Handle h2);

	/* initialize_handle returns a Handle object with an ID. */
	funcdef initialize_handle(Handle h1) returns (Handle h2) 
		authentication required;

	/* These provides an empty implementation so that if a concrete
	   implementation is not provided an error is thrown. These are
	   the equivelant of abstract methods, with runtime rather than
	   compile time inforcement.
	*/
	funcdef upload(string infile) returns(Handle h) 
		authentication required;
	funcdef download(Handle h, string outfile) returns()
		authentication required;
	
	/* Not sure if these should be abstract or concrete. If concete
	   then we don't have to hand roll an implemetation for the four
	   different supported languages. The cost is an extra network
	   hop. For now, I choose the extra network hop over implementing
	   the same method by hand in for different languages. I belive it
	   to be a safe assumption that the metadata won't exceed several
	   megabytes in size.
	*/
	funcdef upload_metadata(string infile) returns(Handle h)
		authentication required;
	funcdef download_metadata(Handle h, string outfile) returns()
		authentication required;

	funcdef add_metadata(Handle h, string infile) returns ()
		authentication required;
	funcdef add_data(Handle h, string infile) returns()
		authentication required;


	/* The list_all function returns a set of handles. If the user
	   is authenticated, it retuns the set of handles owned by the
	   user and those that are public or shared.
	*/
	funcdef list_all() returns (list<Handle> l)
		authentication optional;

	/* The list function returns the set of handles that belong
	   to the user.
	*/
	funcdef list_mine() returns (list<Handle> l)
		authentication required;


	/* Just stubbing this one out for now. The idea here is that
	   ours is determined by way of user groups.
	*/
	funcdef list_ours() returns (list<Handle> l)
		authentication required;

};

