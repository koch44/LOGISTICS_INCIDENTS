*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_SELECT_EVT
*&---------------------------------------------------------------------*
 DATA: lc_regex      TYPE REF TO cl_abap_regex,
       lc_matcher    TYPE REF TO cl_abap_matcher,
       lv_match      TYPE c LENGTH 1,
       lv_check(100) TYPE c,
       lv_pattern    TYPE string,
       lv_success    TYPE char1,
       lv_count      TYPE i,
       lv_vdat_von   TYPE dats,
       lv_vdat_bis   TYPE dats,
       lv_vbeln      TYPE avnr,
       lv_vsgzustlr  TYPE vsgzustlr.

* Initialisierung
 INITIALIZATION.
   CLEAR: ls_variant, lv_count.
   ls_variant-report = sy-repid.
   CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
     EXPORTING
       i_save     = ls_save
     CHANGING
       cs_variant = ls_variant
     EXCEPTIONS
       not_found  = 2.
   IF sy-subrc = 0.
     p_vari = ls_variant-variant.
   ENDIF.

* TOP OF PAGE
 TOP-OF-PAGE.
   lv_count = lv_count + 1.
   PERFORM build_top_header.
   PERFORM build_header.

* PAI im Selektionsbild
 AT SELECTION-SCREEN.
   IF NOT p_vari IS INITIAL.
* prüfen ob Layout-Variante existiert.
     ls_variant-report = sy-repid.
     MOVE p_vari TO ls_variant-variant.
     CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
       EXPORTING
         i_save     = ls_save
       CHANGING
         cs_variant = ls_variant.
   ELSE.
     CLEAR ls_variant-variant.
   ENDIF.
* Eine der Optionen muß ausgewählt sein
   IF p_ord IS INITIAL AND p_slief IS INITIAL AND p_elief IS INITIAL.
     MESSAGE e000(jk) WITH text-010.
   ENDIF.
* Mailversand ohne Adresse geht nicht
   IF p_mail EQ 'X' AND p_madr IS INITIAL.
     MESSAGE e000(jk) WITH text-012.
   ENDIF.
* Mailadresse prüfen
   IF NOT p_madr IS INITIAL.
*        CREATE OBJECT lc_regex
*          EXPORTING
*            pattern                                               = '^[a-zA-Z]+(([\''\,\.\- ][a-zA-Z ])?[a-zA-Z]*)*\s+<'
*            &
*            '(\w[-._\w]*\w@\w[-._\w]*\w\.\w{2,3})>$|^(\w[-._\w]*'
*            &
*            '\w@\w[-._\w]*\w\.\w{2,3})$'.

     CREATE OBJECT lc_regex
       EXPORTING
         pattern = '^[\w\.=-]+@[\w\.-]+\.[\w]{2,3}$'.
     TRY.
         CREATE OBJECT lc_matcher
           EXPORTING
             regex = lc_regex
             text  = p_madr.
         IF lc_matcher->match( ) NE abap_true.
           MESSAGE e000(jk) WITH text-014.
         ENDIF.
       CATCH cx_sy_regex.
         MESSAGE e000(jk) WITH text-014.
       CATCH cx_sy_matcher .
         MESSAGE e000(jk) WITH text-014.
     ENDTRY.
   ENDIF.
* Keine Ausschlußkriterien beim Gültigkeitsdatum
   IF NOT s_fdat[] IS INITIAL.
* Aufgrund der Screengestaltung kann es nur eine Zeile geben
     READ TABLE s_fdat INDEX 1.
* Bestimmte Selektionskriterien sind außen vor
     IF s_fdat-option EQ 'NB' OR s_fdat-sign EQ 'E'.
       MESSAGE e000(jk) WITH text-015.
     ENDIF.
   ENDIF.


 AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
   CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
     EXPORTING
       is_variant = ls_variant
       i_save     = ls_save
     IMPORTING
       e_exit     = lv_exit
       es_variant = ls_variant
     EXCEPTIONS
       not_found  = 2.
   IF sy-subrc = 2.
     MESSAGE ID sy-msgid TYPE 'S'      NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ELSE.
     IF lv_exit = space.
       p_vari = ls_variant-variant.
     ENDIF.
   ENDIF.

* Beginn der Verarbeitung
 START-OF-SELECTION.

* Initialisieren
   PERFORM init.

* Datenselektion in Sequentieller Folge

*   -> Auftragsreklamationen
   PERFORM select_auftragsrekla.

*   -> Standard-JV41 Meldungen
   PERFORM select_stoer_standard.

*   -> Meldungen bis hierher in die Ausgabestruktur stellen
   PERFORM build_outtab.

*   -> Erweiterte Meldungen
   PERFORM select_stoer_enhanced.

*   -> Ausgabe als ALV-Liste
   PERFORM out_alv_list.

**   -> Ausgabe in den Spool als ALV-Liste
*      PERFORM out_spool_list.

* <-- aw20180409
*   -> Ausgabe in den Spool mit festem Layout
   PERFORM out_spool_layout.

*   -> Ausgabe als E-Mail mit Attachment
   PERFORM out_csv_mail.
