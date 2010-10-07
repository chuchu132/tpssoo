#!/bin/bash

#	Todos las las funciones devuelven 
#	0	<->	OK
#	1	<-> ERROR


ambiente(){
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo Ambiente:
	echo "grupo = $grupo"
	echo "PATH = $PATH"
	echo "FECHA_HOY = $FECHA_HOY"	
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

}

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
		echo $comando >> "$grupo/temp/.running_$comando.lck"
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


##########################
#	fepini				 #
##########################

#	Verifico que el ambiente no haya sido inicializado	#
if [ ! -z $INI_FEPINI ]
then
	if [ $INI_FEPINI -eq 2 ]
	then
		echo Fepini ya esta siendo ejecutado
		return 1
	fi
	if [ $INI_FEPINI -eq 1 ]
	then
		echo El ambiente ya ha sido inicializado 
		ambiente
		return 1
	fi
fi

#	Variables de Ambiente	#

export INI_FEPINI=2			# indica que fepini esta siendo ejecutado
export grupo="$PWD/.."		# directorio del trabajo practico 
export PATH="$PATH:$PWD"	
export RECIBIDOS="$grupo/recibidos"
export ACEPTADOS="$grupo/aceptados"
export RECHAZADOS="$grupo/rechazados"
export DIA_HOY=`date +%d`
export MES_HOY=`date +%m`
export ANIO_HOY=`date +%y`
export FECHA_HOY="$ANIO_HOY-$MES_HOY-$DIA_HOY"

#	Funciones genericas para todos los comandos	#

export -f bloquear
export -f desbloquear

error=0

#	Validacion de la instalacion	#

#	Verificar carpetas	#
for carp in prin prin/old arribos recibidos rechazados aceptados facturas facturas/old facturas/listados comandos comandos/log temp
do
	if ! [ -d "$grupo/$carp" ]
	then
		mkdir "$grupo/$carp" > /dev/null
	fi
done


#	Verificar archivos	#

if [ ! -f "$grupo/prin/maepro.txt" ]
then
	echo No existe el archivo Maestro de Proveedores >> "$grupo/temp/instalacion.log"
	error=1
fi

if [ ! -f "$grupo/prin/presu.txt" ]
then
	echo No existe el archivo de Presupuesto >> "$grupo/temp/instalacion.log"
	error=1
fi


#	Verificar comandos	#

for cmd in fepini.sh feponio.sh feprima.sh fepago feplist Glog Mover startfe stopfe
do
	if [ ! -e "$grupo/comandos/$cmd" ]
	then
		echo No esta instalado el comando $cmd >> "$grupo/temp/instalacion.log"
		error=1
	else
		chmod 777 "$grupo/comandos/$cmd"
	fi		
done	


# # # #
echo "=========================================================="
if [ $error -eq 0 ]
then
	#	Iniciar Feponio	#

	local rdo=`ps | grep "feponio.sh$"`
	if [ $? -eq 0 ]
	then
		#	lanzo el demonio
		feponio.sh &
		PID_FO=$!
		#	en el archivo lock guardo el PID	
		echo "PID=$PID_FO" >> "$grupo/temp/.running_feponio.sh.lck"
	else
		#	si ya esta corriendo obtengo su PID
		PID_FO=`grep "PID=" "$grupo/temp/.running_feponio.sh.lck" | cut -d '=' -f 2`
	fi

	echo "Inicializacion de Ambiente Concluida"
	ambiente
	echo Demonio corriendo bajo el no.: $PID_FO
	INI_FEPINI=1	#	indica que el ambiente esta inicializado
	
else
	INI_FEPINI=0	#	indica que el ambiente no esta inicializado
	echo "Inicializacion de Ambiente No fue exitosa. Errores:"
	cat "$grupo/temp/instalacion.log"
fi
echo "=========================================================="

rm -f "$grupo/temp/instalacion.log" > /dev/null
#exit $error
#end fepini

