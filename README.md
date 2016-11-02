# EVMDB

## Description
A simple Ethereum Virtual Machine Database (EVMDB). Version 0.0.1. **It is a first functional prototype**, use with cautious!

EVMDB is used for creating and managing DBs on the EVM.

The functionality provided is simple:
- create a DB.
- insert, update, delete or read data from a DB.
- search a DB, where search is only exact search and only on one field ("the primary key") at the moment.

Further developments may include type checking, "select" search, complicated DB structues etc.

License:  MIT 

## Usage
The EVMDB can either be called from DAPPs or from another smart contract.

DB managing API:
- create(bytes32 _name, bytes32[] _headers): creates a DB called _name with headers _headers. Returns the ID of the newly created DB. It is assumed that _headers[0] is the primary key of the DB. Generates a 'DBCreated' event
- insert(uint256 _DB_id, bytes32[] _data): inserts a row with data _data to _DB_ID. Returns the ID for the newly inserted row.
- erase(uint256 _DB_id, uint256 _row): erases a row with id _row from _DB_id. Recall that in Solidity deletion of a row means exchanging all of its values with '0'.
- update(uint256 _DB_id, uint256 _row, bytes32[] _data): updates the data in the row with id _row in _DB_id to be _data.

DB search API:
- search(uint256 _DB_id, bytes32 _value): a constant function. Searches the primary key (i.e, the first column) of _DB_id for _value. If found, returns the id of the row that contains the item (if the primary key contains duplications, then some row that fits the search is returned). If not found, returns '-1'.

DB read API:
- get_header(uint256 _DB_id). a constatnt function. Returns a bytes32[] array with the header names of _DB_id.
- get_row(uint256 _DB_id, uint256 _row). a constatnt function. Returns a bytes32[] array with data of row with id _row of _DB_id.
- get_row_col(uint256 _DB_id, uint256 _row, uint256 _col). a constatnt function. Returns the data in column id _col in row id _row in _DB_id. 
- get_DB_info(uint256 _DB_id). a constatnt function, returns an array of (DB address, DB owner (address), DB size) of _DB_id.
- get_number_of_DBs(). a constatnt function. Returns the number of DBs in the smart contract.

## Examples
A demo smart contract using EVMDB is supplied in the [examples folder](https://github.com/eyalron33/EVMDB/tree/master/examples). 


A [demo Dapp](http://cryptom.site/evmdb/) to manage databases is run on a simulated blockchain on Cryptom's server. The data there is deleted every 24 hours, so use it for impression only!

You can also run the demo Dapp locally using testrpc. To do so, follow those steps:
1. Clone this repository.

2. Install and run [testrpc](https://github.com/ethereumjs/testrpc), you should see something like that:
![Testrpc_run1](https://c2.staticflickr.com/6/5284/30128813205_b61a6d85b0_o.jpg)

3. run 'deploy_contract.html' located in /demo/deployent/ folder, you should be something like this:
![Testrpc_run2](https://c2.staticflickr.com/8/7504/30093902056_f35abf54fd_o.jpg)

4. Copy the contract number ("0x8a1dfd7888b9ec7709ce6ff468edb4f6100955a1" in the picture above) and paste it as the value of 'deployed_contract' in /demo/deployment/deployment.js

5. run evmdb_demo_dapp.html.
