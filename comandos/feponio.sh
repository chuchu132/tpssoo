#!/bin/bash

# feponio.sh Demonio: Realiza el mismo proceso que se encuentra dentro del while
# cada 30 segundos. De acuerdo a las especificaciones del trabajo; comprobando 
# el nombre de los archivos arribados y pasandolos a la carpeta de recibidos o 
# rechazados segun corresponda. 
# Luego ejecuta el script feprima.sh, si no se esta procesando

#ruta de arribos
RUTAARRIBOS=$ARRIBOS

#ruta de recibidos
RUTARECIBIDOS=$RECIBIDOS

#ruta de rechazados
RUTARECHAZADOS=$RECHAZADOS

# cantidad de digitos que debe tener el CAE
#CAE=14
#MENOR=00000000000000
#MAYOR=99999999999999

# 	Verificar ambiente	#
if [ -z $INI_FEPINI ]
then
	echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente.
	./glog.sh feponio SERROR "No se ha inicializado el ambiente."
	exit 1
fi

#	tiempo para dejar terminar a fepini
sleep 2	

while [ 1 ]
do
	# me fijo si existe algun archivo en el directorio de arribos
	archivos=`ls "$RUTAARRIBOS"`
	if [ -n "$archivos" ]
	then
		echo ""
		echo "Existen archivos en $RUTAARRIBOS"
		# Se verfica que los nombres sean correctos.
		# Los archivos válidos poseen nombres con este formato: <CAE>. El CAE sea de 14 dígitos 	
		for nombre in $archivos
		do
			# obtiene la cantidad de digitos del nombre del archivo
			# verifica si es igual a la cantidad pedida segun el CAE
			#if [ \("${#nombre}" -eq $CAE \) -a \( "$nombre" -ge "$MENOR" -a "$nombre" -le "$MAYOR" \) ]
			result=`echo $nombre | grep '^[0-9]\{14\}$'`
			if [ $? -eq 0 ] 
			then
				echo "Factura Recibida: ${nombre}"
				Mover "$RUTAARRIBOS/${nombre}" "$RUTARECIBIDOS"
			else
				echo "Factura Rechazada. Archivo con nombre incorrecto: ${nombre}"
				Mover "$RUTAARRIBOS/${nombre}" "$RUTARECHAZADOS"			
			fi 				
		done
	else
		echo "No existen archivos en $RUTAARRIBOS"
	fi
	
	recibidos=`ls "$RUTARECIBIDOS"`
	if [ -n "$recibidos" ]
	then
		echo ""
		echo "Existen archivos en $RUTARECIBIDOS."
		# busco en los procesos que se estan corriendo actualmente al proceso feprima.sh
		x=`ps | grep 'feprima\.sh$'`
		# si el grep retorna un valor distinto de 0 quiere decir que no encontro ningun proceso con ese nombre
		if [ $? -ne 0 ]
		then
			feprima.sh
		else
			echo "No se puede lanzar feprima.sh porque está en ejecución."
		fi
	fi

	sleep 30

done

