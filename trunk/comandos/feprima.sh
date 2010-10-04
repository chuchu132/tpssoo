#!/bin/bash



##############################
# return: 
#	0	<->	OK	
#	1	<->	error de ejecucion
##############################

function esta_corriendo{
	#falta chekear que no este corriendo feprima
	if [ -z $INI_FEPINI ]
	then
		echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. 
		Glog -se "No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. "
		exit 1
	fi
	}

function es_duplicado {
	local aceptados=`ls $ACEPTADOS`
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

function validar_cabecera { 
    return 0
}

function validar_items {
    return 0
}

function validacion_final {
    return 0    
}

function grabar_registro {
    return 0
}

function procesar {
    $ok=validar_cabecera $1
    if[ -z $ok ]
    then
	$ok=validar_items $1
	if[ -z $ok ]
	then
	    $ok=validacion_final $1
	    if[ -z $ok ]
	    then
		grabar_registro
	    else
		#Glog -se "Factura Errónea no coinciden los totales: $1"
	    fi
	else
	#Glog -se "Factura Errónea en registro de ítem: $1"
	fi
    else
    #Glog -se "Factura Errónea en registro cabecera: $1"
    fi

}

function procesar_archivos {
echo "Grupo: $grupo"
cant_arch=`ls -l $RECIBIDOS | wc -l`
cant_arch=`echo "$cant_arch - 1" | bc -l`
echo "Inicio de Feprima: $cant_arch"
# Glog -i "Inicio de Feprima: $cant_arch" 
archivos=`ls $RECIBIDOS`
	for file in $archivos
	do
	# Glog -i "Archivo a Procesar: $file"
	repetido= es_duplicado $file
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
esta_corriendo
procesar_archivos
ret="$?"
echo Resultado $ret
exit $ret

#end feprima

