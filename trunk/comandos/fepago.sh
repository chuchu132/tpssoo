# Verifica que no haya otro fepago corriendo	#
#########################
estaCorriendoFepago(){
	x=`ps | grep '^.* fepago\.sh$'`
	if [ $? -eq 0 ]
	then
		echo "Error: fepago ya se está ejecutando."
		pid=`ps | grep '^.* fepago\.sh$' | sed 's/ \?\([0-9]*\).*/\1/'`
		echo "Pid=${pid}"
		echo ""
		exit 1
	fi
}

#########################
# Verifica si esta  inicializado el ambiente	#
#########################
initAmbiente(){
	if [ -z $INI_FEPINI ]
	then
		echo No se ha inicializado el ambiente. Debe ejecutarse el comando \". fepini.sh\" previamente.
		./glog.sh fepago SERROR "No se ha inicializado el ambiente."
		exit 1
	fi
}

#########################
# Verifica que no haya otro feprima corriendo	#
#########################
estaCorriendoFeprima(){
	x=`ps | grep '^.* feprima\.sh$'`
	if [ $? -eq 0 ]
	then
		echo "Error: feprima ya se está ejecutando."
		pid=`ps | grep '^.* feprima\.sh$' | sed 's/ \?\([0-9]*\).*/\1/'`
		echo "Pid=${pid}"
		echo ""
		exit 1
	fi
}


#########################
# fepago				#
#########################

estaCorriendoFepago
#initAmbiente
estaCorriendoFeprima



#end fepago
