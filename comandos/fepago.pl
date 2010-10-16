#! /usr/bin/perl

$TRUE = 1;
$FALSE = 0;

/* Clave: FUENTE => Valor: monto disponible */
%fuentes;
/*Cada elemento es un registro completo APAGAR */
@comprometidos;
/* Clave: CAE => Valor: TRUE|FALSE */
%disponibilidad;


##################################
# Verifica que no haya otro fepago corriendo	#
#########################
sub estaCorriendoFepago{
	$x=`ps | grep '^.*fepago\.sh\$'`;
	if ( $x ){
		print 'Error: fepago ya se está ejecutando'."\n";
		exit 1;
	}
	else{
		exit 0;
	}
}

##################################
# Verifica que no haya otro feprima corriendo	#
#########################
sub estaCorriendoFrima{
	$x=`ps | grep '^.*feprima\.sh\$'`;
	if ( $x ){
		print 'Error: feprima ya se está ejecutando'."\n";
		exit 1;
	}
	else{
		exit 0;
	}
}

#########################
# Verifica si esta  inicializado el ambiente	#
#########################
sub initAmbiente{
	if ( -z $INI_FEPINI )
	{
		print 'No se ha inicializado el ambiente. Debe ejecutarse el comando fepini.sh previamente'. "\n";
		$text="No se ha inicializado el ambiente";
		system("./glog.sh fepago SERROR $text");
		exit 1;
	}
	else{
		exit 0;
	}	
}

####################################
# Iniciliza %fuentes
####################################
sub leer_presupuesto{

my($FD,$linea,@campos);

open(FD,"<$PRESUPUESTO");
while($linea = <FD>){
	chomp($linea);
	@campos=split(";",$linea);
	$fuentes{$campos[0]}= $campos[1];	
}

close(FD);

}


########################################################################
# Determina una fuente, segun el monto pasado
########################################################################

sub get_fuente{

my($monto,$fuente);

$monto = $_[0];
if( $monto < 1000){
	$fuente="11";
} elsif ( $monto >= 1000 && $monto<10000 ){
	$fuente="12";
} elsif ( $monto >= 1000 && $monto<10000 ){
	$fuente="13";
} elsif ( $monto >= 10000 && $monto<150000 ){
	$fuente="14";
} elsif ( $monto >= 150000 ){
	$fuente="15";
}
return ($fuente);
}

####################################
# Verifica si alcanza el monto disponible
# en la fuente para cubrir el monto a pagar.
####################################

sub check_disponibilidad{

my($monto,$fuente);

$monto = $_[0];
$fuente= &get_fuente($monto);
if($fuentes{$fuente} >= $monto  ){
	return ($TRUE);
}

return ($FALSE);

}

####################################
# Actualiza el monto disponible en una fuente. (En memoria, no en el archivo)
####################################

sub actualizar_disponibilidad{

my($monto,$fuente);

$monto = $_[0];
$fuente= &get_fuente($monto);
$fuentes{$fuente} -= $monto;

}


sub mostrar_registros_comprometidos{

my($registro,@campos);

	foreach $registro (comprometidos) {
		@campos=split(";",$registro);
		if($disponibilidad{$campos[1]} == $TRUE ){
			print $campos[0]."-".$campos[2]."-".$campos[3]."-LIBERADA\n";
		}else{
			print $campos[0]."-".$campos[2]."-".$campos[3]."-A PAGAR\n";
		}
	}
}


sub mostrar_presupuesto{
my($FD,$linea,@campos);

open(FD,"<$PRESUPUESTO");
while($linea = <FD>){
	chomp($linea);
	@campos=split(";",$linea);
	print	$campos[0]."-".$campos[1]."-".$fuentes{$campos[0]}."\n";
}

close(FD);

}



#################################
#		$0 archivo $1 dir_dest
#################################
sub backup_archivo{
	@num=`ls | sed \'s/.*\\.\\(.*\\)\$/\\1/g\' | sort -n`;
	$ultima_version= $num[-1];
	$ultima_version++;
	$cmd = "cp $_[0] $_[1]/$_[0]\.$ultima_version";
	system($cmd);
}

#################################
#		Fepago		#
#################################

&estaCorriendoFepago;
&estaCorriendoFeprima;
&initiAmbiente;

# end Fepago
