#!/usr/bin/perl

$TRUE = 1;
$FALSE = 0;

#Clave: FUENTE => Valor: monto disponible
%fuentes;
%fuenteModificada;
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
$backupEntrada = "$ENV{'grupo'}/facturas/old/";
$backupPresupuesto = "$ENV{'grupo'}/prin/old/";
#$entrada = "apagar.txt";
#$presupuesto = "presu.txt";
#Registros a incluir en el nuevo apagar.txt
@regApagar;
#Registros a incluir en el nuevo presu.txt
@regPresu;


sub Bash
{
	$value=`bash -c "@_ 2>/dev/null"`;
	if ( $? != 0 )
	{
		print "No se puede ejecutar \"@_\".\n";
		exit 1;
	}

	chomp( $value );
	return $value;
}

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
		my( @args );

		print 'No se ha inicializado el ambiente. Debe ejecutarse el comando fepini.sh previamente'. "\n";
		$text="No se ha inicializado el ambiente";
		chop($text);
		Bash( "./glog.sh fepago ERROR \"$text\"" );

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
	$fuenteModificada{$campos[0]} = $campos[3];
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
	#print	$campos[0]." - ".$campos[1]." - ".$fuenteModificada{$campos[0]}."\n";
	
	#Actualizo fecha
	if ($campos[1] ne $fuentes{$campos[0]}){
	  $campos[2] = $ENV{"FECHA_HOY"};
	}

	#se guardan indistintamente para -ms o -ma, solo para -ma se persisten
	$nuevaLinea = $campos[0].";".$fuentes{$campos[0]}.";".$campos[2].";".$fuenteModificada{$campos[0]}."\n";
	chomp($nuevaLinea);
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
      } elsif ( $monto >= 10000 && $monto<50000 ){
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
    #print "Monto a pagar $_[0]\n";
    $fuente= getFuente($monto);
    #print "Fuente disponible $fuentes{$fuente}\n";
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
    $fuente= getFuente($monto);
    $fuentes{$fuente} -= $monto;
    $fuenteModificada{$fuente} = $ENV{'USER'};
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
       @num=`ls "$_[1]" | sed \'s/.*\\.\\(.*\\)\$/\\1/g\' | sort -n`;
       $ultima_version= $num[-1];
       $ultima_version++;
       @rutas=split('/',$_[0]);
       $archivo= $rutas[-1];
        
       $cmd = "cp \"$_[0]\" \"$_[1]$archivo\.$ultima_version\"";
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
	  print "Debe ingresar un modo de ejecucion valido (-ms,-ma o -q para terminar)\n";
	  #exit 0;
	} 

	if (($param[1] eq "-bf") or ($param[1] eq "-bi") or ($param[1] eq "-bfi")){
	  $modobarr = $param[1];
	  if ($modobarr eq "-bf"){
	    #tomo 2 parametros
	    validarFecha ($fechadesde = $param[2]);
	    validarFecha ($fechahasta = $param[3]);
	  }
	  if ($modobarr eq "-bi"){
	    #tomo 2 parametros
	    validarMonto ($montodesde = $param[2]);
	    validarMonto ($montohasta = $param[3]);
		}
	  if ($modobarr eq "-bfi"){
	    #tomo 3 parametros
	    validarFecha ($fechadesde = $param[2]);
	    validarFecha ($montodesde = $param[3]);
	    validarMonto ($montohasta = $param[4]);
	  }
	}
	elsif ( $param[0] ne "-q" ){
	  print "Debe ingresar un modo de barrido valido (-bf,-bi o -bfi)\n";
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
		Bash( "./glog.sh fepago ERROR \"Formato de fecha ingresada invalido: $fecha\"" );
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
		Bash( "./glog.sh fepago ERROR \"Monto ingresado negativo: $monto\"" );

		exit 1;
	}
	if ($monto=~ /^[0-9]*\.[0-9][0-9]$/){
		return;
	}

	print "Formato monto no valido: $monto\n";
	print "Formato monto valido: numero.2decimales (ej. 54.00)\n";
	Bash( "./glog.sh fepago ERROR \"Formato monto ingresado invalido: $monto\"" );

	exit 1;	
}

#################################
#	Inicializa el log	
#################################

sub inicializarLog{
	my(@args);
	$textIni="Inicio de fepago $cadena";
	chomp($textIni);
	Bash( "./glog.sh fepago ERROR \"$textIni\"" );

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

      #my($r);
      #$r=0;

      #Vacio los arreglos
      @comprometidos = ();
      @regApagar = ();
      @regPresu = ();

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

	#print "modo barrido = $modobarr\n";

	if ( $modobarr eq "-bi" ){
	  if ( ($montoapagar > $montodesde) && ($montoapagar < $montohasta ) ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      #print "Estado $apagar[1]\n";
	      if ( $apagar[1] eq "A PAGAR" ){
		#print "Monto $apagar[3]\n";
		if (checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #print "registro comprometido\n";
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  #print "Estado $apagar[1]\n";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro);
		  #if ($modoejec eq "-ma"){
		  #`echo $registro > "apagar2.txt"`;
		  #}
		  actualizarDisponibilidad($apagar[3]);    	
		} else { #No hay disponibilidad
		    #Siguen como A PAGAR
		    #$r++;
		    #print "r = $r\n";
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
	  $valorMayor = fechaEsMayor($fechaapagar);  
	  $valorMenor = fechaEsMenor($fechaapagar);  
	  if ( $valorMayor && $valorMenor ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      if ( $apagar[1] eq "A PAGAR" ){
		if (checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro); 
		  actualizarDisponibilidad($apagar[3]);    	
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
	  $valorMayor = fechaEsMayor($fechaapagar);  
	  $valorMenor = fechaEsMenor($fechaapagar);
	  if ( $valorMayor && $valorMenor && ($montoapagar > $montodesde) && ($montoapagar < $montohasta ) ){
	      #Esta en el rango pedido, me fijo si esta comprometido
	      if ( $apagar[1] eq "A PAGAR" ){
		if (checkDisponibilidad($apagar[3])){ #Hay disponibilidad
		  #print "registro comprometido\n";
		  #Tengo que setear como LIBERADA
		  $apagar[1] = "LIBERADA";
		  $registro = join(";",@apagar);  
		  push (@comprometidos, $registro);
		  push (@regApagar, $registro);
		  actualizarDisponibilidad($apagar[3]);    	
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
estaCorriendoFepago;
estaCorriendoFeprima;
initAmbiente;
leerPresupuesto;
pedirParametros;

while ($modoejec ne "-q"){
  inicializarLog;
  determinarComprometidos;
  mostrarRegistrosComprometidos;
  mostrarPresupuesto;

  if ($modoejec eq "-ma"){ #Modo Actualizacion -> Debo persistir los cambios
    
    backupArchivo($entrada,$backupEntrada);
    backupArchivo($presupuesto,$backupPresupuesto);
    generarArchivoApagar;
    generarArchivoPresu;
  }
  pedirParametros;
}
print "Fin del proceso FEPAGO\n";

# end Fepago
