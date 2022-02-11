*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_F03
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
***INCLUDE ZJKR_STOER_MAINT_F03.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  SAVE_230_BEZIRK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_230_bezirk .

  DATA: bdcdata        TYPE jybdc_t_bdcdata WITH HEADER LINE.
  DATA: btci_options   TYPE ctu_params.
  DATA: bdcmsgtab      TYPE TABLE OF bdcmsgcoll.
  DATA: wa_bdcmsgtab   TYPE bdcmsgcoll.
  DATA: ls_log_handle TYPE balloghndl,
        lv_extnumber  TYPE bal_s_log-extnumber,
        ls_message    TYPE string,
        lt_fvnr       TYPE TABLE OF /msh/stoer_s_fvnr,
        ls_fvnr       TYPE /msh/stoer_s_fvnr.

* Nicht im Änderungsmodus
  IF gv_changemode IS INITIAL.
* Nur wenn Prüfungen erfolgt sind
    IF /msh/stoer_s_top-gueltigvon LE sy-datum AND gt_bezirk_cre[] IS INITIAL.
      CLEAR ok_0100.
      MESSAGE e031.
    ENDIF.

    UPDATE rseumod SET gra_editor = 'X'
              WHERE uname = sy-uname.
    COMMIT WORK.

    btci_options-nobinpt  = 'X'.
    btci_options-racommit = 'X'.
    btci_options-dismode  = 'N'.

* LOG anlegen
    PERFORM log_create USING '/MSH/STOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.

    REFRESH lt_fvnr[].

* Abarbeitung im Loop über die Anlagedaten
    LOOP AT gt_bezirk_cre INTO gs_bezirk.
      REFRESH: bdcdata,
               bdcmsgtab.
* Einstiegsbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0100'.
      PERFORM bdc_field TABLES bdcdata
*                      USING: 'FVART_TAB-XFELD(02)' 'X',
                        USING: 'G_FVART_0003_FLAG' 'X',
                               'BDC_OKCODE' '=ENT1'.
* Detailbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0200'.
      PERFORM bdc_field TABLES bdcdata
                        USING: 'BDC_OKCODE'          '=UPDA',
                               'JVTFEHLER-FVGRUND'    /msh/stoer_s_top-fvgrund,
                               'JVTFEHLER-VKORG'      /msh/stoer_s_lief-vkorg,
                               'JVTFEHLER-VTWEG'      /msh/stoer_s_lief-vtweg,
                               'JVTFEHLER-LFARTLOG'   gs_bezirk-lfartlog,
                               'JVTFEHLER-VRSNDDATUM' gs_bezirk-versanddat,
                               'JVTFEHLER-XBEZSPAET'  /msh/stoer_s_lief-xbezspaet,
                               'JVTFEHLER-DRUCKEREI'  /msh/stoer_s_lief-druckerei,
                               'JVTFEHLER-XBEZLIEGT'  /msh/stoer_s_lief-xbezliegt,
                               'JVTFEHLER-BEZIRK'     gs_bezirk-bezirktat,
                               'JVTFEHLER-XNACHLIEF'  /msh/stoer_s_lief-xnachlief,
                               'JVTFEHLER-NLEDATUM'   /msh/stoer_s_lief-nledatum,
                               'JVTFEHLER-NLEUHRZEIT' /msh/stoer_s_lief-nleuhrzeit,
                               'JVTFEHLER-FVVERURS'   /msh/stoer_s_lief-fvverurs.
* TA Aufrufen
      CALL TRANSACTION 'JV41' USING         bdcdata
                          OPTIONS  FROM btci_options
                          MESSAGES INTO bdcmsgtab.
      CLEAR wa_bdcmsgtab.
      READ TABLE bdcmsgtab INTO wa_bdcmsgtab
                WITH KEY msgid = 'JV'
                         msgnr = '809'.
      IF sy-subrc = 0.
* Erfolgreich
        MESSAGE i032 WITH wa_bdcmsgtab-msgv1 gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
        ls_fvnr-fvnr = wa_bdcmsgtab-msgv1.
        APPEND ls_fvnr TO lt_fvnr.
      ELSE.
* Fehler
        MESSAGE e033 WITH gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
      ENDIF.
    ENDLOOP.


* Log ausgeben und clearen
    PERFORM log_display_popup USING ls_log_handle.
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
  ENDIF.

* Generelles sichern
  PERFORM save_0230_general TABLES lt_fvnr.

ENDFORM.                    " SAVE_230_BEZIRK
*&---------------------------------------------------------------------*
*&      Form  SAVE_230_ZUSTELLUNG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_230_zustellung .
  DATA: bdcdata        TYPE jybdc_t_bdcdata WITH HEADER LINE.
  DATA: btci_options   TYPE ctu_params.
  DATA: bdcmsgtab      TYPE TABLE OF bdcmsgcoll.
  DATA: wa_bdcmsgtab   TYPE bdcmsgcoll.
  DATA: ls_log_handle TYPE balloghndl,
        lv_extnumber  TYPE bal_s_log-extnumber,
        ls_message    TYPE string,
        lt_fvnr       TYPE TABLE OF /msh/stoer_s_fvnr,
        ls_fvnr       TYPE /msh/stoer_s_fvnr.

* Nicht im Änderungsmodus
  IF gv_changemode IS INITIAL.
* Nur wenn Prüfungen erfolgt sind
    IF /msh/stoer_s_top-gueltigvon LE sy-datum AND gt_bezirk_cre[] IS INITIAL.
      CLEAR ok_0100.
      MESSAGE e031.
    ENDIF.

    UPDATE rseumod SET gra_editor = 'X'
              WHERE uname = sy-uname.
    COMMIT WORK.

    btci_options-nobinpt  = 'X'.
    btci_options-racommit = 'X'.
    btci_options-dismode  = 'N'.

* LOG anlegen
    PERFORM log_create USING 'ZSTOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.

    REFRESH lt_fvnr[].

* Abarbeitung im Loop über die Anlagedaten
    LOOP AT gt_bezirk_cre INTO gs_bezirk.
      REFRESH: bdcdata,
               bdcmsgtab.
* Einstiegsbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0100'.
      PERFORM bdc_field TABLES bdcdata
*                      USING: 'FVART_TAB-XFELD(02)' 'X',
                        USING: 'G_FVART_0002_FLAG' 'X',
                               'BDC_OKCODE' '=ENT1'.
* Detailbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0200'.
      PERFORM bdc_field TABLES bdcdata
                        USING: 'BDC_OKCODE'          '=UPDA',
                               'JVTFEHLER-FVGRUND'    /msh/stoer_s_top-fvgrund,
                               'JVTFEHLER-VKORG'      /msh/stoer_s_lief-vkorg,
                               'JVTFEHLER-VTWEG'      /msh/stoer_s_lief-vtweg,
                               'JVTFEHLER-LFARTLOG'   gs_bezirk-lfartlog,
                               'JVTFEHLER-VRSNDDATUM' gs_bezirk-versanddat,
                               'JVTFEHLER-DRERZ'      /msh/stoer_s_lief-drerz,
                               'JVTFEHLER-PVA'        /msh/stoer_s_lief-pva,
                               'JVTFEHLER-XBEZSPAET'  /msh/stoer_s_lief-xbezspaet,
                               'JVTFEHLER-XBEZLIEGT'  /msh/stoer_s_lief-xbezliegt,
                               'JVTFEHLER-BEZIRK'     gs_bezirk-bezirktat,
                               'JVTFEHLER-DRUCKEREI'  /msh/stoer_s_lief-druckerei,
                               'JVTFEHLER-BEABLST'    /msh/stoer_s_lief-beablst,
                               'JVTFEHLER-BEZRUNDE'   /msh/stoer_s_lief-bezrunde,
                               'JVTFEHLER-ROUTE'      /msh/stoer_s_lief-route,
                               'JVTFEHLER-XNACHLIEF'  /msh/stoer_s_lief-xnachlief,
                               'JVTFEHLER-NLEDATUM'   /msh/stoer_s_lief-nledatum,
                               'JVTFEHLER-NLEUHRZEIT' /msh/stoer_s_lief-nleuhrzeit,
                               'JVTFEHLER-FVVERURS'   /msh/stoer_s_lief-fvverurs.
* TA Aufrufen
      CALL TRANSACTION 'JV41' USING         bdcdata
                          OPTIONS  FROM btci_options
                          MESSAGES INTO bdcmsgtab.
      CLEAR wa_bdcmsgtab.
      READ TABLE bdcmsgtab INTO wa_bdcmsgtab
                WITH KEY msgid = 'JV'
                         msgnr = '809'.
      IF sy-subrc = 0.
* Erfolgreich
        MESSAGE i032 WITH wa_bdcmsgtab-msgv1 gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
        ls_fvnr-fvnr = wa_bdcmsgtab-msgv1.
        APPEND ls_fvnr TO lt_fvnr.
      ELSE.
* Fehler
        MESSAGE e033 WITH gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
      ENDIF.
    ENDLOOP.


* Log ausgeben und clearen
    PERFORM log_display_popup USING ls_log_handle.
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
  ENDIF.

* Generelles sichern
  PERFORM save_0230_general TABLES lt_fvnr.
ENDFORM.                    " SAVE_230_ZUSTELLUNG
*&---------------------------------------------------------------------*
*&      Form  SAVE_230_BEZRUNDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_230_bezrunde .
  DATA: bdcdata        TYPE jybdc_t_bdcdata WITH HEADER LINE.
  DATA: btci_options   TYPE ctu_params.
  DATA: bdcmsgtab      TYPE TABLE OF bdcmsgcoll.
  DATA: wa_bdcmsgtab   TYPE bdcmsgcoll.
  DATA: ls_log_handle TYPE balloghndl,
        lv_extnumber  TYPE bal_s_log-extnumber,
        ls_message    TYPE string,
        lt_fvnr       TYPE TABLE OF /msh/stoer_s_fvnr,
        ls_fvnr       TYPE /msh/stoer_s_fvnr.

* Nicht im Änderungsmodus
  IF gv_changemode IS INITIAL.
* Nur wenn Prüfungen erfolgt sind
    IF /msh/stoer_s_top-gueltigvon LE sy-datum AND gt_bezirk_cre[] IS INITIAL.
      CLEAR ok_0100.
      MESSAGE e031.
    ENDIF.

    UPDATE rseumod SET gra_editor = 'X'
              WHERE uname = sy-uname.
    COMMIT WORK.

    btci_options-nobinpt  = 'X'.
    btci_options-racommit = 'X'.
    btci_options-dismode  = 'N'.

* LOG anlegen
    PERFORM log_create USING '/MSH/STOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.

    REFRESH lt_fvnr[].

* Abarbeitung im Loop über die Anlagedaten
    LOOP AT gt_bezirk_cre INTO gs_bezirk.
      REFRESH: bdcdata,
               bdcmsgtab.
* Einstiegsbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0100'.
      PERFORM bdc_field TABLES bdcdata
*                      USING: 'FVART_TAB-XFELD(02)' 'X',
                        USING: 'G_FVART_0004_FLAG' 'X',
                               'BDC_OKCODE' '=ENT1'.
* Detailbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0200'.
      PERFORM bdc_field TABLES bdcdata
                        USING: 'BDC_OKCODE'          '=UPDA',
                               'JVTFEHLER-FVGRUND'    /msh/stoer_s_top-fvgrund,
                               'JVTFEHLER-VKORG'      /msh/stoer_s_lief-vkorg,
                               'JVTFEHLER-VTWEG'      /msh/stoer_s_lief-vtweg,
                               'JVTFEHLER-LFARTLOG'   gs_bezirk-lfartlog,
                               'JVTFEHLER-VRSNDDATUM' gs_bezirk-versanddat,
                               'JVTFEHLER-DRUCKEREI'  /msh/stoer_s_lief-druckerei,
                               'JVTFEHLER-XBEZSPAET'  /msh/stoer_s_lief-xbezspaet,
                               'JVTFEHLER-XBEZLIEGT'  /msh/stoer_s_lief-xbezliegt,
                               'JVTFEHLER-BEZIRK'     gs_bezirk-bezirktat,
                               'JVTFEHLER-BEZRUNDE'   /msh/stoer_s_lief-bezrunde,
                               'JVTFEHLER-XNACHLIEF'  /msh/stoer_s_lief-xnachlief,
                               'JVTFEHLER-NLEDATUM'   /msh/stoer_s_lief-nledatum,
                               'JVTFEHLER-NLEUHRZEIT' /msh/stoer_s_lief-nleuhrzeit,
                               'JVTFEHLER-FVVERURS'   /msh/stoer_s_lief-fvverurs.
* TA Aufrufen
      CALL TRANSACTION 'JV41' USING         bdcdata
                          OPTIONS  FROM btci_options
                          MESSAGES INTO bdcmsgtab.
      CLEAR wa_bdcmsgtab.
      READ TABLE bdcmsgtab INTO wa_bdcmsgtab
                WITH KEY msgid = 'JV'
                         msgnr = '809'.
      IF sy-subrc = 0.
* Erfolgreich
        MESSAGE i032 WITH wa_bdcmsgtab-msgv1 gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
        ls_fvnr-fvnr = wa_bdcmsgtab-msgv1.
        APPEND ls_fvnr TO lt_fvnr.
      ELSE.
* Fehler
        MESSAGE e033 WITH gs_bezirk-bezirktat gs_bezirk-versanddat INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
      ENDIF.
    ENDLOOP.


* Log ausgeben und clearen
    PERFORM log_display_popup USING ls_log_handle.
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
  ENDIF.

* Generelles sichern
  PERFORM save_0230_general TABLES lt_fvnr.
ENDFORM.                    " SAVE_230_BEZRUNDE
*&---------------------------------------------------------------------*
*&      Form  SAVE_230_PVA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_230_pva .
  DATA: bdcdata        TYPE jybdc_t_bdcdata WITH HEADER LINE.
  DATA: btci_options   TYPE ctu_params.
  DATA: bdcmsgtab      TYPE TABLE OF bdcmsgcoll.
  DATA: wa_bdcmsgtab   TYPE bdcmsgcoll.
  DATA: ls_log_handle TYPE balloghndl,
        lv_extnumber  TYPE bal_s_log-extnumber,
        ls_message    TYPE string,
        lt_fvnr       TYPE TABLE OF /msh/stoer_s_fvnr,
        ls_fvnr       TYPE /msh/stoer_s_fvnr,
        ls_jdtvausgb  TYPE jdtvausgb.

* Nicht im Änderungsmodus
  IF gv_changemode IS INITIAL.

* Nur wenn Prüfungen erfolgt sind
    IF /msh/stoer_s_top-gueltigvon LE sy-datum AND gt_jdtvausgb[] IS INITIAL.
      CLEAR ok_0100.
      MESSAGE e031.
    ENDIF.

    UPDATE rseumod SET gra_editor = 'X'
              WHERE uname = sy-uname.
    COMMIT WORK.

    btci_options-nobinpt  = 'X'.
    btci_options-racommit = 'X'.
    btci_options-dismode  = 'N'.

* LOG anlegen
    PERFORM log_create USING '/MSH/STOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.

    REFRESH lt_fvnr[].

* Abarbeitung im Loop über die Anlagedaten
    LOOP AT gt_jdtvausgb INTO ls_jdtvausgb.

      REFRESH: bdcdata,
               bdcmsgtab.
* Einstiegsbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0100'.
      PERFORM bdc_field TABLES bdcdata
*                      USING: 'FVART_TAB-XFELD(02)' 'X',
                        USING: 'G_FVART_0005_FLAG' 'X',
                               'BDC_OKCODE' '=ENT1'.
* Detailbild
      PERFORM bdc_dynpro TABLES bdcdata
                         USING  'SAPMJV41' '0200'.
      PERFORM bdc_field TABLES bdcdata
                        USING: 'BDC_OKCODE'          '=UPDA',
                               'JVTFEHLER-FVGRUND'    /msh/stoer_s_top-fvgrund,
                               'JVTFEHLER-VKORG'      /msh/stoer_s_lief-vkorg,
                               'JVTFEHLER-VTWEG'      /msh/stoer_s_lief-vtweg,
                               'JVTFEHLER-LFARTLOG'   /msh/stoer_s_lief-lfartlog,
                               'JVTFEHLER-VRSNDDATUM' ls_jdtvausgb-erschdat,
                               'JVTFEHLER-XBEZSPAET'  /msh/stoer_s_lief-xbezspaet,
                               'JVTFEHLER-DRERZ'      /msh/stoer_s_lief-drerz,
                               'JVTFEHLER-PVA'        /msh/stoer_s_lief-pva,
                               'JVTFEHLER-DRUCKEREI'  /msh/stoer_s_lief-druckerei,
                               'JVTFEHLER-XNACHLIEF'  /msh/stoer_s_lief-xnachlief,
                               'JVTFEHLER-NLEDATUM'   /msh/stoer_s_lief-nledatum,
                               'JVTFEHLER-NLEUHRZEIT' /msh/stoer_s_lief-nleuhrzeit,
                               'JVTFEHLER-FVVERURS'   /msh/stoer_s_lief-fvverurs.
* TA Aufrufen
      CALL TRANSACTION 'JV41' USING         bdcdata
                          OPTIONS  FROM btci_options
                          MESSAGES INTO bdcmsgtab.
      CLEAR wa_bdcmsgtab.
      READ TABLE bdcmsgtab INTO wa_bdcmsgtab
                WITH KEY msgid = 'JV'
                         msgnr = '809'.
      IF sy-subrc = 0.
* Erfolgreich
        MESSAGE i035 WITH wa_bdcmsgtab-msgv1 ls_jdtvausgb-drerz ls_jdtvausgb-pva ls_jdtvausgb-erschdat INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
        ls_fvnr-fvnr = wa_bdcmsgtab-msgv1.
        APPEND ls_fvnr TO lt_fvnr.
      ELSE.
* Fehler
        MESSAGE e036 WITH ls_jdtvausgb-drerz ls_jdtvausgb-pva ls_jdtvausgb-erschdat INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
      ENDIF.
    ENDLOOP.


* Log ausgeben und clearen
    PERFORM log_display_popup USING ls_log_handle.
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
  ENDIF.

* Generelles sichern
  PERFORM save_0230_general TABLES lt_fvnr.
ENDFORM.                    " SAVE_230_PVA
*&---------------------------------------------------------------------*
*&      Form  SAVE_0230_GENERAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FVNR  text
*----------------------------------------------------------------------*
FORM save_0230_general  TABLES   pt_fvnr STRUCTURE /msh/stoer_s_fvnr.

  DATA: lt_text TYPE text_table_type,
        ls_fvnr LIKE LINE OF pt_fvnr.
  DATA: wa_header TYPE  thead,
        itc_lines TYPE ism_tline_tab.
  DATA: ls_stoer TYPE /msh/stoer_t_lf,
        lv_error TYPE xfeld.

* Text prüfen
  PERFORM check_and_set_text USING '0230'
                             CHANGING lt_text.
  IF NOT lt_text[] IS INITIAL.
    /msh/stoer_s_lief-xcomment_lief = 'X'.
* Text konvertieren
    CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
      TABLES
        text_stream = lt_text
        itf_text    = itc_lines.
  ELSE.
    CLEAR /msh/stoer_s_lief-xcomment_lief.
  ENDIF.


* Texte fortschreiben in ggf. bereits angelegte Fehlernummern
  IF NOT pt_fvnr[] IS INITIAL AND /msh/stoer_s_lief-xcomment_lief EQ 'X'.
    CLEAR wa_header.
    wa_header-tdobject = 'JVTFEHLER'.
    wa_header-tdid = 'KOM1'.
    wa_header-tdspras = 'D'.
    wa_header-tdform = 'SYSTEM'.
    wa_header-tdfuser = sy-uname.
    wa_header-tdfdate = sy-datum.
    wa_header-tdftime = sy-uzeit.
    wa_header-tdlinesize = '072'.
    LOOP AT pt_fvnr INTO ls_fvnr.
      wa_header-tdname = ls_fvnr-fvnr.
      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
          header          = wa_header
          savemode_direct = 'X'
        TABLES
          lines           = itc_lines
        EXCEPTIONS
          id              = 1
          language        = 2
          name            = 3
          object          = 4
          OTHERS          = 5.
      IF sy-subrc = 0.
        CALL FUNCTION 'COMMIT_TEXT'
          EXPORTING
            object   = wa_header-tdobject
            name     = wa_header-tdname
            id       = wa_header-tdid
            language = wa_header-tdspras.
        UPDATE jvtfehler SET xkom1 = 'X' WHERE fvnr = ls_fvnr-fvnr.
        COMMIT WORK.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Nummer holen
  IF gv_changemode IS INITIAL.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = '/MSH/STOER'
      IMPORTING
        number                  = ls_stoer-stoerid
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
      CLEAR ok_0100.
      MESSAGE e009.
    ENDIF.
  ELSE.
    ls_stoer-stoerid = gv_stoerid.
  ENDIF.

* Daten moven
  ls_stoer-mandt = sy-mandt.
  MOVE-CORRESPONDING /msh/stoer_s_lief TO ls_stoer.
  MOVE-CORRESPONDING /msh/stoer_s_top TO ls_stoer.
  IF gv_changemode IS INITIAL.
    ls_stoer-erfuser = sy-uname.
    ls_stoer-erfdate = sy-datum.
    ls_stoer-erftime = sy-uzeit.
  ELSE.
    SELECT SINGLE erfuser erfdate erftime INTO
            (ls_stoer-erfuser, ls_stoer-erfdate, ls_stoer-erftime)
           FROM /msh/stoer_t_lf WHERE stoerid = gv_stoerid.
    ls_stoer-aenuser = sy-uname.
    ls_stoer-aendate = sy-datum.
    ls_stoer-aentime = sy-uzeit.
  ENDIF.

* Text sichern
  PERFORM save_text USING lt_text
                          ls_stoer-stoerid
                          'LIEF'
                    CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    MESSAGE e009.
  ENDIF.

* DB-Update
  CLEAR ok_0100.
  MODIFY /msh/stoer_t_lf FROM ls_stoer.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE s010 WITH 'Auslieferungsstörung' ls_stoer-stoerid.
* Zuordnungstabelle sichern
    IF NOT pt_fvnr[] IS INITIAL AND gv_changemode IS INITIAL.
      PERFORM save_liefzuo TABLES pt_fvnr
                           USING ls_stoer-stoerid.
    ENDIF.
* Startscreen
    PERFORM back_to_start.
  ELSE.
    MESSAGE e009.
  ENDIF.
ENDFORM.                    " SAVE_0230_GENERAL
*&---------------------------------------------------------------------*
*&      Form  SAVE_LIEFZUO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_STOER_ZSTOERID  text
*      -->P_PT_FVNR  text
*----------------------------------------------------------------------*
FORM save_liefzuo  TABLES   pt_fvnr STRUCTURE /msh/stoer_s_fvnr
                   USING    pv_stoerid TYPE /msh/stoerid.

  DATA: ls_stoerzuo TYPE /msh/stoer_t_lz,
        ls_fvnr     LIKE LINE OF pt_fvnr.

  CHECK NOT pv_stoerid IS INITIAL.

  CLEAR ls_stoerzuo.
  ls_stoerzuo-mandt = sy-mandt.
  ls_stoerzuo-erfuser = sy-uname.
  ls_stoerzuo-erfdate = sy-datum.
  ls_stoerzuo-erftime = sy-uzeit.
  ls_stoerzuo-stoerid = pv_stoerid.

  LOOP AT pt_fvnr INTO ls_fvnr.
    ls_stoerzuo-fvnr = ls_fvnr-fvnr.
    MODIFY /msh/stoer_t_lz FROM ls_stoerzuo.
    COMMIT WORK.
  ENDLOOP.


ENDFORM.                    " SAVE_LIEFZUO
*&---------------------------------------------------------------------*
*&      Form  call_view_ext
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_view_ext USING iv_key TYPE swo_typeid.

* Memory Export
  EXPORT ev_key FROM iv_key TO MEMORY ID 'STOERKEY'.

* Screenaufruf
  CALL TRANSACTION '/MSH/STOER_DYN'.
ENDFORM.                    " call_view_ext
*&---------------------------------------------------------------------*
*&      Form  IMPORT_FROM_EXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM import_from_ext .
  DATA: lv_key TYPE swo_typeid.

  FIELD-SYMBOLS: <fs_dyn> TYPE any.

* Importieren
  IMPORT ev_key TO lv_key FROM MEMORY ID 'STOERKEY'.
  FREE MEMORY ID 'STOERKEY'.
* CUST-Eintrag lesen
  SELECT SINGLE * FROM /msh/stoer_t_cst INTO gs_cust WHERE area_id = lv_key(2).
  CHECK sy-subrc = 0.

* Daten selektieren und in die Struktur stellen
* Die DB-Tab und Dynprostruktur muß gepflegt sein
  CHECK NOT gs_cust-area_dbtab IS INITIAL.
  CHECK NOT gs_cust-area_dynstruc IS INITIAL.
* Die Tabelle muß die Spalte GUELTIGBIS haben
  SELECT SINGLE COUNT(*) FROM dd03l WHERE tabname = gs_cust-area_dbtab
                                    AND fieldname EQ 'STOERID'.
  CHECK sy-subrc = 0.
  ASSIGN (gs_cust-area_dynstruc) TO <fs_dyn>.
  SELECT SINGLE * FROM (gs_cust-area_dbtab) INTO CORRESPONDING FIELDS OF <fs_dyn>
                                             WHERE stoerid = lv_key+2.
  SELECT SINGLE * FROM (gs_cust-area_dbtab) INTO CORRESPONDING FIELDS OF /msh/stoer_s_top
                                             WHERE stoerid = lv_key+2.
  gv_stoerid = lv_key+2.
* Screenaufruf je nach ID
  gv_repid = gs_cust-area_repid.
  gv_dynnr = gs_cust-area_dynnr.
ENDFORM.                    " IMPORT_FROM_EXT
*&---------------------------------------------------------------------*
*&      Module  SET_GP_LAND  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_gp_land OUTPUT.
  IF gs_0220_old IS INITIAL.
    /msh/stoer_s_gp-land1 = 'DE'.
  ENDIF.
ENDMODULE.                 " SET_GP_LAND  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  DUMMY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dummy .

ENDFORM.                    " DUMMY
*&---------------------------------------------------------------------*
*&      Form  UPDATE_DYN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GV_REPID  text
*      -->P_GV_DYNNR  text
*      -->P_<FS_DYN>  text
*----------------------------------------------------------------------*
FORM update_dyn  USING    pv_stoerid TYPE /msh/stoerid
                 CHANGING pv_xdo TYPE xfeld.

  DATA: lv_answ(1) TYPE c.


  IF NOT gv_stoerid_old IS INITIAL AND gv_stoerid_old NE pv_stoerid.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = 'Geänderte Daten gehen verloren. Fortsetzen?'
        text_button_1         = 'Ja'
        text_button_2         = 'Nein'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answ
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF lv_answ = '1'.
      pv_xdo = 'X'.
      gv_stoerid_old = pv_stoerid.
    ELSE.
      CLEAR pv_xdo.
    ENDIF.
  ELSE.
    pv_xdo = 'X'.
    gv_stoerid_old = pv_stoerid.
  ENDIF.

ENDFORM.                    " UPDATE_DYN
*&---------------------------------------------------------------------*
*&      Form  CHECK_ROUTE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_/MSH/STOER_S_LIEF_ROUTE  text
*      <--P_/MSH/STOER_S_TOP  text
*----------------------------------------------------------------------*
FORM check_route  USING    pv_route TYPE tagroute
                  CHANGING ps_stoer_top TYPE /msh/stoer_s_top.

  DATA: lv_checkdate TYPE dats,
        lv_newmin    TYPE dats,
        lv_newmax    TYPE dats,
        lv_errdat    TYPE dats,
        lv_error     TYPE xfeld.

* Nur wenn eine Route übergeben wird
  CHECK NOT pv_route IS INITIAL.

* Nur wenn die Gültigkeit festgelegt ist
  CHECK NOT ( ps_stoer_top-gueltigvon IS INITIAL AND ps_stoer_top-gueltigbis IS INITIAL ).

* Wird die Route an jedem Tag des Störungsintervalls bedient?
  lv_checkdate = ps_stoer_top-gueltigvon.

  CLEAR: lv_error, lv_newmin, lv_newmax.

* Maximaldatum vorerst immer GültigBis
  lv_newmax = ps_stoer_top-gueltigbis.

  WHILE lv_checkdate LE ps_stoer_top-gueltigbis.
    SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = pv_route AND dispodat = lv_checkdate.
    IF sy-subrc = 0. "Route an diesem Tag bedient
      IF lv_newmin IS INITIAL.
        lv_newmin = lv_checkdate. "Beginn
      ENDIF.
      lv_newmax = lv_checkdate. "Ende
      lv_checkdate = lv_checkdate + 1. "Nächster Tag
    ELSE.            "Route an diesem Tag nicht bedient
      lv_error = 'X'.
      lv_errdat = lv_checkdate.
      lv_checkdate = lv_checkdate + 1. "Nächster Tag
    ENDIF.
  ENDWHILE.

* Wie sieht jetzt die Konstellation aus?
  IF lv_newmin NE ps_stoer_top-gueltigvon AND NOT lv_newmin IS INITIAL AND lv_newmin NE '00000000'.
    ps_stoer_top-gueltigvon = lv_newmin.
  ENDIF.
  IF lv_newmax NE ps_stoer_top-gueltigbis.
    ps_stoer_top-gueltigbis = lv_newmax.
  ENDIF.

* Text ggf. neu
  MESSAGE i003 WITH ps_stoer_top-gueltigvon ps_stoer_top-gueltigbis INTO gv_time.

* Meldung bei Fehler je nach Konstellation
  IF lv_error EQ 'X'.
    IF NOT lv_newmin IS INITIAL.
      MESSAGE i042 WITH pv_route lv_errdat.
    ELSE.
      MESSAGE e043 WITH pv_route.
    ENDIF.
  ENDIF.
ENDFORM.                    " CHECK_ROUTE
*&---------------------------------------------------------------------*
*&      Form  SELECT_PROD_EXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_EXIST  text
*----------------------------------------------------------------------*
FORM select_prod_ext  TABLES pt_zuo STRUCTURE /msh/stoer_t_lz
                      CHANGING   pt_exist TYPE /msh/stoer_tt_exist_lief.

  DATA: lt_stoer_prod TYPE TABLE OF /msh/stoer_t_prd,
        ls_stoer_prod TYPE /msh/stoer_t_prd,
        ls_exist      TYPE /msh/stoer_s_exist_lief,
        lt_text       TYPE TABLE OF tline,
        lv_name       TYPE thead-tdname,
        xnobezirk     TYPE xfeld,
        ls_zuo        LIKE LINE OF pt_zuo,
        r_bezirk      TYPE RANGE OF bezirk,
        ls_bezirk     LIKE LINE OF r_bezirk.

* Bezirke aufbauen
  IF NOT /msh/stoer_s_lief-bezirk IS INITIAL.
    ls_bezirk-sign = 'I'.
    ls_bezirk-option = 'EQ'.
    ls_bezirk-low = /msh/stoer_s_lief-bezirk.
    APPEND ls_bezirk TO r_bezirk.
    CLEAR xnobezirk.
  ELSE.
    xnobezirk = 'X'.
  ENDIF.
  IF NOT pt_zuo[] IS INITIAL.
    LOOP AT pt_zuo INTO ls_zuo.
      CLEAR ls_bezirk.
      SELECT SINGLE bezirk FROM jvtfehler INTO ls_bezirk-low WHERE fvnr = ls_zuo-fvnr.
      CHECK NOT ls_bezirk-low IS INITIAL.
      ls_bezirk-sign = 'I'.
      ls_bezirk-option = 'EQ'.
      APPEND ls_bezirk TO r_bezirk.
    ENDLOOP.
  ENDIF.

  IF xnobezirk = 'X'.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_stoer_prod WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                           AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                           AND drerz_prod = /msh/stoer_s_lief-drerz
                                                           AND pva_prod = /msh/stoer_s_lief-pva
                                                           AND route EQ /msh/stoer_s_lief-route.

  ELSE.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_stoer_prod WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                           AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                           AND drerz_prod = /msh/stoer_s_lief-drerz
                                                           AND pva_prod = /msh/stoer_s_lief-pva
                                                           AND bezirk_prod IN r_bezirk.
  ENDIF.

  LOOP AT lt_stoer_prod INTO ls_stoer_prod.
    CLEAR ls_exist.
* Feldweise moven
    ls_exist-erfuser = ls_stoer_prod-erfuser.
    ls_exist-gueltigvon = ls_stoer_prod-gueltigvon.
    ls_exist-gueltigbis = ls_stoer_prod-gueltigbis.
    ls_exist-bezirk = ls_stoer_prod-bezirk_prod.
    ls_exist-route = ls_stoer_prod-route.
    SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_prod-fvgrund.
    IF ls_stoer_prod-xcomment_prod EQ 'X'.
      REFRESH lt_text[].
      lv_name = ls_stoer_prod-stoerid.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id                      = 'PROD'
          language                = sy-langu
          name                    = lv_name
          object                  = '/MSH/STOER'
        TABLES
          lines                   = lt_text
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc = 0.
        CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
          EXPORTING
            it_tline       = lt_text
          IMPORTING
            ev_text_string = ls_exist-kommentar.
      ENDIF.
    ENDIF.
    ls_exist-stoerid = ls_stoer_prod-stoerid.
    ls_exist-kurztext = 'Produktion'.
    ls_exist-drerz = ls_stoer_prod-drerz_prod.
    ls_exist-pva = ls_stoer_prod-pva_prod.
    ls_exist-linec = 'C400'.
    APPEND ls_exist TO pt_exist.
  ENDLOOP.
ENDFORM.                    " SELECT_PROD_EXT
*&---------------------------------------------------------------------*
*&      Form  GET_VSG_ROUTE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_vsg_route USING p_mode TYPE char1.

  DATA: ls_par   TYPE rjv2001,
        lt_vsg   TYPE TABLE OF rjv0401,
        lv_beab  TYPE jvtbezart-beabstelle,
        lv_route TYPE jrtroubea-route.

  CASE p_mode.
    WHEN 'L'. "Auslieferung

      "VSG initial?
      IF /msh/stoer_s_lief-vsgzustlr IS INITIAL.
        "Obligatorische Daten da?
        CHECK NOT /msh/stoer_s_lief-bezirk IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigvon IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigbis IS INITIAL.
        "Selektion füllen
        ls_par-bezirk = /msh/stoer_s_lief-bezirk.
        OVERLAY ls_par-bezrunde WITH '********************************'.
        OVERLAY ls_par-gp_rolle WITH '********************************'.
        OVERLAY ls_par-jgpartner WITH '********************************'.
        OVERLAY ls_par-jservges WITH '********************************'.
        "VSG ermitteln
        CALL FUNCTION 'ISP_SELECT_JVTBEZGP'
          EXPORTING
            bezrndpar       = ls_par
            bis_d           = /msh/stoer_s_top-gueltigbis
            flg_aktive_only = 'X'
            von_d           = /msh/stoer_s_top-gueltigvon
          TABLES
            bezrndgp_tab    = lt_vsg.
        CHECK NOT lt_vsg[] IS INITIAL.
        SORT lt_vsg BY jservges ASCENDING.
        DELETE ADJACENT DUPLICATES FROM lt_vsg COMPARING jservges.
        CHECK lines( lt_vsg ) EQ 1. "Ansonsten muss man hier ein Popup zur Auswahl einbauen
        READ TABLE lt_vsg ASSIGNING FIELD-SYMBOL(<fs_vsg>) INDEX 1.
        /msh/stoer_s_lief-vsgzustlr = <fs_vsg>-jservges.
      ENDIF.

      "Route initial?
      IF /msh/stoer_s_lief-route IS INITIAL.
        "Obligatorische Daten da?
        CHECK NOT /msh/stoer_s_lief-bezirk IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigvon IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigbis IS INITIAL.
        "Über die Abladungen?
        IF NOT /msh/stoer_s_lief-drerz IS INITIAL.
          SELECT SINGLE route FROM jrtablg INTO lv_route WHERE bezirktat = /msh/stoer_s_lief-bezirk AND drerztat = /msh/stoer_s_lief-drerz AND versanddat = /msh/stoer_s_top-gueltigvon.
        ELSE.
          SELECT SINGLE route FROM jrtablg INTO lv_route WHERE bezirktat = /msh/stoer_s_lief-bezirk AND versanddat = /msh/stoer_s_top-gueltigvon.
        ENDIF.
        IF sy-subrc NE 0 OR lv_route IS INITIAL.
          "Hauptabladestelle
          SELECT SINGLE beabstelle FROM jvtbezart INTO lv_beab WHERE bezirk = /msh/stoer_s_lief-bezirk.
          CHECK NOT lv_beab IS INITIAL.
          "Route (erdtmal abstrahhiert von Zeitraum)
          SELECT SINGLE route FROM jrtroubea INTO lv_route WHERE beablst = lv_beab AND gueltigab LE /msh/stoer_s_top-gueltigvon
                                                                                   AND gueltigbis GE /msh/stoer_s_top-gueltigbis.
          CHECK NOT lv_route IS INITIAL.
        ENDIF.
        "Tagesroute (basierend auf Beginndatum, ansonsten müsste man ein Popup zur Auswahl ggf. vorsehen)
        SELECT SINGLE route FROM jrttroute INTO /msh/stoer_s_lief-route WHERE basisroute = lv_route AND dispodat = /msh/stoer_s_top-gueltigvon.
      ENDIF.
    WHEN 'K'. "Kunde
      "VSG initial?
      IF /msh/stoer_s_gp-vsgzustlr IS INITIAL.
        "Obligatorische Daten da?
        CHECK NOT /msh/stoer_s_gp-bezirk_gp IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigvon IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigbis IS INITIAL.
        "Selektion füllen
        ls_par-bezirk = /msh/stoer_s_gp-bezirk_gp.
        OVERLAY ls_par-bezrunde WITH '********************************'.
        OVERLAY ls_par-gp_rolle WITH '********************************'.
        OVERLAY ls_par-jgpartner WITH '********************************'.
        OVERLAY ls_par-jservges WITH '********************************'.
        "VSG ermitteln
        CALL FUNCTION 'ISP_SELECT_JVTBEZGP'
          EXPORTING
            bezrndpar       = ls_par
            bis_d           = /msh/stoer_s_top-gueltigbis
            flg_aktive_only = 'X'
            von_d           = /msh/stoer_s_top-gueltigvon
          TABLES
            bezrndgp_tab    = lt_vsg.
        CHECK NOT lt_vsg[] IS INITIAL.
        SORT lt_vsg BY jservges ASCENDING.
        DELETE ADJACENT DUPLICATES FROM lt_vsg COMPARING jservges.
        CHECK lines( lt_vsg ) EQ 1. "Ansonsten muss man hier ein Popup zur Auswahl einbauen
        READ TABLE lt_vsg ASSIGNING <fs_vsg> INDEX 1.
        /msh/stoer_s_gp-vsgzustlr = <fs_vsg>-jservges.
      ENDIF.

      "Route initial?
      IF /msh/stoer_s_gp-route IS INITIAL.
        "Obligatorische Daten da?
        CHECK NOT /msh/stoer_s_gp-bezirk_gp IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigvon IS INITIAL.
        CHECK NOT /msh/stoer_s_top-gueltigbis IS INITIAL.
        "Über die Abladungen?
        IF NOT /msh/stoer_s_gp-drerz IS INITIAL.
          SELECT SINGLE route FROM jrtablg INTO lv_route WHERE bezirktat = /msh/stoer_s_gp-bezirk_gp AND drerztat = /msh/stoer_s_gp-drerz AND versanddat = /msh/stoer_s_top-gueltigvon.
        ELSE.
          SELECT SINGLE route FROM jrtablg INTO lv_route WHERE bezirktat = /msh/stoer_s_gp-bezirk_gp AND versanddat = /msh/stoer_s_top-gueltigvon.
        ENDIF.
        IF sy-subrc NE 0 OR lv_route IS INITIAL.
          "Hauptabladestelle
          SELECT SINGLE beabstelle FROM jvtbezart INTO lv_beab WHERE bezirk = /msh/stoer_s_gp-bezirk_gp.
          CHECK NOT lv_beab IS INITIAL.
          "Route (erdtmal abstrahhiert von Zeitraum)
          SELECT SINGLE route FROM jrtroubea INTO lv_route WHERE beablst = lv_beab AND gueltigab LE /msh/stoer_s_top-gueltigvon
                                                                                   AND gueltigbis GE /msh/stoer_s_top-gueltigbis.
          CHECK NOT lv_route IS INITIAL.
        ENDIF.
        "Tagesroute (basierend auf Beginndatum, ansonsten müsste man ein Popup zur Auswahl ggf. vorsehen)
        SELECT SINGLE route FROM jrttroute INTO /msh/stoer_s_gp-route WHERE basisroute = lv_route AND dispodat = /msh/stoer_s_top-gueltigvon.
      ENDIF.
  ENDCASE.
ENDFORM.
