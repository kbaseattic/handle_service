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
	typedef string HandleId;
	typedef structure {
		HandleId hid;
		string file_name;
		string id;
		string type;
		string url;
		string remote_md5;
		string remote_sha1;
	} Handle;



	/* BASIC HANDLE CREATION FUNCTIONS */

	
	/* The new_handle function returns a Handle object with a url and a
	   node id. The new_handle function invokes the localize_handle
	   method first to set the url and then invokes the initialize_handle
	   function to get an ID.
	 */
	funcdef new_handle() returns (Handle h) authentication optional;

	/* The localize_handle function attempts to locate a shock server near
 	   the service. The localize_handle function must be called before the
	   Handle is initialized becuase when the handle is initialized, it is
	   given a node id that maps to the shock server where the node was
	   created. This function should not be called directly.
	 */
	funcdef localize_handle(Handle h1, string service_name)
		returns (Handle h2);

	/* The initialize_handle returns a Handle object with an ID. This
	   function should not be called directly
	 */
	funcdef initialize_handle(Handle h1) returns (Handle h2) 
		authentication optional;

	/* The persist_handle writes the handle to a persistent store
	   that can be later retrieved using the list_handles
	   function.
	*/
	funcdef persist_handle(Handle h) returns (string hid)
		authentication optional;



	/* ABSTRACT HANDLE FUNCTIONS */


	/* The upload and download functions  provide an empty
	   implementation that must be provided in a client. If a concrete
	   implementation is not provided an error is thrown. These are
	   the equivelant of abstract methods, with runtime rather than
	   compile time inforcement.
	
	   [client_implemented]
	*/
	funcdef upload(string infile) returns(Handle h) 
		authentication optional;

	/* The upload and download functions  provide an empty
           implementation that must be provided in a client. If a concrete
           implementation is not provided an error is thrown. These are
           the equivelant of abstract methods, with runtime rather than
           compile time inforcement.

	   [client_implemented]
	*/
	funcdef download(Handle h, string outfile) returns()
		authentication optional;
	
	/* The upload_metadata function uploads metadata to an existing
	   handle. This means that the data that the handle represents
	   has already been uploaded. Uploading meta data before the data
	   has been uploaded is not currently supported.

	   [client_implemented]
	*/
	funcdef upload_metadata(Handle h, string infile) returns()
		authentication optional;

	/* The download_metadata function downloads metadata associated
	   with the data handle and writes it to a file.

	   [client_implemented]
	*/
	funcdef download_metadata(Handle h, string outfile) returns()
		authentication optional;



	/* STANDARD FUNCTIONS FOR MANAGING HANDLES */

	/* Given a list of handle ids, this function returns
	   a list of handles. 

	   TODO: The function will throw an error if the user
	   requesting the handles does not have read permission on
	   any one of the handles.
	*/
	funcdef hids_to_handles(list<HandleId> hids)
		returns(list<Handle> handles)
		authentication required;
	
	/* Given a list of handle ids, this function determines if
	   the underlying data is readable by the caller. If any
	   one of the handle ids reference unreadable data this
	   function returns false.
	*/
	funcdef are_readable(list<HandleId>) returns(int)
		authentication required;

	/* Given a handle id, this function queries the underlying
	   data store to see if the data being referred to is
	   readable to by the caller.
	*/
	funcdef is_readable(string id) returns(int)
		authentication required;

	/* The list function returns the set of handles that were
	   created by the user. 
	*/
	funcdef list_handles() returns (list<Handle> l)
		authentication optional;

	/* The delete_handles function takes a list of handles
	   and deletes them on the handle service server.
	*/
	funcdef delete_handles(list<Handle> l) returns ()
		authentication optional;

	/*

	*/
	funcdef give (string user, string perm, Handle h)
		returns() authentication required;

};

