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

##################################################################
# Chequea, que la cuenta este bien, y q los montos sean positivos#
#	$1: MontoIVAItem  $2: MontoItem  $3:TasaIVAItem          #
##################################################################
monto_es_valido(){
    MontoTemp= `echo "$2 * $3 / 100" | bc -l`
    if [ $MontoTemp -e $1 ]
    then
	 if [ `echo $1 | bc -l` < 0 ] -o  [ `echo $2 | bc -l` < 0 ] -o [ `echo $3 | bc -l` < 0 ]
	 then
	    return 0; #invalido
	else
	    return 1; #valido
	fi
    else
	return 0; #invalido
    fi
}
#############################
#   $1: %iva                #
#############################
esta_gravado(){
    if [ $1 -e "0.00" ]
    then
	return 1; #true
    else
	return 0; #false
    fi
} 


#################################
#	$1: archivo a validar		#
#################################
validarItems(){
    local suma_monto_gravado
    local suma_monto_no_gravado
    local suma_monto_iva
    
    lineas=`sed 1d $1`
    for linea in lineas
    do
    local DescItem = `echo $linea | cut -d ';' -f 1`
    local MontoItem = `echo $linea | cut -d ';' -f 2`
    local TasaIVAItem = `echo $linea | cut -d ';' -f 3`
    local MontoIVAItem = `echo $linea | cut -d ';' -f 4`
    if [ `monto_es_valido $MontoIVAItem $MontoItem $TasaIVAItem` -e 1]
    then
	if [ `esta_gravado $TasaIVAItem` -e 1 ]
	then
	    $suma_monto_gravado = `echo "$suma_monto_gravado + $MontoItem" | bc -l` 
	else
	    $suma_monto_no_gravado = `echo "$suma_monto_no_gravado + $MontoItem" | bc -l` 
	fi
	$suma_monto_iva = `echo "$suma_monto_iva + $MontoIVAItem" | bc -l` 
    else 
      return 1
    fi
    done
    
    #	comparar los valores de los acumuladores con los del encabezado
    if [ $suma_monto_no_gravado -eq `head -n 1 "$1" | cut -d ';' -f 7` ]
    then
    if [ $suma_monto_gravado -eq `head -n 1 "$1" | cut -d ';' -f 8` ]
    then
    if [ $suma_monto_iva -eq `head -n 1 "$1" | cut -d ';' -f 9` ]
    then
    	local total=`echo "$suma_monto_iva + $suma_monto_no_gravado + $suma_monto_gravado" | bc -l`
    	if [ $total -eq `head -n 1 "$1" | cut -d ';' -f 10` ]
    	then
    		return 0 	# Los montos concuerdan con el encabezado
    	fi
    fi
    fi
    fi
    
    echo Los montos no concuerdan con el encabezado 
    return 1
}


#################################
#	$1: archivo a validar		#
#################################
validacionFinal(){
    return 0    
}

#############################################
#	$1: archivo de la factura				#
# 	necesita seteada la variable COND_PAGO	#
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
if [ -z $INI_FEPINI ]
then
	echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente.
	#Glog -se "No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. "
	exit 1
fi

bloquear "$0"
procesarArchivos
desbloquear "$0"
rdo=$?

exit $rdo

#end feprima





