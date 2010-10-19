#!/usr/bin/perl

$TRUE = 1;
$FALSE = 0;

#Clave: FUENTE => Valor: monto disponible
%fuentes;
#Cada elemento es un registro completo APAGAR
@comprometidos;
#Clave: CAE => Valor: TRUE|FALSE
%disponibilidad;
#Parametros ingresados por el usuario
$cadena;
$modobarr;
$modoejec;
$fechadesde;
$fechahasta;
$montodesde;
$montohasta;
$fechalimite = "2050-12-31";
$entrada = "$ENV{'grupo'}/facturas/apagar.txt";
$presupuesto = "$ENV{'grupo'}/prin/presu.txt";
#Registros a incluir en el nuevo apagar.txt
@regApagar;
#Registros a incluir en el nuevo presu.txt
@regPresu;


##################################
# Verifica que no haya otro fepago corriendo	#
#########################

sub estaCorriendoFepago{
	$x=`ps | grep '^.*fepago\.sh\$'`;
	if ( $x ){
		print 'Error: fepago ya se esta ejecutando'."\n";
		exit 1;
	}
}

##################################
# Verifica que no haya otro feprima corriendo	#
#########################

sub estaCorriendoFeprima{
	$x=`ps | grep '^.*feprima\.sh\$'`;
	if ( $x ){
		print 'Error: feprima ya se esta ejecutando'."\n";
		exit 1;
	}
}

#########################
# Verifica si esta  inicializado el ambiente	#
#########################

sub initAmbiente{
	if ( ! $ENV{"INI_FEPINI"} )
	{
		print 'No se ha inicializado el ambiente. Debe ejecutarse el comando fepini.sh previamente'. "\n";
		$text="No se ha inicializado el ambiente";
		chop($text);
	      	@args = ('glog.sh',"fepago","SERROR","$text");
		system(@args);
		exit 1;
	}
		
}

####################################
# Inicializa %fuentes
####################################

sub leerPresupuesto{

    my($FD,$linea,@campos);

    open(FD,"<$presupuesto");
    while($linea = <FD>){
	chomp($linea);
	#Cargo el hash %fuentes
	@campos=split(";",$linea);
	$fuentes{$campos[0]}= $campos[1];

	#print "$campos[0], $campos[1]\n";
  }

  close(FD);
}

####################################
# Muestra %fuentes
####################################

sub mostrarPresupuesto{

    my($FD,$linea,@campos,$nuevaLinea);

    open(FD,"<$presupuesto");
    while($linea = <FD>){
	chomp($linea);
	@campos=split(";",$linea);
	print	$campos[0]." - ".$campos[1]." - ".$fuentes{$campos[0]}."\n";
	
	#se guardan indistintamente para -ms o -ma, solo para -ma se persisten
	$nuevaLinea = $campos[0].";".$fuentes{$campos[0]}.";".$campos[2].";".$campos[3]."\n";
	push (@regPresu, $nuevaLinea);
    }
    close(FD);
}

sub mostrarPresupuestoMem{

    @claves = keys(%fuentes);
    @valores = values(%fuentes);

    $cantValores = @claves;
    $x = 0;  

    while ($x <= $cantValores){
      print "$claves[$x] - $valores[$x]\n";
      $x++;
    }
}

########################################################################
# Determina una fuente, segun el monto pasado
########################################################################

sub getFuente{

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

sub checkDisponibilidad{

    my($monto,$fuente);

    #print "Verificando disponibilidad\n";
    $monto = $_[0];
    $fuente= &getFuente($monto);
    if($fuentes{$fuente} >= $monto){
	#print "Hay disponibilidad\n";
	return ($TRUE);
    }
    #print "No hay disponibilidad\n";
    return ($FALSE);

}

####################################
# Actualiza el monto disponible en una fuente. (En memoria, no en el archivo)
####################################

sub actualizarDisponibilidad{

    my($monto,$fuente);

    $monto = $_[0];
    $fuente= &getFuente($monto);
    $fuentes{$fuente} -= $monto;

    return 0;
}


sub mostrarRegistrosComprometidos{

    my($registro,@campos);

    foreach $registro (@comprometidos) {
	@campos = split(";",$registro);

	print $campos[0]." - ".$campos[2]." - ".$campos[3]." - ".$campos[1]."\n";
    }
    return 0;
}

sub mostrarRegistrosAgrabar{

    my($registro,@campos);

    foreach $registro (@regApagar) {
	@campos = split(";",$registro);

	print $campos[0]." - ".$campos[2]." - ".$campos[3]." - ".$campos[1]."\n";
    }
    return 0;
}

#################################
#	Persistencia para Modo Actualizar
#################################

sub backupArchivo{
       my(@num,@rutas,$ultima_version,$cmd,$archivo);
       @num=`ls $_[1] | sed \'s/.*\\.\\(.*\\)\$/\\1/g\' | sort -n`;
       $ultima_version= $num[-1];
       $ultima_version++;
       @rutas=split('/',$_[0]);
       $archivo= $rutas[-1];
        
       $cmd = "cp $_[0] $_[1]$archivo\.$ultima_version";
       #print "$_[0] $_[1]$archivo\.$ultima_version\n"; 
       system($cmd);
}

#################################
#	Pide parametros al usuario y los carga en variables globales	
#################################
sub pedirParametros{

	print "Ingrese parametros o -q para terminar el proceso\n";

	$cadena = <STDIN>;
	@param = split (" ", $cadena);

	$cant = @param;
	#print "Cantidad de parÃ¡metros= $cant\n";

	#Validacion  
	if (($param[0] eq "-ms") or ($param[0] eq "-ma") or ($param[0] eq "-q")){
	  $modoejec = $param[0];
	}
	else {
	  print "Debe ingresar un modo de ejecucion (-ms,-ma o -q para terminar)\n";
	  #exit 0;
	} 

	if (($param[1] eq "-bf") or ($param[1] eq "-bi") or ($param[1] eq "-bfi")){
	  $modobarr = $param[1];
	  if ($modobarr eq "-bf"){
	    #tomo 2 parametros
	    &validarFecha ($fechadesde = $param[2]);
	    &validarFecha ($fechahasta = $param[3]);
	  }
	  if ($modobarr eq "-bi"){
	    #tomo 2 parametros
	    &validarMonto ($montodesde = $param[2]);
	    &validarMonto ($montohasta = $param[3]);
		}
	  if ($modobarr eq "-bfi"){
	    #tomo 3 parametros
	    &validarFecha ($fechadesde = $param[2]);
	    &validarFecha ($montodesde = $param[3]);
	    &validarMonto ($montohasta = $param[4]);
	  }
	}
	else {
	  print "Debe ingresar un modo de barrido (-bf,-bi o -bfi)\n";
	  #exit 0;
	}
    
	return 0;
}

#################################
#	Validar fecha
#################################
sub validarFecha(){
	my($fecha,@args1,@args2);
	$fecha=$_[0];
	@args1 = ('fechaEsValida',"$fecha");
	system(@args1);
	if ( $? == 0){
		print "Formato fecha invalido: $fecha\n";
		print "Formato fecha valido: YYYY-MM-DD\n";
		@args2 = ('glog.sh',"fepago","ERROR","Error. Fecha invalida: $fecha");
	    system(@args2);
		exit 1;
	}	
}
#################################
#	Validar monto
#################################
sub validarMonto(){
	my($monto,@args2);
	$monto=$_[0];
	#print "monto a validar $monto\n";
	if ($monto < 0){
		print "El monto: $monto es negativo\n";
		@args2 = ('glog.sh',"fepago","ERROR","Error. Monto negativo: $monto.");
	    system(@args2);
		exit 1;
	}
	if ($monto=~ /^[0-9]*\.[0-9][0-9]$/){
		return;
	}

	print "Formato monto no valido: $monto\n";
	print "Formato monto valido: numero.2decimales (ej. 54.00)\n";
	@args2 = ('glog.sh',"fepago","ERROR","Error. Monto invalida: $monto");
    system(@args2);
	exit 1;	
}

#################################
#	Inicializa el log	
#################################

sub inicializarLog{
	my(@args);
	$textIni="Inicio de fepago $cadena";
	chop($textIni);
	@args = ('glog.sh',"fepago","ERROR","$textIni");
    system(@args);
    return $result;
}

#################################
#	Comparacion  de Fechas	
#################################

sub fechaEsMayor{
    
    my($fecha, @arregloFecha, @arregloFechaMenor);

    $fecha = $_[0];
    @arregloFecha = split ("-", $fecha);
    @arregloFechaMenor = split("-", $fechadesde);

    if ($arregloFecha[0] > $arregloFechaMenor[0]){	#comparo aÃ±os
      return ($TRUE);
    } elsif ($arregloFecha[0] < $arregloFechaMenor[0]){
	return ($FALSE);
      } elsif ($arregloFecha[0] = $arregloFechaMenor[0]){
	  if ($arregloFecha[1] > $arregloFechaMenor[1]){	#comparo meses
	    return ($TRUE);
	  } elsif ($arregloFecha[1] < $arregloFechaMenor[1]){
	      return ($FALSE);
	    } elsif ($arregloFecha[1] = $arregloFechaMenor[1]){
		if ($arregloFecha[2] > $arregloFechaMenor[2]){  	#comparo dias
		  return ($TRUE)
		} elsif ($arregloFecha[2] < $arregloFechaMenor[2]){
		    return ($FALSE);
		  } elsif ($arregloFecha[2] = $arregloFechaMenor[2]){
		      return ($TRUE);
		    }
	      }
	}
}

sub fechaEsMenor{
    
    my($fecha, @arregloFecha, @arregloFechaMayor);

    $fecha = $_[0];
    @arregloFecha = split ("-", $fecha);
    @arregloFechaMayor = split("-", $fechahasta);

    if ($arregloFecha[0] < @arregloFechaMayor[0]){	#comparo aÃ±os
      return ($TRUE);
    } elsif ($arregloFecha[0] > @arregloFechaMayor[0]){
	return ($FALSE);
      } elsif ($arregloFecha[0] = @arregloFechaMayor[0]){
	  if ($arregloFecha[1] < @arregloFechaMayor[1]){	#comparo meses
	    return ($TRUE);
	  } elsif ($arregloFecha[1] > @arregloFechaMayor[1]){
	      return ($FALSE);
	    } elsif ($arregloFecha[1] = @arregloFechaMayor[1]){
		if ($arregloFecha[2] < @arregloFechaMayor[2]){  	#comparo dias
		  return ($TRUE)
		} elsif ($arregloFecha[2] > @arregloFechaMayor[2]){
		    return ($FALSE);
		  } elsif ($arregloFecha[2] = @arregloFechaMayor[2]){
		      return ($TRUE);
		    }
	      }
	}
}

#################################
#	Determinimar los registros comprometidos	
#################################

sub determinarComprometidos{

      #Abrir archivo Facturas a Pagar
      open ( ENT, "<$entrada" ) or die "No se pudo abrir el archivo $entrada : $!";
      while ( $registro = <ENT> ){
	
	#print $registro;
	#34567890123456;A PAGAR;2009-12-10;727.92
	#45678901234567;A PAGAR;2010-04-01;1053.67
	chomp($registro);
	@apagar = split(';',$registro);
	$montoapagar = $apagar[3];
	$fechaapagar = $apagar[2];

	#printf "modo barrido = $modobarr\n";

	if ( $modobarr eq "-bi" ){
	  if ( ($montoapagar > $montodesde) && ($montoapagar < $montohasta ) ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      if ( $apagar[1] eq "A PAGAR" ){
		if (&checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #print "registro comprometido\n";
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro);
		  #if ($modoejec eq "-ma"){
		  #`echo $registro > "apagar2.txt"`;
		  #}
		  &actualizarDisponibilidad($apagar[3]);    	
		} else { #No hay disponibilidad
		    #Siguen como A PAGAR
		    push (@comprometidos, $registro);
		    push (@regApagar, $registro);
		  }
	      }else { #Ya esta liberada
		push (@regApagar, $registro); 
	       }
	  } else { #No esta dento del rango pedido
	      push (@regApagar, $registro); 
	    }
	}

	if ( $modobarr eq "-bf" ){
	  $valorMayor = &fechaEsMayor($fechaapagar);  
	  $valorMenor = &fechaEsMenor($fechaapagar);  
	  if ( $valorMayor && $valorMenor ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      if ( $apagar[1] eq "A PAGAR" ){
		if (&checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro); 
		  &actualizarDisponibilidad($apagar[3]);    	
		} else { #No hay disponibilidad
		    #Siguen como A PAGAR
		    push (@comprometidos, $registro);
		    push (@regApagar, $registro);
		  }
	      } else { #Ya esta liberada
		push (@regApagar, $registro); 
	       }
	  } else { #No esta dento del rango pedido
	      push (@regApagar, $registro); 
	    }
	}
	
	if ( $modobarr eq "-bfi" ){
	  $fechahasta = $fechalimite;
	  $valorMayor = &fechaEsMayor($fechaapagar);  
	  $valorMenor = &fechaEsMenor($fechaapagar);
	  if ( $valorMayor && $valorMenor && ($montoapagar > $montodesde) && ($montoapagar < $montohasta ) ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      if ( $apagar[1] eq "A PAGAR" ){
		if (&checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #print "registro comprometido\n";
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro);
		  &actualizarDisponibilidad($apagar[3]);    	
		} else { #No hay disponibilidad
		    #Siguen como A PAGAR
		    push (@comprometidos, $registro);
		    push (@regApagar, $registro);
		  }
	      } else { #Ya esta liberada
		  push (@regApagar, $registro); 
		}
	  } else { #No esta dento del rango pedido
	      push (@regApagar, $registro); 
	    }
	}
      }
      close ( ENT );
}

#################################
#		Generar nuevos archivos		
#################################

sub generarArchivoApagar{

  my($cantReg, $c);

  open ( ENT, ">$entrada" ) or die "No se pudo abrir el archivo $entrada : $!";

  $cantReg = @regApagar;
  #print "$cantReg\n";
  
  $c = 0;
  while ($c < $cantReg){
    print ENT "$regApagar[$c]\n";
    $c++;
  }

  close ( ENT );
}


sub generarArchivoPresu{

  my($cantReg, $c);

  open ( PRE, ">$presupuesto" ) or die "No se pudo abrir el archivo $presupuesto : $!";

  $cantReg = @regPresu;
  #print "$cantReg\n";
  
  $c = 0;
  while ($c < $cantReg){
    print PRE "$regPresu[$c]\n";
    $c++;
  }

  close ( PRE );
}

#################################
#		Fepago		
#################################
&estaCorriendoFepago;
&estaCorriendoFeprima;
&initAmbiente;
&leerPresupuesto;
#&mostrarPresupuesto;
&pedirParametros;

while ($modoejec ne "-q"){
  &inicializarLog;
  &determinarComprometidos;
  &mostrarRegistrosComprometidos;
  &mostrarPresupuesto;

  if ($modoejec eq "-ma"){ #Modo Actualizacion -> Debo persistir los cambios
    
    &backupArchivo($entrada);
    &backupArchivo($presupuesto);
    &mostrarRegistrosAgrabar;
    &generarArchivoApagar;
    &generarArchivoPresu;
  }
  &pedirParametros;
}
print "Fin del proceso FEPAGO\n";

# end Fepago
