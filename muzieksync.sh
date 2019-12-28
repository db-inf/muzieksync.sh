#!/bin/bash
:<<'_'
	Kopieert hele muziekbibliotheek naar een mp3-speler of usb-schijf 
		- flac wordt niet gekopieerd, maar omgezet naar mp3 (*.fl.mp3) zoals
		vastgelegd in _flac2mp3.cfg-scripts
	Zie sectie "syntax flac2mp3-script"
	
	GEBRUIK :
	$ bash muzieksync.sh brondirectory doeldirectory
	b.v. hele collectie synchroniseren :
		$ bash muzieksync.sh ~/muziek /media/mp3player
	b.v. een nieuwe cd in de muziekbibliotheek ook toevoegen aan de mp3-collectie :
		$ mkdir -p /media/mp3player/nieuwecd
		$ bash muzieksync.sh ~/muziek/nieuwecd /media/mp3player/nieuwecd
_
#####################
## TE DOEN
##
## EERST : eerst flac2mp3, dan rsync, zodat rsync de directory mod times terug gelijktrekt
## - flac 2 mp3 : array sorteren, zie onderaan
## - flacs van ./ORIG naar . (en links daarnaar in ~/muziek updaten)
##		$ find "$bron" -type d -iname ORIG -exec bash -c '  mv "$1"/* "${1/\/ORIG}"' _ {} \;
##		- ook in opkuis.sh steken (zie volgende)
##		$ find "$bron" -depth -type d -empty
##		$ find "$bron" -type d -empty -delete
## - opkuis doelen
##		- EN alle flacs verwijderen
##		- EN ~/Documents/c/fdupes-master/fdupes -rNMo arg -G "//\.mp3$|\.cue$|\.ogg$|\.jpg$|\.png$" bron doel
## na 1ste keer gelijktrekken
## - alle .fl.mp3 van bron sdata verwijderen
##
#####################
:<<'_'
	Syntax flac2mp3-script
	======================
	 - als de directory geen bestand "_flac2mp3.cfg" bevat, wordt een leeg bestand "_flac2mp3.cfg" aangemaakt en als script behandeld; zo kunnen we het script altijd opnemen in de checksum-controle
	 - als "_flac2mp3.cfg" begint met shebang "#!" (zie Voorbeeld 6), dan wordt het als shellscript uitgevoerd met deze opdracht :
			$ bash _flac2mp3.cfg "$doeldir" "$standaardlameopties"	 	
	 - elk ander bestand "_flac2mp3.cfg" is een soort script voor omzetting naar mp3, volgens onderstaande regels;
		- flacs worden samengevoegd en omgezet naar een mp3-bestand "verzamelnaam.fl.mp3", volgens het "_flac2mp3.cfg"-script
		- de uitvoering van elk "_flac2mp3.cfg"-script begint impliciet met de mapnaam als verzamelnaam
		- leeg bestand "_flac2mp3.cfg" : alle flacs van de directory worden in natuurlijke volgorde samengevoegd (dus naar 1 bestand "mapnaam.fl.mp3"), met de standaard lame-opties (zie instelling 'standaardlameopties=' in dit script)
		- niet-leeg bestand "_flac2mp3.cfg" : omzettingsscript
			- elke lijn bevat een bijzondere opdracht, of de naam vam een om te zetten flac-bestand
			- een bijzondere opdracht begint met '/' in kolom 0
				- de '/' is immers het enige tekstteken dat niet toegelaten is in een linux bestandsnaam
			- elke lijn "//lame-opties" geeft niet-standaard lame-opties voor lopende en volgende verzamelnamen
				- als lame-opties leeg (of spaties), dan terug de standaard lame-opties gebruiken voor lopende en volgende verzamelnamen
			- elke lijn "/doelnaam" stelt "doelnaam" in als de verzamelnaam voor de volgende lijn(en) "naam.flac"
				- evt. vorige verzameling wordt afgesloten en weggeschreven onder de vorige verzamelnaam
				- een lijn met enkel "/" stelt de verzamelnaam in op de lege string ""
			- elke lijn "naam.flac" met verzamelnaam "*" wordt direct omgezet naar "naam.fl.mp3"
			- alle andere lijnen "naam.flac" worden toegevoegd aan "verzamelnaam.fl.mp3"
				- als verzamelnaam de lege string "" is, wordt de naam van het eerste flac-bestand als verzamelnaam genomen
			- als bij het einde van het omzettingsscript nog geen enkele lijn "naam.flac" gevonden is, worden alle .flac bestanden van de directory omgezet volgens de dan geldende verzamelnaam en lame-opties
	- gebruikt b.v. dit commando om een omzettingsscript "_flac2mp3.cfg" te maken met de naam van alle .flac bestanden (goede uitgangsbasis om verzamelnamen en lameopties toe te voegen):
		$ ls -1 *.flac >> _flac2mp3.cfg

	Voorbeeld 1 : lege _flac2mp3.cfg om alle .flac te verzamelen onder mapnaam
		>>> _flac2mp3.cfg
		<<<
	Voorbeeld 2 : _flac2mp3.cfg om alle .flac te verzamelen onder mapnaam, met eigen lame-opties
		>>> _flac2mp3.cfg
			//lame opties
		<<<
	Voorbeeld 3 : _flac2mp3.cfg om alle .flac bestanden 1 voor 1 om te zetten onder eigen naam
		>>> _flac2mp3.cfg
			/*
		<<<
	Voorbeeld 4 : combi van vb. 2 en 3
		>>> _flac2mp3.cfg
			//lame opties
			/*
		<<<
	Voorbeeld 5 : _flac2mp3.cfg om genoemde .flac in groepjes om te zetten:
		- 1ste groepje onder expliciete naam
		- 2de groepje onder naam 1ste flac
		- 3de groepje 1 voor 1
		- lame opties evt. per groepje in te stellen
		>>> _flac2mp3.cfg
			//lame opties opus 1 als er geen andere volgen
			/opus 1
			opus 1 deel 1.flac
			opus 1 deel 2.flac
			//effectieve lame opties opus 1
			/
			opus 2.flac
			opus 2 deel 2.flac
			//lame opties opus 2 en 3
			/*
			opus 3.flac
			//lame opties opus 4
			opus 4.flac
		<<<

	Voorbeeld 6 : shellscript in _flac2mp3.cfg voor omzettingen op maat
		- b.v. split van 1 flac volgens cue-file :
		>>> _flac2mp3.cfg
			#!/bin/bash
			## script wordt aangeroepen door muzieksync.sh met 2 argumenten, als volgt :
			##	bash _flac2mp3.cfg "doeldirectory" "standaardlameopties"
			##
			## script om 1 flac (OPGELET *.flac moet geglobt worden naar 1 flac!) volgens 
			## een .FLAC.cue te splitsen naar stel mp3 bestanden.

			mkdir -p "$1"
			#	-p : verify or create full path
			shntool split -f *.FLAC.cue -t "%n %t" -O always -d "$1" -o "cust ext=fl.mp3 lame --quiet -m j -h -V 5 - %f" *.flac
			#	-O overwrite mode
			#	zie "_Xubuntu truuks en commandos.adoc" sectie "geluidsbestand splitsen volgens cue file"
		<<<
_

#testrun ? (heeft geen invloed op flac->mp3 omzetting, enkel op rsync van de rest)
testrsync=""	
#testrsync="-v -n --list-only "

## gebruik ${checksom}sum als checksum, sha1sum zou qua cpu-gebruik een beetje sneller zijn dan md5sum
## alternatieven md5, sha1, sha256, sha224, sha384, sha512
checksom=sha1

bron="$1"
doel="$2"
#bron=/media/sdata/muziek
#bron=/media/ramdisk/muziek
#niet echt nodig, wel proper: verwijder evt. eind-/
bron="${bron%/}"
doel="${doel%/}"

# Als dit wijzigt, moet eigenlijk elke omzetting opnieuw, maar dit script komt dat nooit te weten
# Kan geforceerd worden door checksums *.${checksom} te verwijderen
standaardlameopties="-m j -h -V 3"
##	LAME VBR kwaliteit (0-9), leidraad:
##	KWAL : GEM.	RANGE (Kbit/sec)
##	-V 0 : 245 	220-260 (this is VBR from 22 to 26 KB/s)
##	-V 1 : 225 	190-250 
##	-V 2 : 190 	170-210 
##	-V 3 : 175 	150-195 
##	-V 4 : 165 	140-185 (Lame's default)
##	-V 5 : 130 	120-150 
##	-V 6 : 115 	100-130 
##	-V 7 : 100 	 80-120 
##	-V 8 :  85 	 70-105 
##	-V 9 :  65 	 45- 85 
##maak pushd quiet
pushd () {
    command pushd "$@" > /dev/null
}
##maak popd quiet
popd () {
    command popd "$@" > /dev/null
}
#behandelt een reeks te joinen flacbestanden : schrijft alles in joinedflacs naar bestaande joinnaam of naar naam 1ste joinedflacs (als joinnaam="" of ="*")
function zetBestandOm {
	# echo -"$joinnaam".fl.mp3- "${joinedflacs[@]}"
	if [ ${#joinedflacs[@]} -gt 0 ]
	then
		if [ -z "$joinnaam" ] || [ "$joinnaam" == "*" ] # altijd ge-set, dus -z volstaat
		then ## neem naam eerste/enige van joinedflacs als uitvoer (voor joinnaam "*" wordt ftie. voor elke flac aangeroepen)
			uitvoer="${joinedflacs[0]::-5}"
		else
			uitvoer="$joinnaam"
		fi
		# zie "_Xubuntu truuks en commandos.adoc" sectie "flac geluidsbestanden achter elkaar plakken" :
		# join in natuurlijke sortering naar 1 bestand joinnaam.fl.mp3 (%f) zonder tijdelijk flac-bestand
		uitvoer="$doeldir"/"$uitvoer"
		if [ ${#joinedflacs[@]} -gt 1 ]
		then
			## te dikwijls error in pipe van joined flac naar custom command (ineens mp3 zonder tijdelijk flac-bestand)
			#printf '%s\n' "${joinedflacs[@]}" > /media/ramdisk/joinedflacs.lst
			#shntool join -F /media/ramdisk/joinedflacs.lst -a "$uitvoer" -n -o 'cust ext=fl.mp3 lame --quiet "$lameopt" - %f'
			#OF
			#shntool join "${joinedflacs[@]}" -a "$uitvoer" -n -o 'cust ext=fl.mp3 lame --quiet "$lameopt" - %f'
			
			# [@] om elk joinedflacs-element apart tussen "" te zetten
			shntool join -q "${joinedflacs[@]}" -a "/media/ramdisk/joinedflacs" -n -O always -o flac
			lame --quiet $lameopt "/media/ramdisk/joinedflacs.flac" "$uitvoer".fl.mp3
			rm "/media/ramdisk/joinedflacs.flac"
		else
			lame --quiet $lameopt "${joinedflacs[0]}" "$uitvoer".fl.mp3
		fi
		unset joinedflacs
		declare -A joinedflacs
	fi
}

#behandelt 1 subdirectory van bron met *.flac en conversiescript "_flac2mp3.cfg"
function zetDirectoryOm {
	
	## $1 : volledige brondirectory (subdirectory van $bron)
	subdir="${1:${#bron}}" # ":${#bron}" : vanaf offset = lengte bron
	subdir="${subdir#/}"   # verwijder evt. '/' voor- en achteraan
	subdir="${subdir%/}"
	doeldir="$doel/$subdir"
echo $subdir
	pushd "$1"
	# gebruik checksums op doel om te zien of er iets te doen valt:
	#	- vergelijk _flac.${checksom} van doel met bestanden op bron
	#	- vergelijk _flac2mp3.${checksom} van bron met bestanden op doel
	mkdir -p "$doeldir"
	if [ -f "$doeldir"/_flac.${checksom} ] && [ -f _flac2mp3.${checksom} ]
	then
		${checksom}sum --status -c "$doeldir"/_flac.${checksom} &&
		(
			# (command) : command in subshell, dus cd niet blijvend; exit code subshell toch in $?
			cd "$doeldir";
			${checksom}sum --status -c "$1"/_flac2mp3.${checksom}
		)
		# ${checksom}sum --status print OK noch NOK, geeft enkel exit code
		# && voert 2de commando niet uit als exit 1ste commando niet 0
		if [ $? == 0 ]
		then
			popd
			return
		fi
	fi
	
	## *.flac, *.fl.mp3 of _flac2mp3.cfg gewijzigd (of fl.mp3 niet meer leesbaar door bad sector), fl.mp3 opnieuw maken
	## oude .fl.mp3 in doeldir hernoemen naar .fl.mp3~ om evt. bad sectors niet zomaar terug vrij te geven (evt. ook move naar elders, maar niet trash)
	for flmp3 in "$doeldir"/*.fl.mp3
	do # alleen als $flmp3 bestaan, zou nog "...*..." kunnen zijn (zonder "shopt -s nullglob")
		[ -f "$flmp3" ] && mv "$flmp3" "$flmp3"~
	done

	# Als _flac2mp3.cfg niet bestaat (in bron $1), maak dan lege _flac2mp3.cfg: betekent join onder mapnaam.
	# Dit zorgt ook ALTIJD voor checksum _flac2mp3.cfg in _flac.${checksom} hierna, zodat wijziging daarvan ook gezien wordt
	if [ ! -f _flac2mp3.cfg ]
	then
		touch _flac2mp3.cfg
	fi

	lameopt="$standaardlameopties"
	# begin met mapnaam als verzamelnaam (zonder evt. moedermappen)
			#TODO evt. 1ste niveau directory na muziek/ toevoegen: (b.v. "muziek/Maurice Ravel 4x/Opus zoveel")
	joinnaam="${subdir##*/}"
	
	unset joinedflacs
	declare -A joinedflacs
	flacsgezien=N
	if [ -s _flac2mp3.cfg ] # -s : non-zero file
	then # interpreteer geformateerde opdrachten
		## "while read" leest config d.m.v. "< _flac2mp3.cfg" na "done"
		##	OPM: een break in zo'n loop stopt de omleiding van dat invoerbestand naar stdin
		##		 (dus zonder dat overschot nog terechtkomt in b.v. een volgende of andere omleiding)
		lijnnr=0
		while IFS= read -r lijn || [ -n "$lijn" ] 	# als laatste lijn geen \n heeft: reply-variabele wel gevuld, maar read sloot af met nonzero exit code dus eindigt while-loop
		# "IFS=" voorkomt trimmen van omringende en samenslagen van opeenvolgende witruimte door de read-opdracht
		do
			echo "_flac2mp3.cfg - " "$lijn"
			let lijnnr++
			if [[ $lijnnr == 1 && "${lijn:0:2}" == "#!" ]] # vorm "#!" ofte hash bang : script
			then ## _flac2mp3.cfg uitvoeren als omzettingsscript
				bash _flac2mp3.cfg "$doeldir" "$standaardlameopties"
				break;
			elif [ "${lijn:0:2}" == "//" ] # vorm "//lame opties"
			then
				lameopt="${lijn:2}"				
				if [ -z "$(echo $lameopt)" ] # "$(echo $var)" is "" als var alleen IFS-chars " \t\n" bevat
				then
					lameopt="$standaardlameopties"
				fi
			elif [ "${lijn:0:1}" == "/" ] # vorm "/joinnaam"
			then ## evt. joinedflacs uitschrijven onder vorige vezamelnaam
				zetBestandOm
				## zet nieuwe joinnaam
				joinnaam="${lijn:1}"
				## opkuisen van 2 speciale betekenissen "" en "*": evt. spaties verwijderen
				if [ -z "$(echo $joinnaam)" ] # "$(echo $var)" is "" als var alleen IFS-chars " \t\n" bevat
				then
					joinnaam=
				else
					if [ "$(echo $joinnaam)" == "*" ]
					then
						joinnaam="*"
					fi
				fi
			elif [ -z "$(echo $lijn)" ] ## alleen witruimte
			then
				continue
			else # vorm "bestand.flac" (extensie niet gecheckt)
				flacsgezien=Y
				joinedflacs[${#joinedflacs[@]}]="$lijn"
				if [ "$joinnaam" == "*" ]
				then # direct schrijven
					zetBestandOm
				fi
			fi
		done < _flac2mp3.cfg
		## laatste reeks
		zetBestandOm
		## als er nog niets geconverteerd is (b.v. _flac2mp3.cfg heeft alleen lameopties of instelling verzamelnaam),
		## dan alle flac van deze directory omzetten
		if [ "$flacsgezien" != "Y" ]
		then
			for lijn in *.[Ff][Ll][Aa][Cc]
			do
				joinedflacs[${#joinedflacs[@]}]="$lijn"
				if [ "$joinnaam" == "*" ]
				then # direct schrijven
					zetBestandOm
				fi
			done
			zetBestandOm
		fi
	else # _flac2mp3.cfg is leeg (evt. zelfs pas gemaakt) : alle *.flac van de directory samenvoegen
		for lijn in *.[Ff][Ll][Aa][Cc]
		do
			joinedflacs[${#joinedflacs[@]}]="$lijn"
		done
		zetBestandOm
	fi

	## maak checksums
	${checksom}sum *.[Ff][Ll][Aa][Cc] _flac2mp3.cfg > "$doeldir"/_flac.${checksom}
	## naar directory van voor "pushd $1", zodat we na "pushd doeldir" terug naar daar kunnen
	popd
		## bash Tilde Expansion : ... If the tilde-prefix  is  a `~-', the value of the shell variable OLDPWD, if it is set, is substituted.
	pushd "$doeldir"
	# overschrijft evt. op bron bestaande _flac2mp3.${checksom} van ander doel, maar dat moet toch ooit dezelfde mp3-s krijgen
	## OPM: eerst naar brondirectory $1 schrijven, want doel kan ntfs zijn en die
	## verknoeit permissions, dus willen we niet van ntfs naar ext4 kopieren
	${checksom}sum *.fl.mp3 > "$1"/_flac2mp3.${checksom}
	cp "$1"/_flac2mp3.${checksom} .
	#change back to prev. PWD
	popd
}

if [ ! -d "$doel" ]
then
	echo Doel "$doel" is geen directory
	exit -1
fi
if [ ! -w "$doel" ]
then
	echo Doel "$doel" is niet schrijfbaar
	exit -2
fi
## vervang relatief doelpad en '.' of '..' door absoluut pad, want we veranderen geregeld van directory
doel=$(realpath "$doel")
echo Lijst van bestandsnamen met verboden tekens in NTFS
## \/ is ook verboden in Windows, maar eveneens in Linux, komt dus niet voor
##	terwijl find er wel een waarschuwing (overbodig dus) voor toont
find "$bron" -iname "*[\?\<\>\|\\\:\"\*]*"
read -p "Enter om door te gaan ondanks bovenstaande lijst van ongeldige namen"

## sync behalve flac, mp3 gemaakt van flac (.fl.mp3), en ${checksom}-checksums die we hierna
## gaan gebruiken om te zien of we .fl.mp3 opnieuw moeten maken uit flac

rsync $testrsync --progress -ax --modify-window=2 -i --no-p --no-g --no-o --safe-links --delete --backup --backup-dir=_0_RSYNC_BACKUP --exclude={"*.flac","*.fl.mp3","*.${checksom}"} --exclude=/_0_RSYNC_BACKUP/ "$bron"/ "$doel"/
	# OPM : -c (altijd checksums vergelijken bij even grote files, tijdrovend) vervangen door
	#	 --modify-window=2 (vergelijk alleen bestandsgrootte en, op 2 seconden na, -tijd)
#############################################################
##OPGELET : --exclude={"*.flac","*.fl.mp3","*.${checksom}"}
## 		rekent op bash brace expansion; als er niet minstens
##		2 csv-strings tussen de {} staan, is er geen brace
##		expansion en blijven de {} gewoon staan
##
## 		DUS --exclude="*.flac" NOOIT --exclude={"*.flac"}
#
#############################################################

# rsync $testrsync --progress -aci --safe-links --delete --backup --backup-dir=_0_RSYNC_BACKUP --exclude={"*.flac","*.${checksom}"} --exclude=/_0_RSYNC_BACKUP/ "$bron"/ "$doel"/

	#	/ : zeker achteraan van bron/ en doel/
	#	--backup ... suffix : t.b.v. schijf met bad clusters: onleesbare bestanden behouden, zodat die bad clusters voorlopig bezet blijven, maar opzij zetten
# enkele rsync opties
#	-v : verbose
#	-n, --dummy : geen wijzigingen aanbrengen
#	--list-only             list the files instead of copying them
#	-a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
#		-r, --recursive             recurse into directories
#		-l : copy symlinks as symlinks
#		-p, --perms                 preserve permissions
#		-t, --times                 preserve modification times
#		-g, --group                 preserve group
#		-o, --owner                 preserve owner (super-user only)
#		-D                          same as --devices --specials
#			--specials              preserve special files
#			--devices               preserve device files (super-user only)
#		--no-OPTION                 turn off an implied OPTION (e.g. --no-D)
#			--no-p en --no-g omdat NTFS (de USB-schijven) dat niet kunnen syncen met ext4
#			--no-t-enkel-voor-directories zou welkom zijn, want directories wijzigen door flac->mp3, maar
#				bij de eerstvolgende muzieksync.sh wordt de directory mod time gelukkig wel voorgoed
#				gelijk getrokken.
#	-i, --itemize-changes : output a change-summary for all updates
#	-c, --checksum              skip based on checksum, not mod-time & size
#	--safe-links (ignore symlinks that point outside the tree)
#	--delete                delete extraneous files from dest dirs
#	-b, --backup : With this option, preexisting destination files are renamed as each file is transferred or deleted.
#	--backup-dir=DIR : In combination with the --backup option, this tells rsync to store all backups in the specified directory on the receiving side. If you specify a relative path, the backup directory will be relative to the destination directory.
#	[--suffix=SUFFIX] : override the default backup suffix used with the --backup (-b) option. The default suffix is a ~ if no --backup-dir was specified, otherwise it is an empty string.
#	--exclude=/BAK/	: onze backup-directory "BAK" in root van transfertree niet mee overzetten ($bron/BAK) of deleten ($doel/BAK)

## Nu voor elk flac-bestand zien of de directory daarvan al behandeld is ("in array flacdirs staat"), en indien niet, dan in de array flacdirs zetten en de functie flac2mp3 ermee aanroepen
## find -exec deelt gevonden lijst in handelbare stukken; doe liever find -printf met pipe van de hele lijst naar group command
## group command moet tussen " { " en " } " (met spaties!) en afgesloten door ';' of newline
# pipe output van printf naar command group (zonder gaat het niet)
# 	-printf "%h" print directory van gevonden files (ZONDER eind-/)
find "$bron" -type f -iname "*.flac" -printf "%h\n" | 
{
###TEDOEN ### SORTEER FLACDIRECTORIES (gebruikt here-string)
#############3 zie https://stackoverflow.com/questions/7442417/how-to-sort-an-array-in-bash
##	IFS=$'\n' array=($(sort <<<"${array[*]}"))
##	unset IFS
#############
	##	OPM: elke kant van een pipe 'find ... | while ...' loopt in een subshell; veranderingen aan
	##	variables zijn daar buiten NIET zichtbaar.
	##	Oplossing: 'find ... | { while ...; opdracht; }'  (MET spaties " { " en " } ", en ook na laatste commando ; of \n)
	declare -A flacdirs
	## "_liedjes apart" evt. uitsluiten door al direct in de array te zetten:
		# flacdirs["${bron}"/"_liedjes apart"]=
	while IFS= read -r flacdir
		 # read -r : -r prevents backslash interpretation; without this option, any unescaped backslashes
		 # in the input will be discarded. You should almost always use the -r option with read.
		 # "IFS=" voorkomt trimmen van omringende en samenslagen van opeenvolgende witruimte door read
	do	 # "var[index]=" is voldoende om een index in var te definieren
		flacdirs["$flacdir"]=
	done
	# voor alle gedefinieerde indexen (zijnde directories met .flac) :
	for flacdir in "${!flacdirs[@]}"
	do
		zetDirectoryOm "$flacdir"
	done
}

