*eject
***INCLUDE LJS01PT1 .
* Datendefinitionen für die allgemeine Strukturpflege -
* Schnittstellen-Parameter

*******************************************************************
*        Konstanten                                               *
*******************************************************************

* allg. Konstanten - Lesen ---------------------------------------*

* Ausprägungen der Knotenart der Strukturzuordnungen
CONSTANTS:
      CON_POST_LAND     LIKE RJS0102-KNOTENART1 VALUE '01',
      CON_POST_ORT      LIKE RJS0102-KNOTENART1 VALUE '02',
      CON_POST_PLZ      LIKE RJS0102-KNOTENART1 VALUE '03',
      CON_POST_STRASSE  LIKE RJS0102-KNOTENART1 VALUE '04',
      CON_POST_POSTFACH LIKE RJS0102-KNOTENART1 VALUE '05',
*     Alle postalischen Einheiten mit if... cp '0+'.
      CON_POST_TYP      LIKE RJS0102-KNOTENART1 VALUE '0+',  "<===== !!!
      CON_GEOEINH       LIKE RJS0102-KNOTENART1 VALUE '21',
      CON_POSTEINH      LIKE RJS0102-KNOTENART1 VALUE '22',
      CON_AUFORGEINH    LIKE RJS0102-KNOTENART1 VALUE '23',
      CON_BEZIRK        LIKE RJS0102-KNOTENART1 VALUE '24',
      CON_LIEFBAR       LIKE RJS0102-KNOTENART1 VALUE '25',
      CON_ROUTE         LIKE RJS0102-KNOTENART1 VALUE '26',
      CON_ABLADESTELLE  LIKE RJS0102-KNOTENART1 VALUE '27',
      CON_TAGESROUTE    LIKE RJS0102-KNOTENART1 VALUE '28',
      CON_ABLDRGL       LIKE RJS0102-KNOTENART1 VALUE '29',
      CON_ROUPVA        LIKE RJS0102-KNOTENART1 VALUE '30'.

* Zugriffspfade
CONSTANTS:
      CON_PFAD_ABLDRGL           LIKE   TJS15-ZUGRIFFPF  VALUE '0002',
      CON_PFAD_ABLDBAR           LIKE   TJS15-ZUGRIFFPF  VALUE '0003',
      CON_PFAD_LIEFBAR           LIKE   TJS15-ZUGRIFFPF  VALUE '0004',
      CON_PFAD_BEZGEOPOS         LIKE   TJS15-ZUGRIFFPF  VALUE '0008',
      CON_PFAD_AUFGEOPOS         LIKE   TJS15-ZUGRIFFPF  VALUE '0009',
      CON_PFAD_ROUBEA            LIKE   TJS15-ZUGRIFFPF  VALUE '0010',
      CON_PFAD_TROBEA            LIKE   TJS15-ZUGRIFFPF  VALUE '0011',
      " Pfad der die jeweils für einen Tag gültig Route liefert
      CON_PFAD_AROBEA            LIKE   TJS15-ZUGRIFFPF  VALUE '0012',
      CON_PFAD_ROUPVA            LIKE   TJS15-ZUGRIFFPF  VALUE '0013'.


* Kennzeichen für Ende des Zugriffspfades.
CONSTANTS:
      CON_EOF_ZUGRIFFSPFAD       LIKE   TJS15-ZUORDTYP   VALUE 'XX'.

* Ausprägungen des Zuordnungstyps
CONSTANTS:
      CON_GEOHIE            LIKE RJS0102-ZUORDTYP    VALUE 'GH',
      CON_GEOPST            LIKE RJS0102-ZUORDTYP    VALUE 'PG',
      CON_POSTHIE           LIKE RJS0102-ZUORDTYP    VALUE 'PH',
      CON_GEOAUFBAUORG      LIKE RJS0102-ZUORDTYP    VALUE 'GA',
      CON_GEOBEZIRK         LIKE RJS0102-ZUORDTYP    VALUE 'GB',
      CON_BEZIRKBEZIRK      LIKE RJS0102-ZUORDTYP    VALUE 'BB',
      CON_AUFBAUORGHIE      LIKE RJS0102-ZUORDTYP    VALUE 'AH',
      CON_LIEFERBARKEIT     LIKE RJS0102-ZUORDTYP    VALUE 'LA',
      CON_ABLADBARKEIT      LIKE RJS0102-ZUORDTYP    VALUE 'AB',
      CON_ABLADEREGELN      LIKE RJS0102-ZUORDTYP    VALUE 'AR',
      CON_ROUHIE            LIKE RJS0102-ZUORDTYP    VALUE 'RH',
      CON_ROUTEBEABST       LIKE RJS0102-ZUORDTYP    VALUE 'RB',
      CON_ROUTEPVA          LIKE RJS0102-ZUORDTYP    VALUE 'RP'.

* Ausprägungen der Strukturleseart
*     von Knoten auflösen
CONSTANTS:
      CON_KNOTEN       LIKE RJS0101-STRULESART VALUE 'K',
*     über akt.änd.Ändr.Nr
      CON_AENDNRAKT    LIKE RJS0101-STRULESART VALUE 'A',
*     über akt.ini.Ändr.Nr
      CON_AENDNRINIT   LIKE RJS0101-STRULESART VALUE 'I',
*     über Änderungsnummer mit der aus einer Zuordnung umgehängt wurde
      CON_AENDNRVON    LIKE RJS0101-STRULESART VALUE 'V',
*     über Änderungsnummer mit der in eine Zuordnung umgehängt wurde
      CON_AENDNRNACH   LIKE RJS0101-STRULESART VALUE 'N',
*     pauschal über Änderungsnummer des Ab- oder Bis-Datums
      CON_AENDNRPAUSCH LIKE RJS0101-STRULESART VALUE 'P'.

* Ausprägungen der Strukturauflöserichtung
CONSTANTS:
      CON_BAUKASTEN              LIKE RJS0104-STRURICHT VALUE 'S',
      CON_VERWENDUNG             LIKE RJS0104-STRURICHT VALUE 'V'.

* Ausprägungen für den Strukturoutput
CONSTANTS:
      CON_INTTABZUO              LIKE RJS0101-STRUOUTPUT VALUE 'Z',
      CON_KNOTENTAB              LIKE RJS0101-STRUOUTPUT VALUE 'K',
      CON_BEIDES                 LIKE RJS0101-STRUOUTPUT VALUE 'B',
      CON_NICHTS                 LIKE RJS0101-STRUOUTPUT VALUE ' '.

* Ausprägungen für der StrukturUmfangAktiv (sollen nur aktive, nur
* inaktive oder beider Struktursätze gelesen werden).
CONSTANTS:
      CON_STRUAKTIV              LIKE JYTANRSTD-XSTRUAKTIV VALUE 'A',
      CON_STRUINAKTIV            LIKE JYTANRSTD-XSTRUAKTIV VALUE 'I',
      CON_STRUBEIDES             LIKE JYTANRSTD-XSTRUAKTIV VALUE 'B'.

* Ausprägungen für die Zuordnungsart, die gelesen werden soll (sollen
* nur normale, nur Unterbrechungen oder beide Arten von Zuordnungen
* gelesen werden).
CONSTANTS:
      CON_STRUNORMAL             LIKE RJS0101-STRUUMFART VALUE 'N',
      CON_STRUUNTERBRECHUNG      LIKE RJS0101-STRUUMFART VALUE 'U',
      CON_STRUNORMUNT            LIKE RJS0101-STRUUMFART VALUE 'B'.


* allg. Konstanten - Modifizieren --------------------------------*


* Ausprägungen des Funktionssteuer-Codes
CONSTANTS:
      CON_ZUO_HINZUFUEGEN       LIKE RJS0102-FCCODE    VALUE '01',
      CON_ZUO_BEENDEN           LIKE RJS0102-FCCODE    VALUE '02',
      CON_ZUO_UNTERBRECHEN      LIKE RJS0102-FCCODE    VALUE '03',
      CON_ZUO_MASTER            LIKE RJS0102-FCCODE    VALUE '04',
      CON_ZUO_LOESCHEN          LIKE RJS0102-FCCODE    VALUE '05',
      CON_ZUO_AENDPLAN          LIKE RJS0102-FCCODE    VALUE '06',
      CON_ZUO_AENDERUNG         LIKE RJS0102-FCCODE    VALUE '07',
      CON_ZUO_EXPUNTERBRECHEN   LIKE RJS0102-FCCODE    VALUE '08',
      CON_ZUO_BAR_BEENDEN       LIKE RJS0102-FCCODE    VALUE '09',
      CON_ZUO_BAR_BEE_LOESCHEN  LIKE RJS0102-FCCODE    VALUE '10',
      CON_ZUO_POINTER_AENDERN   LIKE RJS0102-FCCODE    VALUE '11',
      CON_ZUO_LOESCHEN_ZURUECK  LIKE RJS0102-FCCODE    VALUE '12',
      CON_ZUO_DEL_LOE_ZURUECK   LIKE RJS0102-FCCODE    VALUE '13',
* nur für internen Gebrauch SAPLJS01 !!!
      CON_ZUO_BEENDEN_REGEL_AKTIV " Beenden mit aktiver Änderungs-Nr.
                                LIKE RJS0102-FCCODE    VALUE '97',
      CON_ZUO_HINZUFUEGEN_RESTREGEL " hinzufügen mit befristeter Änd.Nr
                                LIKE RJS0102-FCCODE    VALUE '98',
      CON_ZUO_VERLAENGERN       LIKE RJS0102-FCCODE    VALUE '99'.

* Ausprägungen der Strukturinfo aktiv/inaktiv
CONSTANTS : CON_AKTIV   LIKE RJS0102-XSTRUAKTIV   VALUE ' ',
            CON_INAKTIV LIKE RJS0102-XSTRUAKTIV   VALUE 'X'.

* Ausprägungen der Zuordnungsart
CONSTANTS:
      CON_NORMAL        LIKE RJS0102-ZUORDART  VALUE ' ',
      CON_UNTERBRECHUNG LIKE RJS0102-ZUORDART  VALUE '-'.

* Ausprägungen der Zuordnungsfunktion
CONSTANTS:
      CON_INKLUSIVE LIKE RJS0102-ZUORDFUNK  VALUE ' ',
      CON_EXKLUSIVE LIKE RJS0102-ZUORDFUNK  VALUE '-'.

* Ausprägungen des Feldes RJS_KNOT01-xmanuell
CONSTANTS:
      CON_MORE_INFO LIKE RJS_KNOT01-XMANUELL VALUE '>'.

* Hierarchietyp Geographie
CONSTANTS:
      CON_HIETYP_GEO  LIKE  TJS01-HTPGEO  VALUE  '01'.


* Ausprägungen des DB-Codes
CONSTANTS:
      CON_SDB_INSERT       LIKE RJS0102-DBCODEFREI VALUE 'I',
      CON_SDB_UPDATE       LIKE RJS0102-DBCODEFREI VALUE 'U',
      CON_SDB_DELETE       LIKE RJS0102-DBCODEFREI VALUE 'D',
      CON_SDB_READ         LIKE RJS0102-DBCODEFREI VALUE 'R',
      CON_SDB_NO_OPERATION LIKE RJS0102-DBCODEFREI VALUE 'N'.

* In den Zuordnungssätzen wird vermerkt, ob das Ab- oder das Bis-
* Datum der angegebenen Änderungsnummer das Ab- oder Bis-Datum der
* Zuordnung bestimmt hat.
CONSTANTS:
      CON_AENDNR_AB              LIKE   RJS0102-AENDNRABD VALUE '1',
      CON_AENDNR_BIS             LIKE   RJS0102-AENDNRABD VALUE '2'.


* allg. Konstanten - Update --------------------------------------*

* Kennzeichen, welcher Update durchgeführt werden soll
CONSTANTS:
      CON_UPD_AENDER             LIKE   RJS0101-STRUUPDATE VALUE '1',
      CON_UPD_FREIGABE           LIKE   RJS0101-STRUUPDATE VALUE '2'.

* Maximale Anzahl Änderungen innerhalb einer Änderungsnummer
CONSTANTS:
      CON_MAX_LFDNR              LIKE  JSTAENDER-AENDLFDNR VALUE '9999'.

* Allg. gültige Parameter-ID's für Gültigab und Gültigbis
CONSTANTS:
      CON_VON_PARAMID(3)     VALUE 'JSA',
      CON_BIS_PARAMID(3)     VALUE 'JSB'.
