/* The DataStoreInterface module provides a programmatic
   access to a remote file store.
*/
module DataStoreInterface {

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

	
	/* new_handle returns a Handle object with a url and a node id */
	funcdef new_handle(string service_name) returns (Handle h);

	/* locate returns a url of a shock server near a service */
	funcdef locate(string service_name) returns (string url, string type);

	/* initialize_handle returns a Handle object with an ID. */
	funcdef initialize_handle(Handle h1) returns (Handle h2);

};

