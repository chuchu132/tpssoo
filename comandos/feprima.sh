#!/bin/bash

##############################
# return: 
#	0	<->	OK	
#	1	<->	error de ejecucion
##############################

##############################
#	return validaciones
#	0 <-> invalido - false
#	1 <-> valido - true
##############################



fechaEsValida(){
if [ ! `echo $1 | grep "^[0-9]\{4\}-[0-1][0-9]-[0-3][0-9]$"` ] 
then	
	echo LA FECHA NO TIENE EL FORMATO
	return 0 #invalida
fi

OIFS=$IFS
IFS='-'
arr=($1)

dd=${arr[2]}
mm=${arr[1]}
yy=${arr[0]}
 
days=0
 
if [ $mm -le 0 -o $mm -gt 12 ];
then
    IFS=$OFS
    echo ERROR MES!
    return 0 #invalida
fi
 
case $mm in
   01) days=31;;
   02) days=28 ;;
   03) days=31 ;;
   04) days=30 ;;
   05) days=31 ;;
   06) days=30 ;;
   07) days=31 ;;
   08) days=31 ;;
   09) days=30 ;;
   10) days=31 ;;
   11) days=30 ;;
   12) days=31 ;;
    *)  days=-1 ;;
esac

if [ $mm -eq 2 ]; 
then
	if [ $((yy % 4)) -ne 0 ] && [ $((yy % 400)) -eq 0 ] && [ ! $((yy % 100)) -eq 0 ]
	then
	   days=29
	fi
fi

if [ $dd -le 0 ] || [ $dd -gt $days ]
then
	IFS=$OFS
	echo ERROR DIAS!!!!!!!!!
	return 0 #invalida
fi

IFS=$OFS
echo VALIDA!
return 1 #valida

}






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


validar_formato_cabecera(){
#0 CUITProveedor  11 Dígitos. Clave Única de Identificación Tributaria
#1 codigoTipoComprobante 1 Carácter. VALORES posibles A B C E
#2 numeroPuntoVenta 4 Caracteres. Valores posibles 0001 a 9998
#3 numeroComprobante 8 Caracteres. Valores posibles 00000001 a 99999998
#4 fechaFactura
#5 fechaVencimientoCAE

cabecera=`head -n 1 "$1"`
OIFS=$IFS
IFS=';'
array=($cabecera)
cant_campos=${#array[@]}

if [ $cant_campos -eq 10 ]
then

	if [ `echo ${array[0]} | grep "^[0-9]\{11\}$"` ] && [ `echo ${array[1]} | grep "^[ABCE]\{1\}$"` ] && [ `echo ${array[2]} | grep "^[0-9]\{3\}[0-8]$"` ] && [ `echo ${array[3]} | grep "^[0-9]\{7\}[0-8]$"` ]
	then
		if [ `fechaEsValida ${array[4]}` ] && [ `fechaEsValida ${array[5]}` ] 
		then
	        if [ `echo ${array[6]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[7]} | grep "^[0-9]*\.[0-9][0-9]$"` ] &&   [ `echo ${array[8]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[9]} | grep "^[0-9]*\.[0-9][0-9]$"` ]
	        then
				IFS=$OIFS       
				echo ______________ VALIDAR FORMATO CABECEERA VALIDO _______________________
				return 1; # valido
			fi
		fi
	fi
fi
IFS=$OIFS
echo ______________ VALIDAR FORMATO CABECERA NO VALIDO _______________________
return 0; #invalido
}


#################################
#	$1: archivo a validar		#
#################################
validarCabecera(){

	validar_formato_cabecera "$1"
	if [ $? -eq 1 ]
	then
		#	verifico que el proveedor este en el registro maestro	#
		local cuit_prov=`head -n 1 "$1" | cut -d ';' -f 1`
		local resultado=`grep "^.*;${cuit_prov};.*;.*;.*;.*$" "$grupo/prin/maepro.txt"`
		if [ $? -ne 0 ]
		then
			echo No existe el proveedor con CUIT $cuit_prov en el archivo maestro de proveedores 
			glog.sh feprima WARN "No existe el proveedor con CUIT $cuit_prov en el archivo maestro de proveedores"
			return 1
		fi
		#	en $resultado esta el registro del maestro de prov	#
		#	seteo COND_PAGO para grabarRegistro	#
		COND_PAGO=`echo "$resultado" | cut -d ';' -f 6`
		
		#	seteo las variables de fecha actual
		fechaHoy
	
		#	verifico vencimiento del CAE	#
		local fecha_cae=`head -n 1 "$1" | cut -d ';' -f 6`
		if [ $ANIO_HOY -lt `echo $fecha_cae | cut -d '-' -f 1` ]
		then
			return 0	 # Factura en fecha
		else
			if [ $ANIO_HOY -eq `echo $fecha_cae | cut -d '-' -f 1` ]
			then
			if [ $MES_HOY -lt `echo $fecha_cae | cut -d '-' -f 2` ]
			then 
				return 0
			else
				if [ $MES_HOY -eq `echo $fecha_cae | cut -d '-' -f 2` ]
				then
				if [ $DIA_HOY -le `echo $fecha_cae | cut -d '-' -f 3` ]
				then
					return 0	
				fi
				fi
			fi
			fi
		fi
		echo "Factura Vencida: $1"
		glog.sh feprima WARN "Factura Vencida: $1"
		return 1
	fi
	return 1
				
}
	
##################################################################
# Chequea, que la cuenta este bien, y q los montos sean positivos#
#	$1: MontoIVAItem  $2: MontoItem  $3:TasaIVAItem          #
##################################################################
monto_es_valido(){
    MontoTemp=`echo "$2 * $3 / 100" | bc -l | sed 's/^\([^.]*\...\).*/\1/g'`
    if [ $MontoTemp = $1 ]
    then
	 if [ "$1" "<" "0" ] || [ "$2" "<" "0" ] || [  "$3" "<" "0" ]
	 then
	 				echo ______________ MONTO  INVALIDO _______________________
	    return 0 #invalido
	else
					echo ______________ MONTO ES VALIDO _______________________
	    return 1 #valido
	fi
    else
    				echo ______________ MONTO INVALIDO _______________________
	return 0 #invalido
    fi
}
#############################
#   $1: %iva                #
#############################
esta_gravado(){
    if [ $1 = "0.00" ]
    then
	return 1; #true
    else
	return 0; #false
    fi
} 

#DescItem N Caracteres. Descripción del Item
#PrecioItem Importe (N enteros y 2 dígitos decimales). Valor del Item antes de aplicar IVA
#tasaIVAItem Importe (N enteros y 2 dígitos decimales). Tasa de IVA aplicable al ítem. Los productos no gravados tienen tasa de iva cero. El valor habitual es 21. Representa un porcentaje.
#montoIVAItem           Importe (N enteros y 2 dígitos decimales). Monto del Iva resultante de aplicar la tasa al precio.

validarFormatoItems(){
	OIFS=$IFS
	IFS=';'
	array=($1)
	cant_campos=${#array[@]}
	res=0
	if [ $cant_campos -eq 4 ]
	then
		if [ `echo ${array[1]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[2]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[3]} | grep "^[0-9]*\.[0-9][0-9]$"` ]
		then
			res=1
		fi	
	fi
	IFS=$OIFS
	return $res;
}

#####################################
#	Valida los items de la factura	#
#	$1: archivo a validar			#
#	return 	0 <-> OK				#
#			1 <-> error formato		#
#			2 <-> error totales		#
#####################################
validarItems(){
    local suma_monto_gravado=0
    local suma_monto_no_gravado=0
    local suma_monto_iva=0
    OIFS=$IFS
IFS='
'
    for linea in `sed 1d "$1"`
    do
    	echo $linea
		validarFormatoItems "$linea"
		if [ $? -eq 1 ]
		then
			local DescItem=`echo $linea | cut -d ';' -f 1`
			local MontoItem=`echo $linea | cut -d ';' -f 2`
			local TasaIVAItem=`echo $linea | cut -d ';' -f 3`
			local MontoIVAItem=`echo $linea | cut -d ';' -f 4`
			monto_es_valido $MontoIVAItem $MontoItem $TasaIVAItem
			if [ $? -eq 1 ]
			then
			esta_gravado $TasaIVAItem
			if [ $? -eq 1 ]
			then
				suma_monto_gravado=`echo "$suma_monto_gravado + $MontoItem" | bc -l` 
			else
				suma_monto_no_gravado=`echo "$suma_monto_no_gravado + $MontoItem" | bc -l` 
			fi
			suma_monto_iva=`echo "$suma_monto_iva + $MontoIVAItem" | bc -l` 
			else
			echo ___monto invalido ____
			IFS=$OFS
			return 1
			fi
		else
			echo .-.-.monto invalido -.-.
			IFS=$OFS
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
    		echo _____________los montos concuerdan ___________
    		return 0 	# Los montos concuerdan con el encabezado
    	fi
    fi
    fi
    fi
    IFS=$OFS    
    return 2
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
    validarCabecera "${RECIBIDOS}/$1"
    if [ $? -eq 0 ]
    then
		validarItems "${RECIBIDOS}/$1"
		local rdo=$?
		if [ $rdo -eq 0 ]
		then
			grabarRegistro "${RECIBIDOS}/$1"
			Mover "${RECIBIDOS}/$file" "$ACEPTADOS" feprima.log
	        glog.sh feprima INFO "Factura Aceptada: $file"
		fi
		if [ $rdo -eq 2 ]
		then
			echo "Factura Errónea, no coinciden los totales: $1"
			glog.sh feprima ERROR "Factura Errónea no coinciden los totales: $1"
			Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
		fi
		if [ $rdo -eq 1 ]
		then
			echo "Factura Errónea en registro item: $1"
			glog.sh feprima ERROR "Factura Errónea en registro item: $1"
			Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
		fi
		
    else
	    echo "Factura Errónea en registro cabecera: $1"
	    glog.sh feprima ERROR "Factura Errónea en registro cabecera: $1"
	    Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
    fi

}

procesarArchivos(){

	cant_arch=`ls -l "$RECIBIDOS" | wc -l`
	cant_arch=`echo "$cant_arch - 1" | bc -l`
	echo "==================================="
	echo "Inicio de Feprima: $cant_arch"
	glog.sh feprima INFO "=============================="
	glog.sh feprima INFO "Inicio de Feprima: $cant_arch" 
	
	archivos=`ls "$RECIBIDOS"`
	for file in $archivos
	do
		echo " "
		echo "Archivo a Procesar: $file"
		glog.sh feprima INFO "Archivo a Procesar: $file"
		repetido=`esDuplicado "$file"`
		if [ $repetido ]
		then
			echo "Factura Duplicada: $file"
			Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
			glog.sh feprima WARN "Factura Duplicada: $file"
		else
			procesar $file
		fi
	done
	echo "Fin de Feprima"
	echo "==================================="
	glog.sh feprima INFO "Fin de Feprima"
	glog.sh feprima INFO "=============================="
}

#########################
# feprima				#
#########################
if [ -z $INI_FEPINI ]
then
	echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente.
	./glog.sh feprima SERROR "No se ha inicializado el ambiente."
	exit 1
fi

bloquear "$0"
rdo=$?
if [ $rdo -eq 0 ]
then
        procesarArchivos
        desbloquear "$0"
        rdo=$?
fi

exit $rdo

#end feprima





