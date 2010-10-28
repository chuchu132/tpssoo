#!/bin/bash

# ####################################################################
# Valido y obtengo los Argumentos del script
# Valida la cantidad de argumentos
if [ $# -ne 3 ]
then

	if [ $# -ne 1 -o "$1" != "--help" -a "$1" != "--HELP" -a "$1" != "-h" ]
	then
		echo "Error: Argumentos erroneos. Por favor revise la ayuda (glog.sh --help)."
		exit 1;
	fi

	echo "Uso: glog.sh log tipo mensaje";
	echo " log		Nombre del archivo del log.";
	echo " mensaje	Mensaje a registrar.";
	echo " tipo		Tipo de mensaje. Los \"tipos\" posibles son:";
	echo "			info   o INFO    mensaje informativo.";
	echo "			warn   o WARN    mensaje de advertencia.";
	echo "			error  o ERROR   mensaje de error.";
	echo "			serror o SERROR  mensaje de error severo.";

	exit 0;
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
	*) 
		echo "Error: Argumento erroneo ($2) en la posicion (2). Por favor revise la ayuda (glog.sh --help)";
		exit 5;
	;;

esac;

# ###################################################################
# Verifico si debo crear la carpeta donde se guardan los logs.
[ -z "$grupo" ] && logPath="${PWD}/log";
[ -n "$grupo" ] && logPath="${grupo}/comandos/log";

# Verifico que exista el directorio
if [ -d "${logPath}" ]
then
	
	# Verifico que pueda escribir en el directorio...
	if [ ! -w "${logPath}" ]
	then
		echo "Error: No tiene permisos de escritura en la carpeta \"${logPath}\".";
		exit 10
	fi

else

	# Verifico que pueda escribir en el directorio padre...
	if [ ! -w "${grupo:-$PWD}" ]
	then
		echo "Error: No tiene permisos para crear la carpeta \"${logPath}\".";
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
		echo "Error: No tiene permisos de escritura en el log \"${logName}\"."
		exit 11
	fi

	# Verifico si debo truncar el log...
	logMaxSize=${GLOG_MAX_SIZE:-"1048576"}
	logSize=`ls -l "$logName" | cut -d' ' -f5`
	logSizeWillBe=`expr ${logSize} + ${#2} + 30`

	if [ $logSizeWillBe -gt $logMaxSize  ]
	then

		echo "Log<$logFile> Tamaño de log excedido (tamaño maximo ${logMaxSize} b)."
		logSaveLast=${GLOG_LAST:-"15"}

		if [ $logSaveLast -gt 0 ]
		then

			echo "Log<${logFile}> Se guardaran los ultimos ${logSaveLast} registros." 
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
