#!/bin/bash

#	Todos las las funciones devuelven 
#	0	<->	OK
#	1	<-> ERROR

#################################################
#	guarda que el comando esta siendo ejecutado	#
#	$1: nombre del comando						#
#################################################
bloquear(){
	if [ $# -lt 1 ]
	then
		echo "*** bloquear recibe el nombre del comando ***"
		return 1
	fi
	
	local comando=`basename $1`
	if [ -a "$grupo/temp/.running_$comando.lck" ]
	then
		echo "El comando $comando ya esta siendo ejecutado."
		#Glog
		return 1
	else
		echo $! > "$grupo/temp/.running_$comando.lck"
		echo Creado archivo lock "$grupo/temp/.running_$comando.lck" #TODO borrar esta linea
		return 0
	fi
}

#############################
#	 borrar archivo lock	#
# 	 $1: nombre comando		#
#############################
desbloquear(){
	if [ $# -lt 1 ]
	then
		echo "*** desbloquear recibe el nombre del comando ***"
		return 1
	fi
	
	local comando=`basename $1`
	rm -f "$grupo/temp/.running_$comando.lck" > /dev/null
	return $?
}

#############################################
#	indica si se puede ejecutar el comando	#
#	$1: nombre del comando					#
#############################################
iniTests(){
	if [ $# -lt 1 ]
	then
		echo "*** iniTest recibe el nombre del comando ***"
		return 1
	fi
	
	if [ -z $INI_FEPINI ]
	then
		echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. 
		#Glog -se "No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. "
		return 1
	fi
	
	bloquear $1
	return $?
}


##########################
#	fepini				 #
##########################


if [ ! -z $INI_FEPINI ]
then
	echo El ambiente ya ha sido inicializado 
	return 1
fi


#	Variables de Ambiente	#

export INI_FEPINI=1			# indica que fepini esta siendo ejecutado
export grupo="$PWD/.."		# directorio del trabajo practico 
export PATH="$PATH:$PWD"	#TODO no me esta tomando las rutas con espacios!
export RECIBIDOS="$grupo/recibidos"
export ACEPTADOS="$grupo/aceptados"
export RECHAZADOS="$grupo/rechazados"
export DIA_HOY=`date +%d`
export MES_HOY=`date +%m`
export ANIO_HOY=`date +%y`
export FECHA_HOY="$ANIO_HOY-$MES_HOY-$DIA_HOY"

echo "La variable grupo es $grupo"
echo "La variable PATH es $PATH"

#	Funciones genericas para todos los comandos	#

export -f iniTests
export -f bloquear
export -f desbloquear


return 0
#end fepini

