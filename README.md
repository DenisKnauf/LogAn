Status
======

Proof of Concept!

Queue:
	Ruby-Klasse zur Kommunikation zwischen Threads.  Unidirektional
BDB-Queue:
	Queue auf Basis einer BDB.  Kann zur Kommunikation zwischen Prozessen dienen.  Unidirektional.
Stream:
	UNIX-Stream. Bidirektional.

Sicherheit
==========

Verarbeitung wird jeweils abgeschottet und  darf nicht auf andere Daten zugreifen.
$SAFE = 4 waere wuenschenswert,  aber unpraktikabel bezueglich Queue.
$SAFE = 3 reicht.

Mehrere Prozesse also nicht noetig.

erstes Map auf Logdaten
=======================

Liest aus der BDB-Queue,  verarbeitet und schreibt in eine andere Datenbank.

Parallelisierung
----------------

Eine DB,  die speichert,  wer an was arbeitet.  Koennte langsam werden.

MapReduce allgemein
===================

Woher kommt die Information,  dass gearbeitet werden kann?  BDB-Queue/Stream/Queue.

Piping
======

MapReduce-Verarbeitung kann auch hintereinander geschaltet werden.
Hierzu bietet sich Queue im Prozess an.
