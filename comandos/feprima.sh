#!/bin/bash

##############################
# return: 
#       0       <->     OK      
#       1       <->     error de ejecucion
##############################

##############################
#       return validaciones
#       0 <-> invalido - false
#       1 <-> valido - true
##############################

########################################
# Verifica si el archivo pasado en $1
# ya fue aceptado.
########################################
esDuplicado(){
        local f 
        local aceptados=`ls "$ACEPTADOS"`
        for f in $aceptados
        do
                if [ "$f" = "$1" ]
                then
                return 1
                fi
        done
        return 0
}

########################################
# Valida el valor del punto de venta
# pasado en $1
########################################
ptoVentaValido(){
if [ `echo $1 | grep "^[0-9]\{4\}$"` ]
then 
        if [ $1 = "0000" ] || [ $1 = "9999" ]
        then 
        return  0 #invalido
        fi
return 1
fi
return  0 #invalido
} 

########################################
# Valida el valor del numero de comprobante
# pasado en $1
########################################
comprobanteValido(){
if [ `echo $1 | grep "^[0-9]\{8\}$"` ]
then 
        if [ $1 = "00000000" ] || [ $1 = "99999999" ]
        then 
        return  0 #invalido
        fi
return 1
fi
return  0 #invalido
} 

########################################
# Verifica que todos los campos del registro cabecera 
# pasado en $1 esten bien formados.
########################################
validar_formato_cabecera(){

cabecera=`head -n 1 "$1"`
OIFS=$IFS
IFS=';'
array=($cabecera)
cant_campos=${#array[@]}

if [ $cant_campos -eq 10 ]
then
        ptoVentaValido ${array[2]}
        puntoVenta=$?
        comprobanteValido  ${array[3]}
        comprobante=$?
        if [ `echo ${array[0]} | grep "^[0-9]\{11\}$"` ] && [ `echo ${array[1]} | grep "^[ABCE]\{1\}$"` ] && [ $puntoVenta  -eq 1 ] && [ $comprobante  -eq 1 ]
        then
                fechaEsValida ${array[4]}
                local r1=$?
                fechaEsValida ${array[5]}
                local r2=$?
                if [ $r1 -eq 1 ] && [ $r2 -eq 1 ]
                then
                if [ `echo ${array[6]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[7]} | grep "^[0-9]*\.[0-9][0-9]$"` ] &&   [ `echo ${array[8]} | grep "^[0-9]*\.[0-9][0-9]$"` ] && [ `echo ${array[9]} | grep "^[0-9]*\.[0-9][0-9]$"` ]
                then
                                IFS=$OIFS       
                                return 1; # valido
                        fi
                fi
        fi
fi
IFS=$OIFS
return 0; #invalido
}


#########################################
#       $1: archivo a validar           #
#       Return:         0 <-> OK        #
#                       1 <-> erronea   #
#                       2 <-> vencida   #
#########################################
validarCabecera(){

        validar_formato_cabecera "$1"
        if [ $? -eq 1 ]
        then
                #       verifico que el proveedor este en el registro maestro   #
                local cuit_prov=`head -n 1 "$1" | cut -d ';' -f 1`
                local resultado=`grep "^[^;]*;${cuit_prov};[^;]*;[^;]*;[^;]*;[^;]*$" "$grupo/prin/maepro.txt"`
                if [ -z "$resultado" ]
                then
                        glog.sh feprima WARN "No existe el proveedor con CUIT $cuit_prov en el archivo maestro de proveedores"
                        return 1
                fi
                #       en $resultado esta el registro del maestro de prov      #
                #       seteo COND_PAGO para grabarRegistro     #
                COND_PAGO=`echo "$resultado" | cut -d ';' -f 6`
                
                #       seteo las variables de fecha actual
                fechaHoy
                
                #       verifico la fecha de la factura
                
                local anio_fact=`head -n 1 "$1" | cut -d ';' -f 5 | cut -d '-' -f 1`
                local mes_fact=`head -n 1 "$1" | cut -d ';' -f 5 | cut -d '-' -f 2`
                local dia_fact=`head -n 1 "$1" | cut -d ';' -f 5 | cut -d '-' -f 3`
                
                if [ $anio_fact -gt $ANIO_HOY ]
                then
                        return 1
                fi
                if [ $anio_fact -eq $ANIO_HOY ] && [ $mes_fact -gt $MES_HOY ]
                then 
                        return 1
                fi
                if [ $anio_fact -eq $ANIO_HOY ] && [ $mes_fact -eq $MES_HOY ] && [ $dia_fact -gt $DIA_HOY ]
                then
                        return 1
                fi

                #       verifico vencimiento del CAE    #
                local fecha_cae=`head -n 1 "$1" | cut -d ';' -f 6`
                if [ $ANIO_HOY -lt `echo $fecha_cae | cut -d '-' -f 1` ]
                then
                        return 0         # Factura en fecha
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
                return 2        #       factura vencida
        fi
        return 1
                                
}
        
##################################################################
# Chequea, que la cuenta este bien, y q los montos sean positivos#
#       $1: MontoIVAItem  $2: MontoItem  $3:TasaIVAItem          #
##################################################################
monto_es_valido(){
        MontoTemp=`echo "$2 * $3 / 100" | bc -l | awk '{printf ("%.2f",$MontoTemp)}'`
   if [ $MontoTemp = $1 ]
    then
         if [ "$2" = "0.00" ]
         then
            return 0 #invalido
        else
            return 1 #valido
        fi
    else
        return 0 #invalido
    fi
}
#############################
#   $1: %iva                #
#############################
esta_gravado(){
    if [ "$1" = "0.00" ]
    then
                return 0
        else
                return 1
    fi
} 

#################################################
# Verifica que todos los campos del registro item 
# pasado en $1 esten bien formados.
#################################################
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


##########################################################
#       Valida los items de la factura  
#       $1: archivo a validar                   
#       return  0 <-> OK                                
#                       1 <-> error formato             
#                       2 <-> error totales             
##########################################################
validarItems(){
    local suma_monto_gravado=0
    local suma_monto_no_gravado=0
    local suma_monto_iva=0
local total=0
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
                                suma_monto_iva=`echo "$suma_monto_iva + $MontoItem * $TasaIVAItem / 100" | bc -l` 
                        else
                                IFS=$OFS
                                return 1
                        fi
                else
                        IFS=$OFS
                        return 1
                fi
    done
    
        suma_monto_iva=`echo "$suma_monto_iva" | bc -l | awk '{printf ("%.2f",$suma_monto_iva)}'`       
        
	#esto es para q coincida con el formato del archivo
        if [ "$suma_monto_no_gravado" = "0" ] 
        then
                suma_monto_no_gravado="0.00"
        fi
        if [ "$suma_monto_gravado" = "0" ] 
        then
                suma_monto_gravado="0.00"
        fi

    if [ "$suma_monto_no_gravado" = "`head -n 1 "$1" | cut -d ';' -f 7`" ]
    then
    if [ "$suma_monto_gravado" = "`head -n 1 "$1" | cut -d ';' -f 8`" ]
    then
    if [ "$suma_monto_iva" = "`head -n 1 "$1" | cut -d ';' -f 9`" ]
    then
        total=`echo "$suma_monto_iva + $suma_monto_no_gravado + $suma_monto_gravado" | bc -l`
        if [ "$total" = "`head -n 1 "$1" | cut -d ';' -f 10`" ]
        then
                return 0        # Los montos concuerdan con el encabezado
        fi
    fi
    fi
    fi
    IFS=$OFS   
    return 2
}

####################################################
# Graba un registro al final del archivo apagar.txt
#       $1: archivo de la factura                  
#       necesita seteada la variable COND_PAGO
####################################################
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


#######################################################
# Valida y procesa el archivo pasado por parametro
#       $1: archivo a procesar          
#######################################################
procesar(){
    validarCabecera "${RECIBIDOS}/$1"
    local rdo=$?
    if [ $rdo -eq 0 ]
    then
                validarItems "${RECIBIDOS}/$1"
                rdo=$?
                if [ $rdo -eq 0 ]
                then
                        grabarRegistro "${RECIBIDOS}/$1"
                        Mover "${RECIBIDOS}/$file" "$ACEPTADOS" feprima.log
                glog.sh feprima INFO "Factura Aceptada: $file"
                echo "Factura Aceptada: $file"
                else
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
                fi              
    else
                if [ $rdo -eq 1 ]
                then
                        echo "Factura Errónea en registro cabecera: $1"
                        glog.sh feprima ERROR "Factura Errónea en registro cabecera: $1"
                        Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
                fi
                if [ $rdo -eq 2 ]
                then
                        echo "Factura Vencida: $1"
                        glog.sh feprima WARN "Factura Vencida: $1"
                        Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
                fi
        fi

}

############################################
# Procesa todos los archivos disponibles en $RECIBIDOS
#
############################################
procesarArchivos(){

        cant_arch=`ls -l "$RECIBIDOS" | wc -l`
        cant_arch=`echo "$cant_arch - 1" | bc -l`
        echo "==================================================================="
        glog.sh feprima INFO "=============================================================="
        echo "Inicio de Feprima: $cant_arch"
        glog.sh feprima INFO "Inicio de Feprima: $cant_arch" 
        
        archivos=`ls "$RECIBIDOS"`
        for file in $archivos
        do      
        if [ -f "${RECIBIDOS}/$file" ]
        then            
                echo " "
                echo "Archivo a Procesar: $file"
                glog.sh feprima INFO "Archivo a Procesar: $file"
                esDuplicado "$file"
                if [ $? -eq 1 ]
                then
                        echo "Factura Duplicada: $file"
                        Mover "${RECIBIDOS}/$file" "$RECHAZADOS" feprima.log
                        glog.sh feprima WARN "Factura Duplicada: $file"
                else
                        procesar $file
                fi
        fi
        done
        echo "Fin de Feprima"
        glog.sh feprima INFO "Fin de Feprima"
        echo "==================================================================="
        glog.sh feprima INFO "=============================================================="
}


print_help(){
echo "
*******************************************************************************

Comando : feprima.sh 

Archivos de Input : Utiliza como input archivos que representan facturas ubicados en la carpeta \$grupo/recibidos.

Archivos de Output : 	Genera el archivo de log  \$grupo/comandos/feprima.log donde registra todo lo sucedido durante la ejecución del comando y luego, si las validaciones dan error mueve el archivo procesado a \$grupo/rechazados, sino lo mueve a \$grupo/aceptados  y escribe en el archivo \$grupo/facturas/apagar.txt un registro con los datos de la factura procesada.

Pre-condición: el ambiente fue inicializado y los archivos a procesar tienen el nombre bien formado.

Pos-condición: se agrega un registro al final del archivo \$grupo/facturas/apagar.txt

*******************************************************************************"
}

#########################
# feprima                               
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
