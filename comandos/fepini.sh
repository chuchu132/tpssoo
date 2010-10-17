#!/bin/bash

#	Todos las las funciones devuelven 
#	0	<->	OK
#	1	<-> ERROR




#############################################################
#	Muestra las variables de ambiente seteadas por fepini	#
#############################################################
ambiente(){
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo Ambiente:
	echo "grupo = $grupo"
	echo "PATH = $PATH"
	echo "FECHA_HOY = $FECHA_HOY"	
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

}

#################################################
#       guarda que el comando esta siendo ejecutado     #
#       $1: nombre del comando                                          #
#       return 1 <-> el comando esta en ejecucion       #
#################################################
bloquear(){
        if [ $# -lt 1 ]
        then
                echo "*** bloquear recibe el nombre del comando ***"
                return 1
        fi
        
        local comando=`basename "$1"`
        if [ -a "$grupo/temp/.running_$comando.lck" ]
        then
                p_id=`grep "^PID=" "$grupo/temp/.running_$comando.lck"`
                echo "El comando $comando ya esta siendo ejecutado bajo $p_id."
                glog fepini WARN "El comando $comando ya esta siendo ejecutado bajo $p_id."
                return 1
        else
                echo "PID=$$" > "$grupo/temp/.running_$comando.lck"
                return 0
        fi
}

#########################
#	borrar archivo lock	#
#	$1: nombre comando	#
#########################
desbloquear(){
        if [ $# -lt 1 ]
        then
                echo "*** desbloquear recibe el nombre del comando ***"
                return 1
        fi
        
        local comando=`basename "$1"`
        rm -f "$grupo/temp/.running_$comando.lck" > /dev/null
        return $?
}


#########################################
#	Setea la var de ambiente FECHA_HOY	#
#	con la fecha actual con formato		#
#########################################
fechaHoy(){
	DIA_HOY=`date +%d`
	MES_HOY=`date +%m`
	ANIO_HOY=`date +%Y`
	FECHA_HOY="$ANIO_HOY-$MES_HOY-$DIA_HOY"
}

##########################
#	fepini				 #
##########################

echo "=========================================================="


#	Verifico que el ambiente no haya sido inicializado	#
if [ ! -z $INI_FEPINI ]
then
	if [ $INI_FEPINI -eq 2 ]
	then
		echo Fepini ya esta siendo ejecutado
		echo "=========================================================="
		return 1
	fi
	if [ $INI_FEPINI -eq 1 ]
	then
		echo El ambiente ya ha sido inicializado 
		ambiente
		echo "=========================================================="
		return 1
	fi
fi

#	Variables de Ambiente	#

export INI_FEPINI=2			# indica que fepini esta siendo ejecutado
export grupo="$PWD/.."		# directorio del trabajo practico 
export RECIBIDOS="$grupo/recibidos"
export ACEPTADOS="$grupo/aceptados"
export RECHAZADOS="$grupo/rechazados"
export ARRIBOS="$grupo/arribos"
export DIA_HOY=`date +%d`
export MES_HOY=`date +%m`
export ANIO_HOY=`date +%Y`
export FECHA_HOY="$ANIO_HOY-$MES_HOY-$DIA_HOY"

#	Si nuestro directorio "comandos" no esta en el PATH lo agrego	#

echo "$PATH" | grep "${PWD}" > /dev/null
if [ $? -ne 0 ]
then
	export PATH="$PATH:$PWD"	
fi


#	Funciones genericas para todos los comandos	#

export -f fechaHoy
export -f bloquear
export -f desbloquear
error=0

#	Validacion de la instalacion	#

#	Verificar carpetas	#
for carp in prin prin/old arribos recibidos rechazados aceptados facturas facturas/old facturas/listados comandos comandos/log temp
do
	if [ ! -d "$grupo/$carp" ]
	then
		mkdir "$grupo/$carp" > /dev/null
	fi
done


#	Verificar archivos	#

if [ ! -f "$grupo/prin/maepro.txt" ]
then
	echo No existe el archivo Maestro de Proveedores >> "$grupo/temp/instalacion.log"
	error=1
else
	chmod 555 "$grupo/prin/maepro.txt"
fi

if [ ! -f "$grupo/prin/presu.txt" ]
then
	echo No existe el archivo de Presupuesto >> "$grupo/temp/instalacion.log"
	error=1
else
	chmod 777 "$grupo/prin/presu.txt"
	export PRESUPUESTO="$grupo/prin/presu.txt"
fi


#	Verificar comandos	#

for cmd in fepini.sh feponio.sh feprima.sh glog.sh Mover
do
	if [ ! -e "$grupo/comandos/$cmd" ]
	then
		echo No esta instalado el comando $cmd >> "$grupo/temp/instalacion.log"
		error=1
	else
		chmod 777 "$grupo/comandos/$cmd"
	fi		
done	

#	Verificar Comandos independientes	#

for cmd in fepago.pl feplist.pl startfe.sh stopfe.sh
do
	if [ ! -e "$grupo/comandos/$cmd" ]
	then
		echo "No esta instalado el comando $cmd. Esta funcionalidad no estara disponible" >> "$grupo/temp/instalacion.log"
	else
		chmod 777 "$grupo/comandos/$cmd"
	fi		
done

# # # #

if [ $error -eq 0 ]
then
	INI_FEPINI=1	#	indica que el ambiente esta inicializado
	
	#	Iniciar Feponio	#

	#	Verifico si esta corriendo el demonio
	rdo=`ps | grep "feponio\.sh$"`
	if [ $? -ne 0 ]
	then
		#	lanzo el demonio
		feponio.sh &
		PID_FO=$!
	else
		#	si ya esta corriendo obtengo su PID
		PID_FO=`ps | grep '^.* feprima\.sh$' | sed 's/ \?\([0-9]*\).*/\1/'`
	fi

	echo "Inicializacion de Ambiente Concluida"
	echo "Demonio corriendo bajo el no.: $PID_FO"
	cat "$grupo/temp/instalacion.log"
	ambiente
	glog.sh fepini INFO "Inicializacion de Ambiente Concluida"
	glog.sh fepini INFO "Demonio corriendo bajo el no.: $PID_FO"
	glog.sh fepini INFO "grupo = $grupo"
	glog.sh fepini INFO "PATH = $PATH"
	
else
	INI_FEPINI=0	#	indica que el ambiente no esta inicializado
	echo "Inicializacion de Ambiente No fue exitosa. Errores:"
	cat "$grupo/temp/instalacion.log"
	ambiente

fi
echo "=========================================================="

rm -f "$grupo/temp/instalacion.log" > /dev/null
#exit $error
#end fepini

