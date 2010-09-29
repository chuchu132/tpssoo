#!/bin/bash

# feprima

##############################
# return: 
#	0	<->	OK	
#	1	<->	error de ejecucion
##############################

esta_corriendo() {

	#falta chekear que no este corriendo feprima
	if [ -z $INI_FEPINI ]
	then
		echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. 
		Glog -se "No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente. "
		exit 1
	fi
}


esta_corriendo

cant_arch=`ls -l | wc -l`
cant_arch=`echo "$cant_arch - 1" | bc -l`
echo "Inicio de Feprima: $cant_arch"
# Glog -i "Inicio de Feprima: $cant_arch" 


ret="$?"
echo Resultado $ret
return $ret

#end feprima

