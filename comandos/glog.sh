# File:					Glog.sh
# Creation:				16.09.2010
# Last modification:			07.10.2010


#!/bin/bash

# #############################################
# Muestra el Help y termina.
#
# Nota: Utiliza la variable "logHelpExit" para
#       salir del script. En caso de no existir
#	termina la ejecucion con "0".

function Help {

	echo "Glog v0.1"
	echo "Usage: Glog command type message"

	exit ${logHelpExit:-"0"}
}

# ####################################################################
# Valido y obtengo los Argumentos del script

# Valida la cantidad de argumentos
if [ $# -ne 3 ]
then

	if [ $# -ne 1 -o "$1" != "--help" -a "$1" != "--HELP" ]
	then
		logHelpExit="2"
	fi
	
	Help
fi

# Obtengo los Argumentos con sus respectivos valores...
logCommand=`echo "$1" | tr [:upper:] [:lower:]`
logMessage="$3"

# Valido el tipo de mensaje...
case "$2" in

	info   | Info   | INFO  )	logType="INFO";	 ;;
	warn   | Warn   | WARN  )	logType="WARN";  ;;
	error  | Error  | ERROR )	logType="ERRO";  ;;
	Serror | SError | SERROR)	logType="SEVE";  ;;
	*)	logHelpExit="3"; Help; ;;

esac;

# ###################################################################
# Verifico si debo crear la carpeta donde se guardan los logs.
#
# Nota: Si la variable "GRUPO" no esta definida pone en el path el PWD

logPath="${grupo:-$PWD}/comandos/log"

# Verifico que exista el directorio
if [ -d "${logPath}" ]
then
	
	# Verifico que pueda escribir en el directorio...
	if [ ! -w "${logPath}" ]
	then
		echo "No tiene permiso de escritura en el directorio \"${logPath}\"."
		exit 10
	fi

else

	# Verifico que pueda escribir en el directorio padre...
	if [ ! -w "${grupo:-$PWD}" ]
	then
		echo "No tiene permisos para crear el directorio \"${logPath}\"."
		exit 20
	fi

	# Creo el directorio...
	mkdir -m 755 -p "${logPath}"

fi

# ####################################################################
# Verifico el tamaño del archivo del log

logFile="${logCommand}.log"
logName="${logPath}/${logFile}"

# Verifico si existe el archivo de log...
if [ -e "${logName}" ]
then

	# Verifico que pueda escribir el log...
	if [ ! -w "${logName}" ]
	then
		echo "No tiene permiso de escritura sobre el log \"${logName}\"."
		exit 11
	fi

	# Verifico si debo truncar el log...
	logMaxSize=${GLOG_MAX_SIZE:-"1048576"}
	logSize=`ls -l "$logName" | cut -d' ' -f5`
	logSizeWillBe=`expr ${logSize} + ${#2} + 30`

	if [ $logSizeWillBe -gt $logMaxSize  ]
	then

		echo "Log<$logFile> excedido de tamaño (${logMaxSize} b)."
		logSaveLast=${GLOG_LAST:-"15"}

		if [ $logSaveLast -gt 0 ]
		then

			echo "Log<${logFile}> guardara los ultimos ${logSaveLast} registros." 
			tail -$logSaveLast $logName > "${logName}.tmp"
			mv --force "${logName}.tmp" "${logName}"

		else
			echo -n "" > "${logName}"
		fi
	fi

fi

# ####################################################################
# Creo el resto de la variables que uso para el registro del log
logTime=$( date +"%Y/%m/%d %H:%M:%S" )

# ####################################################################
# Escribo en el log
echo "${logTime} - ${logType} - ${logMessage}" >> "${logName}"
exit 0

