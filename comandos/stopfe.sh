#!/bin/sh
#
#Detiene la ejecución del demonio.
#pre-condición: el demonio se está ejecutando
#

x=`ps | grep '^.* feponio\.sh$'
if [ $? -eq 0 ]
then
	echo "Se detiene la ejecución de invonio."
	pid=`ps | grep '^.* feponio\.sh$' | sed 's/ \?\([0-9]*\).*/\1/'`
	kill $pid
	echo ""
	exit 0
else
	echo "Error: invonio no se está ejecutando"
	echo ""
	exit 1
fi

