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

#################################
#	$1: archivo a validar		#
#################################
validarCabecera(){ 
	
	#	verifico que el proveedor este en el registro maestro	#
	local cuit_prov=`head -n 1 "$1" | cut -d ';' -f 1`
	local resultado=`grep -q "^.*;${cuit_prov};.*;.*;.*;.*$" "$grupo/prin/maepro.txt"`
	if [ $? -ne 0 ]
	then
		echo No existe el proveedor con CUIT $cuit_prov en el archivo maestro de proveedores
		return 1
	fi
	
	#	seteo COND_PAGO para grabarRegistro	#
	COND_PAGO=`echo "$resultado" | cut -d ';' -f 6`
	
	#	verifico vencimiento del CAE	#
	local fecha_cae=`head -n 1 "$1" | cut -d ';' -f 6`
	if [ `echo $fecha_cae | cut -d '-' -f 1` -ge $ANIO_HOY ]
	then
		if [ `echo $fecha_cae | cut -d '-' -f 2` -ge $MES_HOY ]
		then
			if [ `echo $fecha_cae | cut -d '-' -f 3` -gt $DIA_HOY ]
			then
				return 0
			fi
		fi
	fi
	echo "Factura Vencida: $1"
	return 1
	#TODO validar formato y validaciones extra
}


#################################
#	$1: archivo a validar		#
#################################
validarItems(){
    return 0
}


#################################
#	$1: archivo a validar		#
#################################
validacionFinal(){
    return 0    
}

#############################################
#	$1: archivo de la factura				#
# 	necesita seteadas la variable COND_PAGO	#
#############################################
grabarRegistro(){
	local cae=`basename "$1"`
	local monto=`head -n 1 "$1" | cut -d ';' -f 10`
	local vto=`head -n 1 "$1" | cut -d ';' -f 5`
	if [ ! -z $COND_PAGO ]
	then
		vto=`date --date "${vto} ${COND_PAGO} days" "+%Y-%m-%d"`
	fi
	local registro="${cae};A PAGAR;${vto};${monto}"
	echo $registro >> "$grupo/facturas/apagar.txt"
    return 0
}


#################################
#	$1: archivo a procesar		#
#################################
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

procesarArchivos(){

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
	echo "Fin de Feprima"
	#Glog
}

#########################
# feprima				#
#########################

iniTests $0
if [ $? -eq 0 ]
then
	sleep 10	## TODO esta para ver que se bloquee bien el proceso
	procesarArchivos
	desbloquear $0
	rdo=$?
fi

exit $rdo

#end feprima

