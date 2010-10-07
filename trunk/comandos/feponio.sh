#!/bin/bash

#especifica la ruta raiz donde se encontraran todos los archivos
# en el codigo posta esto estara con la ruta correspondiente
#GRUPO=``

# nombre de los directorios
#ARRIBOS=/home/leonardo/Escritorio/Demonio/arribos/
#RECIBIDOS=/home/leonardo/Escritorio/Demonio/recibidos/
#RECHAZADOS=/home/leonardo/Escritorio/Demonio/rechazados/

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


while [ 1 ]
do
	# me fijo si existe algun archivo en el directorio de arribos
	archivos=`ls $RUTAARRIBOS`
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
				echo "Moviendo archivo a recibidos..."
				#TODO reemplazar por el MOVER
				mv $RUTAARRIBOS${nombre} $RUTARECIBIDOS
			else
				echo "Archivo con nombre incorrecto: ${nombre}"
				echo "Moviendo archivo a rechazados..."
				#TODO reemplazar por el MOVER
				mv $RUTAARRIBOS${nombre} $RUTARECHAZADOS			
			fi 				
		done
	else
		echo "No existen archivos en $RUTAARRIBOS"
	fi
	
	recibidos=`ls $RUTARECIBIDOS`
	if [ -n "$recibidos" ]
	then
		echo ""
		echo "Existen archivos en $RUTARECIBIDOS."
		# busco en los procesos que se estan corriendo actualmente
		# al proceso feprima.sh
		# x=`ps | grep '^.*feprima\.sh$'`
		x=`ps | grep 'feprima\.sh$'`
		# si el grep retorna 1 quiere decir que no encontro ningun proceso con ese nombre
		if [ $? -ne 0 ]
		then
			echo "Se ejecuta feprima.sh"
			# creo q de esta forma se llama al feprima.sh
			feprima.sh
		else
			echo "No se puede lanzar feprima.sh porque está en ejecución."
		fi
	fi

	sleep 30

done

