#!/bin/bash

# Borra los locks que pudieron quedar en caso de cierre forzado

for arch in `ls temp | grep '.*\.lck$'`
do
	echo "Borrando $arch"
	rm -f "temp/$arch"
done

