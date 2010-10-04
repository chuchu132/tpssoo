#!/bin/bash



##############################
# return: 
#	0	<->	OK	
#	1	<->	error de ejecucion
##############################


function salirfep(){
	sleep 10
	rm "$grupo/temp/$1.lck"
	echo Salir con $2
	exit $2
}

function estaCorriendo(){
	if [ -z $INI_FEPINI ]
	then
		echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. 
		#Glog -se "No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. "
		exit 1
	fi
	nombre="$grupo/temp/$1.lck"
	if [ -a "$nombre" ]
	then
		echo El comando $1 ya esta siendo ejecutado.
		#Glog
		exit 1
	else
		echo $1 > "$nombre"
		echo Creado archivo lock $nombre #TODO borrar esta linea
	fi
}

function esDuplicado(){
	local aceptados=`ls "$ACEPTADOS"`
	for file in $aceptados
	do
		if [ "$file" = "$1" ]
		then
		return 1
		else
		return 0
		fi
	done
}

function validarCabecera(){ 
    return 0
}

function validarItems(){
    return 0
}

function validacionFinal(){
    return 0    
}

function grabarRegistro(){
    return 0
}

function procesar(){
    validarCabecera $1
    if [ -z $? ]
    then
	validarItems $1
	if [ -z $? ]
	then
	    validacionFinal $1
	    if [ -z $? ]
	    then
		grabarRegistro
	    else
	    echo "Factura Errónea, no coinciden los totales: $1"
		#Glog -se "Factura Errónea no coinciden los totales: $1"
	    fi
	else
	echo "Factura Errónea en registro de ítem: $1"
	#Glog -se "Factura Errónea en registro de ítem: $1"
	fi
    else
    echo "Factura Errónea en registro cabecera: $1"
    #Glog -se "Factura Errónea en registro cabecera: $1"
    fi

}

function procesar_archivos(){

	cant_arch=`ls -l "$RECIBIDOS" | wc -l`
	cant_arch=`echo "$cant_arch - 1" | bc -l`
	echo "Inicio de Feprima: $cant_arch"
	# Glog -i "Inicio de Feprima: $cant_arch" 
	
	archivos=`ls "$RECIBIDOS"`
	for file in $archivos
	do
		# Glog -i "Archivo a Procesar: $file"
		repetido= `esDuplicado $file`
		if [ $repetido -gt 0 ]
		then
			Mover "${RECIBIDOS}/$file" "$RECHAZADOS" 
			#Glog -i "Factura Duplicada: $file"
		else
			procesar $file
		fi
	done
}

##########################
# feprima
##########################
estaCorriendo $0
procesar_archivos

salirfep $0 $?




#end feprima

