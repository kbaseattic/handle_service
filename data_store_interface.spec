/* The DSI module provides a programmatic interfact to a
   remote file store.
*/
module DSI {

	/* Handle provides a unique reference that enables
	   access to the data files through functions
	   provided as part of the DSI. In the case of using
	   shock, the id is the node id. In the case of using
	   shock the value of type is “shock”. In the future 
	   these values should enumerated. The value of url is
	   the http address of the shock server, including the
	   protocol (http or https) and if necessary the port.
	*/
	typedef structure {
		string file_name;
		string id;
		string type;
		string url;
	} Handle;

	
	/* get_handle returns a Handle object with a url*/
	funcdef get_handle(string service_name) returns (Handle h);
	/* prepare_upload returns a Handle object with an ID */
	funcdef prepare_upload(Handle h) returns (Handle h);
	/* uploads a file and returns the handle */
};

/*
	so what should the upload function do, other than upload
	the data to shock?

	it could store information about the upload such as what
	is contained in the handle.

	think about the remaining methods:
	- download does not require anything not in the handle
	- is_transfer_valid requires client user to provide the
	  checksum. this could be done in the service Impl.
	- delete could also be done in the Impl.
*/
