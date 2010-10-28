#!/bin/bash

# ####################################################################
# Valido y obtengo los Argumentos del script
# Valida la cantidad de argumentos
if [ $# -ne 3 ]
then

	if [ $# -ne 1 -o "$1" != "--help" -a "$1" != "--HELP" -a "$1" != "-h" ]
	then
		echo "Error: Wrong arguments. Please review the help (glog.sh --help).";
		exit 1;
	fi

	echo "Usage: glog.sh log type message"
	echo " log		Logs name. The file will be at \"\$grupo/comandos/log/logArgument.log\"";
	echo " message	Message to be logged."
	echo " type		Type of message log:";
	echo "			info   or INFO   means an informative message";
	echo "			warn   or WARN   means an warning message";
	echo "			error  or ERROR  means an error message";
	echo "			serror or SERROR means an severege message"

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
		echo "Error: Wrong argument. Argument ($2) Position (2). Please review the help (glog.sh --help)."; 
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
		echo "Error: Don't have write permissions on the folder \"${logPath}\"."
		exit 10
	fi

else

	# Verifico que pueda escribir en el directorio padre...
	if [ ! -w "${grupo:-$PWD}" ]
	then
		echo "Error: Don't have permissions to create the folder \"${logPath}\"."
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
		echo "Error: Don't have write permissions on the log \"${logName}\"."
		exit 11
	fi

	# Verifico si debo truncar el log...
	logMaxSize=${GLOG_MAX_SIZE:-"1048576"}
	logSize=`ls -l "$logName" | cut -d' ' -f5`
	logSizeWillBe=`expr ${logSize} + ${#2} + 30`

	if [ $logSizeWillBe -gt $logMaxSize  ]
	then

		echo "Log<$logFile> Size exceeded (${logMaxSize} b)."
		logSaveLast=${GLOG_LAST:-"15"}

		if [ $logSaveLast -gt 0 ]
		then

			echo "Log<${logFile}> ${logSaveLast} records will be saved." 
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
