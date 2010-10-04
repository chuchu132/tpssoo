#!/bin/bash

#fepini

if [ ! -z $INI_FEPINI ]
then
	echo El ambiente ya ha sido inicializado 
	return 1
fi

export INI_FEPINI=1			# indica que fepini esta siendo ejecutado
export grupo="$PWD/.."		# directorio del trabajo practico 
export PATH="$PATH:$PWD"	#TODO no me esta tomando las rutas con espacios!
export RECIBIDOS="$grupo/recibidos"
export ACEPTADOS="$grupo/aceptados"
export RECHAZADOS="$grupo/rechazados"

echo "La variable grupo es $grupo"
echo "La variable PATH es $PATH"




return 0
#end fepini

