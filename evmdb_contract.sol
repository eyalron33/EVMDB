/* A simple Block Chain Database (BCDB)

The SC provides a simple interface for creating 
and managing databases on the EVM.

The SC provides insert, update, delete and search functions.
The search is only exact search for the moment.

There are many things to be added, including type checking, 
regular expression search etc.

*/

//using int256 in binary search to return '-1' for not found,
//this causes max index to be uint128, however use we uint256 
//elsewhere since its the type of array index, and
//we want to avoid type casting.
contract BCDB {
    int256 constant NOT_FOUND 	= -1;

    struct Table {
        address     owner;
        bytes32     name;
        bytes32[]   header;
        bytes32[][]   data; // Dynamic array whose elements are arrays of two bytes
        uint256[] primary_key; // Assume 'primary key' is the first column
    }
    
    address god;
    Table[] tables;
    
    function BCDB() {
        god = msg.sender;
    }
	
	/* Events and Modifiers */
	event tableCreated(bytes32 name, uint256 index);
	modifier onlyGod { if (msg.sender != god) throw; _ }
	
    
    /*                              *
     * External intercace functions *
     *                              */       
    function create(bytes32 name, bytes32[] headers) external returns (uint256) {
		uint256 table_id = tables.length;
		uint256 i;
		
		//array extension is manual
		tables.length = table_id + 1;
		tables[table_id].header.length = headers.length;
		
		
       	for (i=0; i<headers.length; i++) {
       	    tables[table_id].header[i] = headers[i]; 
       	}
        
        tables[table_id].name = name;
        tables[table_id].owner = msg.sender;
		
		tableCreated(name, table_id);
        return table_id;
    }
    
    function insert(uint256 table_id, bytes32[] data) external returns (uint256) {
        if (table_id < tables.length && 
            msg.sender == tables[table_id].owner &&
            data.length == tables[table_id].header.length) {
			
			uint256 row_id = tables[table_id].data.length;
			uint256 i;
			
			//array extension is manual
			tables[table_id].data.length = row_id + 1;
			tables[table_id].data[row_id].length = data.length;
        
            for (i=0; i<data.length; i++) {    
                tables[table_id].data[row_id][i] = data[i];
            }
			
			//push to primary_key table
			uint256 place = place_to_push(table_id, data[0]);
			push_key(table_id, place, row_id);
			
			return row_id;
        }
    }

    function erase(uint256 table_id, uint256 row) external {
        if (table_id < tables.length && 
            msg.sender == tables[table_id].owner && 
            row < tables[table_id].data.length) {
                
			//delete key
			int256 place = binary_search(table_id, tables[table_id].data[row][0]);
			delete_key(table_id, uint256(place));
			
			//delete from DB
			uint256 i;
			for (i=0; i<tables[table_id].data[row].length; i++) {
            	delete tables[table_id].data[row][i];
			}
			
        } else {
			throw; //log NOTHING TO DELETE
		}
    }
    
    function update(uint256 table_id, uint256 row, bytes32[] data) external { //TODO: row_id --> row everywhere
        if (table_id < tables.length && 
            msg.sender == tables[table_id].owner && 
            row < tables[table_id].data.length &&
            data.length == tables[table_id].header.length) {

            uint256 i;

            //delete key
			int256 place = binary_search(table_id, tables[table_id].data[row][0]);
			delete_key(table_id, uint256(place));
			
			//update value
			for (i=0; i<data.length; i++) {    
                tables[table_id].data[row][i] = data[i];
            }
			
			//update key
			place = int256(place_to_push(table_id, data[0]));
			push_key(table_id, uint256(place), row);
        } else {
			throw; //log error
		}
    }
    
    function search(uint256 table_id, bytes32 value) external constant returns (int256) {
		int256 place = binary_search(table_id, value);
		if (place > -1) {
			return int256(tables[table_id].primary_key[uint256(place)]);
		} else {
			return place;
		}
    }
    
    /*                      *
     * internal functions   *
     *                      */    
    function binary_search(uint256 table_id, bytes32 data) returns (int256) {
        uint256 m=0; // search index
        
		//Using int256 as L may be -1,
		//this means that greatest searched index is 2^128-1,
		int256 L = 0; 
		int256 R = int256(tables[table_id].primary_key.length)-1;        

		while (L <= R) {
			m = uint256((L+R)/2);
			if (tables[table_id].data[tables[table_id].primary_key[m]][0] < data) {
				L = int256(m)+1;
			} else if (tables[table_id].data[tables[table_id].primary_key[m]][0] > data) {
				R = int256(m)-1;
			} else {
			   return int256(m);
			}
		}
		
        return NOT_FOUND;
    }
	
	//returns a place to enter new element (not merely searching, like binary_search)
	function place_to_push(uint256 table_id, bytes32 data) returns (uint256) {
        uint256 m=0; // search index
        
		//Using int256 as L may be -1,
		//this means that greatest searched index is 2^128-1,
		int256 L = 0; 
		int256 R = int256(tables[table_id].primary_key.length)-1;        

		while (L <= R) {
			m = uint256((L+R)/2);
			if (tables[table_id].data[tables[table_id].primary_key[m]][0] < data) {
				L = int256(m)+1;
			} else if (tables[table_id].data[tables[table_id].primary_key[m]][0] > data) {	
				R = int256(m)-1;
			} else {
			   return m;
			}
		}
		
		if ( (tables[table_id].primary_key.length>0) && (tables[table_id].data[tables[table_id].primary_key[m]][0] < data) )
        	return m+1;
		else
			return m;
    }
    
	//make those functions only internal
    function push_key(uint256 table_id, uint256 place, uint256 new_value) {
        uint256 i;
		uint256 length = tables[table_id].primary_key.length + 1;
		tables[table_id].primary_key.length = length; //array extension is manual
		
        // push old key forward to make place for new one
        for (i=length-1; i>place; i--) {
            tables[table_id].primary_key[i] = tables[table_id].primary_key[i-1];
        }
        
        tables[table_id].primary_key[place] = new_value;
    }
    
	function delete_key(uint256 table_id, uint256 place) {
        uint256 i;
		uint256 length = tables[table_id].primary_key.length;
		
        // push old key forward to make place for new one
        for (i=place; i<length-1; i++) {
            tables[table_id].primary_key[i] = tables[table_id].primary_key[i+1];
        }
		
		delete tables[table_id].primary_key[length-1];
		tables[table_id].primary_key.length = length - 1; //NEEDED?
    }
	
    // Delete BCDB in case of migrating to another contract (may be removed in production version)
    function delete_BCDB() onlyGod {
		uint i;

		for (i=0; i<tables.length; i++) {
			delete tables[i];
		}
    }
	
	/*                      *
     * Output functions	    *
     *                      */  
	function get_header(uint256 table_id, uint256 header_id) constant returns (bytes32[]) {
		if (header_id < tables[table_id].header.length) {
			return tables[table_id].header;
		} //TAKE CARE OF THE ELSES
	}
	
	function get_keys(uint256 table_id, uint256 key_id) constant returns (uint256) {
		if (table_id < tables.length && key_id < tables[table_id].primary_key.length) {
			return tables[table_id].primary_key[key_id];
		} else { 
			return 1000;
		}
	}
	
	function get_data(uint256 table_id, uint256 row) constant returns (bytes32[]) {
		if (row < tables[table_id].data.length) {
			return (tables[table_id].data[row]);
		}
	}
	
	function get_table_size(uint256 table_id) constant returns (uint256) {
		if (table_id < tables.length) {
			return tables[table_id].data.length;
		}
	}
    
    
}
