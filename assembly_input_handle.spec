module AssemblyInputHandle {

	typedef int boolean;

	/* 
	   A handle is a generic object and is defined
	   in in the handle service.
	*/
	typedef structure {
	    string shock_id;
		string filename;
	} Handle;

	/*
	   Represents a handle to a single end library
	*/
	typedef Handle SingleEndLibrary;

	/* 
	   Represents a handle to a paired end library.
	   handle pair      - represents the set of paired end
	                      read files, and is required.
	   insert_size_mean - is optional.
	   insert_size_std  - is optional.
	   read_orientation_outward - if set to true indicates
	                      the library is a jumping library.
	*/
	typedef structure {
	    tuple<Handle h1, Handle h2> handle_pair;
	    float insert_size_mean;
	    float insert_size_std_dev;
	    boolean read_orientation_outward;
	} PairedEndLibrary;

	/*
	   Assembly input represents the set of handles and
	   associated metadata that provides the minimal
	   inoformation for the KBase assembly service.

	   paired_end_libs is a list of PairedEndLibrary handles.
	   single_end_libs is a list of SingleEndLibrary handles.
	   exprected_coverage is optional.
	   extimated_genome_size is optional.
	   data_set_prefix is optional.
	*/
	typedef structure {
	    list<PairedEndLibrary> paired_end_libs;
	    list<SingleEndLibrary> single_end_libs;
	    float expected_coverage;
	    int estimated_genome_size;
	    string dataset_prefix;
} AssemblyInput;

};
