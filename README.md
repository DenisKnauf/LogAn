Status
======

Proof of Concept!

Derzeit lote ich nur aus,  was alles benoetigt wird.

Sicherheit
==========

Verarbeitung wird jeweils abgeschottet und  darf nicht auf andere Daten zugreifen.
$SAFE = 4

Map auf Logdaten
================

Liest aus der Queue,  verarbeitet und schreibt in eine andere Datenbank.

Parallelisierung
----------------

Eine DB,  die speichert,  wer an was arbeitet.  Koennte langsam werden.

MapReduce allgemein
====================

Woher kommt die Information,  dass gearbeitet werden kann?  Queue/Stream/im Prozess.

Piping
======

MapReduce hintereinander gepipet.  Queue/Stream simpel,
wenn jeweils ein Prozess/Thread zustaendig ist.  Ein Prozess komplexer.
