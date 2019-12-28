# muzieksync.sh
Synchroniseer een flac+mp3 verzameling naar een mp3 kopie

## korte beschrijving
`muzieksync.sh` is een bash script om een directory met een muziekverzameling in gemengd .flac- en .mp3-formaat, met subdirectories, te synchroniseren met een doel-directory in alleen .mp3-formaat.

### andere dan .flac bestanden
Alle subdirectories en bestanden uit de muziekverzameling die gewijzigd zijn, of die nog niet in de doeldirectory voorkomen, worden door `muzieksync.sh` 1-op-1 gekopiëerd, behalve .flac bestanden, die een eigen behandeling krijgen.

### .flac bestanden
.flac-bestanden worden met lame omgezet naar .mp3-bestanden volgens de standaardregels van `muzieksync.sh`, die echter per directory en per .flac bestand kunnen gewijzigd worden.

Van de standaard afwijkende regels kunnen per directory bewaard worden in een eenvoudig omzettingsscript. In te stellen regels zijn de lame-opties voor de omzetting naar .mp3, en het aaneen schakelen van opeenvolgende .flac bestanden tot 1 .mp3 bestand, om ze zonder hoorbare overgang of pauze af te spelen. De omzettingsscripts zijn gedocumenteerd in `muzieksync.sh`, met voorbeelden.

Omzettingsscripts, .flac-bestanden en resulterende .mp3-bestanden worden gewaarmerkt met een checksum in een apart bestand, dat aan `muzieksync.sh` toelaat om te synchroniseren wijzigingen in de muziekverzameling te ontdekken.

## Afhankelijkheden:

 * bash
 * lame
 * shntool
 * rsync
 * sha1sum
 * de standaard linux opdrachten
