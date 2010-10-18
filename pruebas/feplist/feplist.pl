#!/usr/bin/perl

# Variables y constantes inicializadas...
# -----------------------------------------------------------------------------
$GRUPO   = $ENV{'GRUPO'};

## Constantes "parametro" de la linea de comando...
## Tambien se utilizan en un hash de parametros...
$TYPE	 = 'type';			# Tipo de listado.
$TOPAY	 = '-fp';			# Listado de facturas "A PAGAR"
$FREED	 = '-ff';			# Listado de facturas "LIBERADA"
$BUDGET	 = '-b';			# Listado de presupuesto
$MONEY   = '-m';			# Parametro de importe
$DATE	 = '-d';			# Parametro de fecha
$OUTPUT  = '-o';			# Nombre del argumento de salida

## Utilizo un HASH "params" para la toma de parametros
$OUTALL  	= 'all';			# Salida por pantalla y archivo
$OUTDSP  	= 'display';		# Salida solo por pantalla
$OUTFLE  	= 'file';			# Salida solo por archivo
$OUTPATH 	= 'filePath';		# Hash a archivo de salida
$MONEYLOWER = 'moneyLower';		# Importe rango inferior
$MONEYUPPER = 'moneyUpper';		# Importe rango superior
$DATELOWER  = 'dateLower';		# Fecha rango inferior
$DATEUPPER  = 'dateUpper';		# Fecha rango superior

## Salida: Directorio y Nombres de Archivos
$OUTDIRD = "$GRUPO/facturas/listados";	# Salida por default.

## Entrada: Directorio
$BILLDIR	="$GRUPO/facturas";
$BILLACPDIR ="$GRUPO/aceptados";
$BUDGETDIR	="$GRUPO/prin";

## Entrada y Salida: Nombres de archivos
$TOPAYNAME	='apagar';
$FREEDNAME	='liberado';
$BUDGETNAME	='presu';


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
#: Main

%PARAMS = Params( );							# Obtiene y valida los param.
$TITLE  = Title( %PARAMS );						# Obtiene el titulo del list.
@DATA   = Data ( %PARAMS );						# Obtiene los datos procesa.
$FORMAT = PrintFormat( %PARAMS );				# Obtiene el formato de sali.
Print( \%PARAMS, \$TITLE, \@DATA, \$FORMAT );	# Imprime el listado.

#:~ Main
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Funciones Utilizadas en Main
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Obtiene los parametros ingresados desde la linea de comandos.
sub Params 
{
	# Declaracion de variables locales
	local( %params, $i, $argument, $value );
	local( $fileIndex, $allIndex, $file   );
	local( $lower, $upper, $index, $defName );

	# Verifico si se esta llamando al Help o que al menos tenga 1 param
	($#ARGV == -1 || $ARGV[0] eq '-h' || $ARGV[0] eq '--help') && Use( );

	# El primer parametro es fijo: $TOPAY, $FREED o $BUDGET
	($ARGV[0] ne $TOPAY) && ($ARGV[0] ne $FREED) && ($ARGV[0] ne $BUDGET) && (Use( "Invalid argument type ($ARGV[0])." ));

	# Cargo el tipo de listado
	$params{$TYPE}=$ARGV[0];

	# Cargo los valores por default del nombre de archivo de salida
	($ARGV[0] eq $TOPAY ) && ($defName=$TOPAYNAME );
	($ARGV[0] eq $FREED ) && ($defName=$FREEDNAME );
	($ARGV[0] eq $BUDGET) && ($defName=$BUDGETNAME);

	# Cargo el resto de los parametros (varian en posicion)
	for( $i = 1; $i <= $#ARGV; ++$i )
	{
		# Separo Argumento de Valor
		( $argument, $value ) = split( '=', $ARGV[$i] );

		# verifico el tipo de Argumento
		if ( $argument eq $OUTPUT )
		{
			# Parametro de Salida.
			# Separo el valor de opcion del path (opcional)
			( $option, $file ) = split( ':', $value );

			# Verifico que sea correcto el valor de la opcion
			($option ne $OUTALL) && ($option ne $OUTDSP) && ($option ne $OUTFLE) && (Use( "Invalid output value ($option)" ));

			# Cargo la opcion a la variable de parametros
			$params{$OUTPUT}=$option;

			# Para debug: se puede configurar el path del archivo
			if ( $option eq $OUTALL || $option eq $OUTFLE )
			{
				# Verifico si definio el PATH
				(defined( $file )) || ($file="$OUTDIRD/$defName.lst");

				# Cargo el PATH del archivo de salida
				$params{$OUTPATH}=$file;
			}
			else
			{
				# Verifico que no haga o=display:/home/XYX/a
				($file) && (Use( "Invalid output value ($file). Try option \"-o=all:$file\"." ));
			}
		}
		elsif ( $argument eq $MONEY )
		{
			# Listado Presupuesto no tiene esta opcion
			($params{$TYPE} eq $BUDGET) && (Use("Budget list only permits output option."));

			# Valido que este en el formato correcto
			(!($value =~ m/\[[1-9][0-9]*.[0-9]{2}:[1-9][0-9]*.[0-9]{2}\]/)) && Use( "Invalid format. Check money parameter ($value)." );

			# Separo los importes
			$index = index ( $value, ':', 0 );
			$lower = substr( $value, 1, $index - 1 );
			$upper = substr( $value, $index + 1, length( $value ) - $index - 2 );
			
			# Valido el rango
			($lower > $upper) && (Use( "Invalid range. Check money parameter ($value)." ));

			# Ingreso los parametros
			$params{$MONEY} = '1';
			$params{$MONEYLOWER} = $lower;
			$params{$MONEYUPPER} = $upper;
		}
		elsif ( $argument eq $DATE )
		{
			# Listado Presupuesto no tiene esta opcion
			($params{$TYPE} eq $BUDGET) && (Use("Budget list only permits output option."));

			# Valido que este en el formato correcto
			(!($value =~ m/\[[12][0-9]{3}[01][0-9][0-3][0-9]:[12][0-9]{3}[01][0-9][0-3][0-9]\]/)) && Use( "Invalid format. Check date parameter ($value)." );

			# Separo los importes
			$index = index ( $value, ':', 0 );
			$lower = substr( $value, 1, $index - 1 );
			$upper = substr( $value, $index + 1, length( $value ) - $index - 2 );
			
			# Valido el rango
			($lower > $upper) && (Use( "Invalid range. Check date parameter ($value)." ));

			# Valido que sea una fecha
			$value = substr( $lower, 4, 2 ) . '/' . substr( $lower, 6, 2 ) . '/' . substr( $lower, 0, 4 ) ;
			(`date --date "$value" 2>/dev/null`) || (Use( "Invalid lower date ($lower)."));

			$value = substr( $upper, 4, 2 ) . '/' . substr( $upper, 6, 2 ) . '/' . substr( $upper, 0, 4 ) ;
			(`date --date "$value" 2>/dev/null`) || (Use( "Invalid upper date ($upper)."));

			# Ingreso los parametros
			$params{$DATE} = '1';
			$params{$DATELOWER} = $lower;
			$params{$DATEUPPER} = $upper;
		}
		else
		{
			Use( "Invalid Argument ($argument)." );
		}
	}

	# Verifico que que si no cargo las opcionales
	# Los cargo a mano (Salida: display | archivo)
	(defined( $params{$OUTPUT})) || ($params{$OUTPUT}=$OUTDSP);

	return %params;
 }

# -----------------------------------------------------------------------------
# Obtiene los datos segun el tipo de listado
sub Data
{
	# Declaracion de variables locales
	local( %params, $type );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo
	%params = @_;
	$type   = $params{$TYPE};

	# Dirijo, segun el tipo, a la funcion
	# especifica para tomar los datos
	(($type eq $TOPAY || $type eq $FREED)) && ( return DataBill( %params ) );
	( $type eq $BUDGET ) && ( return DataBudget( %params ) );

	# No existe el "tipo": ERROR DE PROGRAMACION: "Params" lo tiene que detectar.
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params Function.' );
}


# -----------------------------------------------------------------------------
# Obtiene el tipo de formato de salida para la correcta tabulacion de la info.
sub PrintFormat 
{
	# Declaracion de variables locales...
	local( %params, $type );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo.
	%params = @_;
	$type   = $params{$TYPE};

	# Dirijo, segun el tipo, a la funcion
	# especifica para tomar los datos.
	(($type eq $TOPAY || $type eq $FREED)) && (return "%11s  %s  %4s  %8s  %10s  %10s  %12.2f  %12.2f  %12.2f  %12.2f");
	( $type eq $BUDGET ) && (return "%15s %12.2f %10s %-s");

	# No existe el "tipo": ERROR DE PROGRAMACION: "Params" lo tiene que detectar.
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params Function.' );
}

# -----------------------------------------------------------------------------
# Obtiene el titulo del listado.
sub Title 
{
	# Declaracion de variables locales
	local( %params, $type, $time );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo
	%params = @_;
	$type   = $params{$TYPE};
	
	# Obtengo la fecha..-
	$time=`date +"%H:%M %d-%m-%Y" 2>/dev/null`;
	chomp( $time );
	
	# Dirijo, segun el tipo, a la funcion especifica para tomar titulo
	($type eq $TOPAY ) && (return 'FACTURAS A PAGAR' . ' 'x78 . "$time\n" . '+'x110);
	($type eq $FREED ) && (return 'FACTURAS LIBERADAS' . ' 'x76 . "$time\n" . '+'x110 );
	($type eq $BUDGET) && (return 'PRESUPUESTO' . ' 'x38 . "$time\n" . '+'x65  );

	# No existe el "tipo": ERROR DE PROGRAMACION: "Params" lo tiene que detectar.
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params Function.' );
}

# -----------------------------------------------------------------------------
# Imprime el listado a donde corresponda.
sub Print
{
	# variables locales = parametros del Print
	local( %params, $title, @data, $format );
	local( @row, $toFile, $toScreen, $tmp, $type );

	# Obtengo por separado los argumentos
	$tmp    = (@_[0]); %params	= %$tmp;
	$tmp	= (@_[1]); $title	= $$tmp;
	$tmp 	= (@_[2]); @data 	= @$tmp;
	$tmp 	= (@_[3]); $format 	= $$tmp;

	# Verifico que tenga datos para mostrar
	(scalar(@data) == 0)  && (exit 0);

	# Obtengo el tipo de salida.
	$type=$params{$OUTPUT};

	# Verifico si debo imprimir en archivo
	$toFile 	= defined( $params{$OUTPATH} );
	$toScreen	= ($type eq $OUTDSP || $type eq $OUTALL) ? 1 : 0;

	# Abro el archivo correspondiente
	( $toFile ) && (( open( FILE, "+>> $params{$OUTPATH}" )) || FatalError( "IO: Couldn\'t open file \"$params{$OUTPATH}\"." ));

	# Imprimo el titulo del listado
	($toScreen) && ( print ( "$title\n" ) );
	( $toFile ) && ((print (FILE "$title\n")) || FatalError( "IO: Couldn\'t write to file \"$params{$OUTPATH}\"." ));

	# Imprimo el cuerpo del listado
	foreach $dat (@data)
	{
		@row = split( ';', $dat );
		$tmp = sprintf ( $format . "\n", @row );

		($toScreen) && ( printf ( "$tmp" ) );
		( $toFile ) && ((printf (FILE "$tmp" )) || FatalError( "IO: Couldn\'t write to file \"$params{$OUTPATH}\"." ));
	}

	# Dejo una linea vacia al final del archivo para que quede legible
	($toFile) && ((print (FILE '~'x80 . "\n" )) || FatalError( "IO: Couldn\'t write to file \"$params{$OUTPATH}\"." ));

	# Cierro el archivo
	( $toFile ) && ( close( FILE ) );
}


# -----------------------------------------------------------------------------
# Funciones del listado de presupuesto
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Obtiene los datos para el listado de presupuesto.
sub DataBudget 
{
	# Declaracion de variables locales.
	local( %params, $pathFile, @data, @tmp, @sorted );
	local( %ranges, %fileData, $row, $value, $range );

	# Obtengo por separado los argumentos.
	%params	= @_;

	# Armo el directorio y nombre donde esta el presupuesto.
	$pathFile = "$BUDGETDIR/$BUDGETNAME.txt";

	# Abro el archivo en solo lectura.
	(open( FILE, "< $pathFile" )) || (FatalError( "IO: Couldn\'t open \"$pathFile\"." ));

	# Seteo los rangos de valores.
	$ranges{'11'} = "<   1000";
	$ranges{'12'} = "1000 <<  10000";
	$ranges{'13'} = "10000 <<  50000";
	$ranges{'14'} = "50000 << 150000";
	$ranges{'15'} = "> 150000";

	# Por cada linea agregar a un @array con.
	while ( $row=<FILE> )
	{
		chomp( $row );
		@tmp = split( ';', $row );
		$fileData{$tmp[0]} = $row;
	}

	# Cierro el archivo.
	close( FILE );

	# Ordeno por los valores de rango.
	@sorted = keys( %fileData );
	@sorted = sort {$a<=>$b}( @sorted );

	# Paso los valores en limpo al valor de retorno.
	foreach $row ( @sorted )
	{
		# Obtengo la fila sin la Fuente.
		$value = $fileData{$row};
		@tmp   = split( ';', $value );

		# Obtengo el rango de la Fuente.
		$range = $ranges{$row};

		# Guardo la info correctamente.
		push( @data, sprintf "$range;$tmp[1];$tmp[2];$tmp[3]" );
	}

	return @data;
}

# -----------------------------------------------------------------------------
# Funciones para el listado de Facturas
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Obtiene los datos filtrados, ordenados y agrupados del listado de facturas.
sub DataBill
{	
	local( %params, @data );
	%params	= @_;

	@data = FilterBills( %params );
	@data = sort( @data );
	@data = DetailBills( @data );
	@data = CreateReport( @data );

	return @data;
}

# -----------------------------------------------------------------------------
# Obtiene de 'apagar.txt' los datos de las facturas filtrando segun corresponda
# Nota: genera un array en formato FECHA:CAE para su posterior ordenamiento.
sub FilterBills
{
	# Variables locales.
	local( %params, @data );
	local( $money, $mLo, $mUp );
	local( $date, $dLo, $dUp );
	local( @reg, @spl );
	local( $stat, $row, $tmp );

	%params = @_;

	# Cargo el filtro del estado... y resto de parametros.
	($params{$TYPE} eq $TOPAY) && ($stat='A PAGAR'  );
	($params{$TYPE} eq $FREED) && ($stat='LIBERADA' );
	(defined($params{$MONEY})) && ($money=1) && ($mLo=$params{$MONEYLOWER}) && ($mUp=$params{$MONEYUPPER});
	(defined($params{$DATE} )) && ($date=1 ) && ($dLo=$params{$DATELOWER} ) && ($dUp=$params{$DATEUPPER} );

	# Armo la ruta donde esta el archivo "apagar.txt"
	$tmp="$BILLDIR/$TOPAYNAME.txt";

	# Abro archivo
	(open( FILE, "< $tmp")) || (FatalError( "IO: Couldn\'t open \"$tmp\"." ));
	
	# Filtrado segun parametros
	while ( $row=<FILE> )
	{
		chomp( $row );
	
		# Separo el registro en los campos
		@reg=split( ';', $row );

		# Filtro el estado.
		($reg[1] ne $stat ) && (next);

		# Si esta el parametro "Money" filtro el monto...
		($money) && (($reg[3] < $mLo) || ($reg[3] > $mUp)) && (next);

		# Si esta el parametro "Date" filtro la fecha...
		@spl = split( '-', $reg[2] );
		$tmp = sprintf( "%s%s%s", @spl );
		($date) && (($tmp < $dLo) || ($tmp > $dUp)) && (next);

		# Este registro cumple con los filtrados.
		push( @data, sprintf( "%s:%s", $tmp, $reg[0] ) );
	}

	# Cierro los archivos.
	close( FILE );

	return @data;
}

# -----------------------------------------------------------------------------
# Obtiene los datos detallados de la factura.
sub DetailBills
{
	local( @data, @spl, $row, $tmp, $bill );

	# Por cada factura filtrada
	foreach $row (@_)
	{
		# Obtengo el nombre del archivo
		@spl=split( ':', $row );
		$tmp="$BILLACPDIR/$spl[1]";

		# Tomo los datos de la cabecera
		($bill=`head -1 "$tmp" 2>/dev/null`) || (FatalError( "IO: Couldn\'t open \"$tmp\"." ));

		# Agrego la factura a la coleccion de facturas
		push( @data, $bill );
	}

	return @data;
}

# -----------------------------------------------------------------------------
# Crea un array con las filas del reporte agrupando por fecha.
sub CreateReport
{
	# Variables locales
	local( @data, @spl, $tmp, $format, $bill );		#  
	local( $cYear, $cMonth, $cWeek, $cDay );		# Var. de control
	local( $rYear, $rMonth, $rWeek, $rDay );		# Var. del reg. actual
	local( %year , %month , %week , %day  );		# Contadores
	local( $taxed, $iva   , $trib , $tot  );		# Totales.

	# Formato para el agregado de los grupos
	$format="%s; ;;;;;%.2f;%.2f;%.2f;%.2f";

	# Configuro las variables del primer registro.
	if ( scalar(@_) > 0 )
	{
		$tmp	 = @_[0];
		chomp( $tmp );

		@spl 	 = split( ';', $tmp );
		$tmp 	 = $spl[4];

		# seteo de var. del reg. actual.
		$cYear 	 = substr( $tmp, 0, 4 );
		$cMonth  = substr( $tmp, 5, 2 );
		$cDay 	 = substr( $tmp, 8, 2 );
		$cWeek 	 = `date --date \"$cMonth/$cDay/$cYear\" +%U 2>/dev/null`;
		chomp( $w );
	}

	# Armado del listado...
	foreach $bill (@_)
	{
		# Tomo la fecha... y demas valores
		@spl = split( ';', $bill );
		$tmp = $spl[4];
		
		# Var. de control de fecha...
		$rYear 	 = substr( $tmp, 0, 4 );
		$rMonth	 = substr( $tmp, 5, 2 );
		$rDay 	 = substr( $tmp, 8, 2 );
		$rWeek 	 = `date --date \"$rMonth/$rDay/$rYear\" +%U 2>/dev/null`;
		chomp( $w );

		$taxed 	+= $spl[6];
		$iva	+= $spl[7];
		$trib	+= $spl[8];
		$tot	+= $spl[9];

		# Verifico si cambio el año
		if( $cYear != $rYear )
		{
			push( @data, sprintf( $format, "Sub. Day   "  , $day{'taxed'}  , $day{'iva'}  , $day{'tributed'}  , $day{'total'} ) );
			push( @data, sprintf( $format, "Sub. Week  " , $week{'taxed'} , $week{'iva'} , $week{'tributed'} , $week{'total'} ) );
			push( @data, sprintf( $format, "Sub. Month ", $month{'taxed'}, $month{'iva'}, $month{'tributed'}, $month{'total'} ) );
			push( @data, sprintf( $format, "Sub. Year  " , $year{'taxed'} , $year{'iva'} , $year{'tributed'} , $year{'total'} ) );
			push( @data, $bill );

			# Contadores a los valores del registro
			$day{'taxed'} 	 = $week{'taxed'} 	 = $month{'taxed'} 	  = $year{'taxed'}	  = $spl[6];
			$day{'iva'} 	 = $week{'iva'} 	 = $month{'iva'}	  = $year{'iva'}	  = $spl[7];
			$day{'tributed'} = $week{'tributed'} = $month{'tributed'} = $year{'tributed'} = $spl[8];
			$day{'total'} 	 = $week{'total'} 	 = $month{'total'}	  = $year{'total'} 	  = $spl[9];

			# Valores de control a los del registro...
			$cYear  = $rYear;
			$cMonth = $rMonth;
			$cWeek  = $rWeek;
			$cDay   = $rDay;

			next;
		}

		# Verifico si cambio el mes
		if ( $cMonth != $rMonth )
		{
			push( @data, sprintf( $format, "Sub. Day   "  , $day{'taxed'}  , $day{'iva'}  , $day{'tributed'}  , $day{'total'} ) );
			push( @data, sprintf( $format, "Sub. Week  " , $week{'taxed'} , $week{'iva'} , $week{'tributed'} , $week{'total'} ) );
			push( @data, sprintf( $format, "Sub. Month ", $month{'taxed'}, $month{'iva'}, $month{'tributed'}, $month{'total'} ) );
			push( @data, $bill );

			# Contadores a los valores del registro
			$day{'taxed'} 	 = $week{'taxed'}	 = $month{'taxed'}	  = $spl[6];
			$day{'iva'}		 = $week{'iva'}		 = $month{'iva'}	  = $spl[7];
			$day{'tributed'} = $week{'tributed'} = $month{'tributed'} = $spl[8];
			$day{'total'}	 = $week{'total'}	 = $month{'total'}	  = $spl[9];

			# Sigo contabilizando los subtotales...
			$year{'taxed'} 		+= $spl[6];
			$year{'iva'} 		+= $spl[7];
			$year{'tributed'} 	+= $spl[8];
			$year{'total'} 		+= $spl[9];

			# Valores de control a los del registro...
			$cMonth = $rMonth;
			$cWeek  = $rWeek;
			$cDay   = $rDay;

			next;
		}

		# verifico si cambio la semana
		if ( $cWeek != $rWeek )
		{
			push( @data, sprintf( $format, "Sub. Day   "  , $day{'taxed'}  , $day{'iva'}  , $day{'tributed'}  , $day{'total'} ) );
			push( @data, sprintf( $format, "Sub. Week  " , $week{'taxed'} , $week{'iva'} , $week{'tributed'} , $week{'total'} ) );
			push( @data, $bill );

			# Contadores a los valores del registro
			$day{'taxed'}	 = $week{'taxed'}	 = $spl[6];
			$day{'iva'}		 = $week{'iva'}		 = $spl[7];
			$day{'tributed'} = $week{'tributed'} = $spl[8];
			$day{'total'}	 = $week{'total'}	 = $spl[9];

			# Sigo contabilizando los subtotales...
			$month{'taxed'} 	+= $spl[6]; $year{'taxed'} 		+= $spl[6];
			$month{'iva'} 		+= $spl[7]; $year{'iva'} 		+= $spl[7];
			$month{'tributed'} 	+= $spl[8]; $year{'tributed'} 	+= $spl[8];
			$month{'total'} 	+= $spl[9]; $year{'total'} 		+= $spl[9];

			# Valores de control a los del registro...
			$cWeek  = $rWeek;
			$cDay   = $rDay;

			next;
		}

		# Verifico si cambio el dia
		if ( $cDay != $rDay )
		{
			push( @data, sprintf( $format, "Sub. Day   "  , $day{'taxed'}  , $day{'iva'}  , $day{'tributed'}  , $day{'total'} ) );
			push( @data, $bill );

			# Contadores a los valores del registro
			$day{'taxed'} 	 = $spl[6];
			$day{'iva'}		 = $spl[7];
			$day{'tributed'} = $spl[8];
			$day{'total'} 	 = $spl[9];

			# Sigo contabilizando los subtotales...
			$week{'taxed'} 		+= $spl[6]; $month{'taxed'} 	+= $spl[6]; $year{'taxed'} 		+= $spl[6];
			$week{'iva'} 		+= $spl[7]; $month{'iva'} 		+= $spl[7]; $year{'iva'} 		+= $spl[7];
			$week{'tributed'} 	+= $spl[8]; $month{'tributed'} 	+= $spl[8]; $year{'tributed'} 	+= $spl[8];
			$week{'total'} 		+= $spl[9]; $month{'total'} 	+= $spl[9]; $year{'total'} 		+= $spl[9];

			# Valores de control a los del registro...
			$cDay   = $rDay;

			next;
		}

		# No cambio nada... 
		push( @data, $bill );

		# Sigo contabilizando los subtotales...
		$day{'taxed'} 	 += $spl[6]; $week{'taxed'} 	+= $spl[6]; $month{'taxed'} 	+= $spl[6]; $year{'taxed'} 		+= $spl[6];
		$day{'iva'} 	 += $spl[7]; $week{'iva'} 		+= $spl[7]; $month{'iva'} 		+= $spl[7]; $year{'iva'} 		+= $spl[7];
		$day{'tributed'} += $spl[8]; $week{'tributed'} 	+= $spl[8]; $month{'tributed'} 	+= $spl[8]; $year{'tributed'} 	+= $spl[8];
		$day{'total'} 	 += $spl[9]; $week{'total'} 	+= $spl[9]; $month{'total'} 	+= $spl[9]; $year{'total'} 		+= $spl[9];
	}

	# El ultimo	registro... y Totales...
	push( @data, sprintf( $format, "Sub. Day   "  , $day{'taxed'}  , $day{'iva'}  , $day{'tributed'}  , $day{'total'} ) );
	push( @data, sprintf( $format, "Sub. Week  " , $week{'taxed'} , $week{'iva'} , $week{'tributed'} , $week{'total'} ) );
	push( @data, sprintf( $format, "Sub. Month ", $month{'taxed'}, $month{'iva'}, $month{'tributed'}, $month{'total'} ) );
	push( @data, sprintf( $format, "Sub. Year  " , $year{'taxed'} , $year{'iva'} , $year{'tributed'} , $year{'total'} ) );
	push( @data, sprintf( $format, "Total      " , $taxed, $iva, $trib , $tot ) );

	return @data;
}

# -----------------------------------------------------------------------------
# Funciones Varios....
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
sub Use 
{
	print "Use: @_\n";
	exit 0;
}

# -----------------------------------------------------------------------------
sub FatalError
{
	printf ( "Error: @_\n" );
	exit 3;
}

# -----------------------------------------------------------------------------
sub Debug 
{
	print ( "Debug: @_\n" );
	exit 2;
}

