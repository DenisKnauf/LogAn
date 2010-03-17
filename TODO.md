
* BDB/SBDB
	+ Enthaelt noch einen fiesen Fehler.
	  Kann aber auch an falscher Benutzung liegen.
		-> TXN-Logging-Overflow

* Sandbox (90%)

* Persistenter Speicher
	+ BDB

* Transactionsuche
	+ Sandbox
	+ Pers. Speicher

+ Config
	+ BDB
	+ String in Object umwandeln
		- Sandbox
	+ Objectcache
		- Hash

* LogAn
	+ Ablauf (siehe Bild) (0%)
	+	Sandbox
	+ Dequeue
		- SBDB
	+ Pers. Speicher
	+ Config
	+ emit
		- SBDB

* File2LogAn
	+ Server (50%)
		- select (100%)
	+ emit (0%)
		* SBDB
	+ Sandbox
	+ Config

* push2mysql
	+ Dequeue
		- SBDB
	+ SQL-Insert
