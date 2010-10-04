#!/bin/bash



##############################
# return: 
#	0	<->	OK	
#	1	<->	error de ejecucion
##############################


esDuplicado(){
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

validarCabecera(){ 
    return 0
}

validarItems(){
    return 0
}

validacionFinal(){
    return 0    
}

grabarRegistro(){
	#TODO setear el valor correcto a las vars de aca abajo
	local registro="${CAE};A PAGAR;${VTO};${MONTO}"
	echo $registro >> "$grupo/facturas/apagar.txt"
    return 0
}

procesar(){
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

procesar_archivos(){

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
			Mover "${RECIBIDOS}/$file" "$ACEPTADOS"
			#Glog "Factura Aceptada: $file"
		fi
	done
}

##########################
# feprima
##########################

iniTests $0
if [ $? -eq 0 ]
then
	procesar_archivos
	sleep 10	## TODO esta para ver que se bloquee bien el proceso
	desbloquear $0
	rdo=$?
fi

exit $rdo

#end feprima

