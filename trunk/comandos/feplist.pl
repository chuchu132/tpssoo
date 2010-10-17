#!/usr/bin/perl

#
#
# Comentario respecto al script, lo que hace, suposiciones...
#
#


# Variables y constantes inicializadas...
# -----------------------------------------------------------------------------
$GRUPO   = $ENV{'GRUPO'};

$TYPE	 = 'type';
$INPUT 	 = '-i';
$TOPAY	 = '-fp';
$FREED	 = '-ff';
$BUDGET	 = '-b';
$OUTPUT  = '-o';			# Nombre del argumento de salida.
$OUTALL  = 'all';		# Salida por pantalla y archivo.
$OUTDSP  = 'display';	# Salida solo por pantalla.
$OUTFLE  = 'file';		# Salida solo por archivo.
$OUTPATH = 'filePath';		# Nombre del ...

## Salida: Directorio y Nombres de Archivos...
$OUTDIRD = "$GRUPO/facturas/listados";	# Salida por dafult.

## Entrada: Directorio ...
$BILLDIR	="$GRUPO/facturas";
$BUDGETDIR	="$GRUPO/prin";

## Entrada y Salida: Nombres de archivos...
$TOPAYNAME	='apagar';
$FREEDNAME	='liberado';
$BUDGETNAME	='presu';


# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
#: Main

%PARAMS = Params( );
$TITLE  = Title( %PARAMS );
@DATA   = Data ( %PARAMS );
$FORMAT = PrintFormat( %PARAMS );
Print( \%PARAMS, \$TITLE, \@DATA, \$FORMAT );


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
	# Declaracion de variables locales...
	local( %params, $i, $argument, $value );
	local( $fileIndex, $allIndex, $file   );
	local( $defName, $defDir );

	# Verifico si se esta llamando al Help o que al menos tenga 1 param...
	( $#ARGV == -1 || $ARGV[0] eq '-h' || $ARGV[0] eq '--help' ) && Useage( "Argument Type" );

	# El primer parametro es fijo: $TOPAY, $FREED o $BUDGET ...
	($ARGV[0] ne $TOPAY) && ($ARGV[0] ne $FREED) && ($ARGV[0] ne $BUDGET) && (Useage( "Argument Type" ));

	# Cargo el tipo de listado...
	$params{$TYPE}=$ARGV[0];

	# Cargo los valores por default de Directorios y Nombres de archivos...
	($ARGV[0] eq $TOPAY ) && ($defName=$TOPAYNAME ) && ($defDir=$BILLDIR );
	($ARGV[0] eq $FREED ) && ($defName=$FREEDNAME ) && ($defDir=$BILLDIR );
	($ARGV[0] eq $BUDGET) && ($defName=$BUDGETNAME) && ($defDir=$BUDGETDIR);

	# Cargo el resto de los parametros (varian en posicion)...
	for( $i = 1; $i <= $#ARGV; ++$i )
	{
		# Separo Argumento de Valor...
		( $argument, $value ) = split( '=', $ARGV[$i] );

		# verifico el tipo de Argumento...
		if ( $argument eq $OUTPUT )
		{
			# Separo el valor de opcion del path (opcional)...
			( $option, $file ) = split( ':', $value );

			# Verifico que sea correcto el valor de la opcion...
			($option ne $OUTALL) && ($option ne $OUTDSP) && ($option ne $OUTFLE ) && (Useage( "Output" ));

			# Cargo la opcion a la variable de parametros...
			$params{$OUTPUT}=$option;

			# Para debug: se puede configurar el path del archivo...
			if ( $option eq $OUTALL || $option eq $OUTFLE )
			{
				# Verifico si definio el PATH...
				(! defined( $file )) && ($file="$OUTDIRD/$defName.lst");

				# Cargo el PATH del archivo de salida...
				$params{$OUTPATH}=$file;
			}
			else
			{
				# Verifico que no haga cosas como -o=display:/home/XYX/a
				($file) && (Useage( "Output: Display con archivo." ));
			}
		}
		elsif ( $argument eq $INPUT )
		{
			# Parametro para debuggear...
			$params{$INPUT}=$value;
		}
		else
		{
			#####################################################
			# ACA VA EL RESTO DE LOS PARAMETROS
			# QUE SON PARA EL LISTADO DE FACTURAS ...
			####################################################

			Debug( "Dinamic Argument" );
		}
	}

	# Verifico que que si no cargo los opcionales...
	# Los cargo a mano (Salida: display | archivo)...
	(!defined( $params{$OUTPUT})) && ($params{$OUTPUT}=$OUTDSP);
	(!defined( $params{$INPUT} )) && ($params{$INPUT}=$defDir );

	return %params;
 }

# -----------------------------------------------------------------------------
# Obtiene los datos (filtrado, ordenado y agrupado) segun el tipo de listado...
sub Data
{
	# Declaracion de variables locales...
	local( %params, $type );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo...
	%params = @_;
	$type   = $params{$TYPE};

	# Dirijo, segun el tipo, a la funcion
	# especifica para tomar los datos...
	(($type eq $TOPAY || $type eq $FREED)) && (return DataBill( %params ));
	( $type eq $BUDGET ) && (return DataBudget( %params ));

	# No existe el "tipo"...
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params.' );
}


# -----------------------------------------------------------------------------
# Obtiene el tipo de formato de salida para la correcta tabulacion de la info.
sub PrintFormat 
{
	# Declaracion de variables locales...
	local( %params, $type );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo...
	%params = @_;
	$type   = $params{$TYPE};

	# Dirijo, segun el tipo, a la funcion
	# especifica para tomar los datos...
	(($type eq $TOPAY || $type eq $FREED)) && (return "");
	( $type eq $BUDGET ) && (return "%2s %12.2f %10s %-s");

	# No existe el "tipo"...
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params.' );
}

# -----------------------------------------------------------------------------
# Obtiene el tipo de formato de salida para
# la correcta tabulacion de la info.
sub Title 
{
	# Declaracion de variables locales...
	local( %params, $type );

	# Paso los Argumentos a Variables para que
	# este explicito el uso del mismo...
	%params = @_;
	$type   = $params{$TYPE};

	# Dirijo, segun el tipo, a la funcion
	# especifica para tomar los datos...
	($type eq $TOPAY ) && (return '-'x10 . ' FACTURAS A PAGAR ' . '-'x10);
	($type eq $FREED ) && (return '-'x10 . ' FACTURAS LIBERADAS ' . '-'x10);
	($type eq $BUDGET) && (return '-'x15 . ' PRESUPUESTO ' . '-'x15);

	# No existe el "tipo"...
	Debug ( 'Invalid Type: It shouldn\'t reach this point. Check Params.' );
}

# -----------------------------------------------------------------------------
# Imprime el listado a donde corresponda
sub Print
{
	# variables locales = parametros del Print...
	local( %params, $title, @data, $format );
	local( @row, $toFile, $toScreen, $tmp, $type );

	# Obtengo por separado los argumentos...
	$tmp    = (@_[0]); %params	= %$tmp;
	$tmp	= (@_[1]); $title	= $$tmp;
	$tmp 	= (@_[2]); @data 	= @$tmp;
	$tmp 	= (@_[3]); $format 	= $$tmp;

	# Obtengo el tipo de salida...
	$type=$params{$OUTPUT};

	# Verifico si debo imprimir en archivo
	$toFile 	= defined( $params{$OUTPATH} );
	$toScreen	= ($type eq $OUTDSP || $type eq $OUTALL) ? 1 : 0;

	# Abro el archivo correspondiente...
	( $toFile ) && (( open( FILE, ">$params{$OUTPATH}" )) || FatalError( "IO: Open file \"$params{$OUTPATH}\"." ));

	# Imprimo el titulo del listado...
	($toScreen) && ( print ( "$title\n" ) );
	( $toFile ) && ((print (FILE "$title\n")) || FatalError( "IO: Write to file." ));

	# Imprimo el cuerpo del listado...
	foreach $dat (@data)
	{
		@row = split( ';', $dat );
		$tmp = sprintf ( $format . "\n", @row );

		($toScreen) && ( printf ( "$tmp" ) );
		( $toFile ) && ((printf (FILE "$tmp" )) || FatalError( "IO: Write to file." ));
	}

	# Cierro el archivo...
	( $toFile ) && ( close( FILE ) );
}

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Funciones varios.....

# -----------------------------------------------------------------------------
sub DataBill
{	
	return ( "cae1", "cae2"  );
}


# -----------------------------------------------------------------------------
sub DataBudget 
{
	# Declaracion de variables locales...
	local( %params, $pathFile, @data, $row );

	# Obtengo por separado los argumentos...
	%params	= @_;

	# Armo el directorio y nombre donde esta el presupuesto.
	$pathFile = "$params{$INPUT}/$BUDGETNAME.txt";

	# Abro el archivo...
	(open( FILE, "<$pathFile" )) || (FatalError( "IO: Unaviable to open \"$pathFile\"" ));

	# Por cada linea agregar a un @array con...
	while ( $row=<FILE> )
	{
		chomp( $row );
		@data = (@data, $row);
	}

	# Cierro el archivo...
	close( FILE );

	# Devuelvo los datos...
	return @data;
}

# -----------------------------------------------------------------------------
sub Useage 
{
	print "Useage: @_\n";
	exit 0;
}

# -----------------------------------------------------------------------------
sub Debug 
{
	print ( "DEBUG: @_\n" );
	exit 2;
}
	
# -----------------------------------------------------------------------------
sub FatalError
{
	printf ( "Error: @_\n" );
	exit 3;
}

