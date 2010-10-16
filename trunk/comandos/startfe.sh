#!/bin/sh
#
#Inicia la ejecución del demonio.
#pre-condiciones: 
#				-el ambiente ya fue inicializado 
#				-el demonio todavía no ha sido ejecutado.
#

if [ -z "$grupo" ]
then
	echo "Error: el ambiente no fue inicializado."
	echo ""
	exit 1
else
	x=`ps | grep '^.* feponio\.sh$'`
	if [ $? -eq 0 ]
	then
		echo "Error: feponio ya se está ejecutando."
		pid=`ps | grep '^.* feponio\.sh$' | sed 's/ \?\([0-9]*\).*/\1/'`
		echo "Pid=${pid}"
		echo ""
		exit 1
	else
		echo "Se inicia la ejecución de feponio"
		feponio.sh&
		PID_FO=$!
		echo "Demonio corriendo bajo no.:$PID_FO"
		echo ""
		exit 0
	fi
fi

