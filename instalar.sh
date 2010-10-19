#!/bin/bash

echo "Instalando"

tar -xvf carpetas.tar > /dev/null
if [ $? -ne 0 ]
then
	echo "Ocurrio un error durante la instalacion"
	exit 1
fi

find ./comandos -name "*" -exec chmod +x {} \;

echo "Instalacion Exitosa"
exit 0
#end instalar.sh

