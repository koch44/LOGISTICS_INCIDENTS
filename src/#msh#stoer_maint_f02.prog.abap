*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_F02
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  LOAD_ACTFORCHANGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_actforchange .
  CHECK gv_called IS INITIAL.

* Customizing-Daten einlesen
  PERFORM preload_global.
  CHECK NOT gt_cust[] IS INITIAL.

* Daten leeren
  REFRESH: gt_overview[].

* Daten aufbauen
  LOOP AT gt_cust INTO gs_cust.
    CLEAR gs_overview.
* Die DB-Tab muß gepflegt sein
    CHECK NOT gs_cust-area_dbtab IS INITIAL.
* Die Tabelle muß die Spalte GUELTIGBIS haben
    SELECT SINGLE COUNT(*) FROM dd03l WHERE tabname = gs_cust-area_dbtab
                                      AND fieldname EQ 'GUELTIGBIS'.
    CHECK sy-subrc = 0.
* Zeile aufbauen
    gs_overview-area = gs_cust-area_info.
    gs_overview-id = gs_cust-area_id.
    SELECT COUNT(*) FROM (gs_cust-area_dbtab) INTO gs_overview-stoercount
                                                WHERE gueltigbis GE sy-datum.
    APPEND gs_overview TO gt_overview.
  ENDLOOP.

ENDFORM.                    " LOAD_ACTFORCHANGE
*&---------------------------------------------------------------------*
*&      Form  SHOW_ACTFORCHANGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_actforchange .
  DATA: ls_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat.

  IF gc_meld IS INITIAL.
    CREATE OBJECT gc_meld
      EXPORTING
        i_parent = gc_cont_meld.
  ENDIF.

* Handler setzen
  SET HANDLER lcl_hotspot_change_over=>on_hotspot_click FOR gc_meld.

* Feldkatalog bauen
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/MSH/STOER_S_OVER'
      i_client_never_display = 'X'
    CHANGING
      ct_fieldcat            = lt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    CASE ls_fieldcat-fieldname.
      WHEN 'ID'.
        ls_fieldcat-no_out = 'X'.
      WHEN 'STOERCOUNT'.
        ls_fieldcat-coltext = 'Anzahl Meldungen'.
      WHEN 'AREA'.
        ls_fieldcat-coltext = 'Störungsbereich'.
        ls_fieldcat-hotspot = 'X'.
    ENDCASE.
    MODIFY lt_fieldcat FROM ls_fieldcat.
  ENDLOOP.
* Tabelle zum ALV schicken
  ls_layout-no_keyfix = 'X'.
  ls_layout-cwidth_opt = 'X'.
  ls_layout-sgl_clk_hd = 'X'.
  ls_layout-no_toolbar = 'X'.
  ls_layout-smalltitle = 'X'.
  ls_layout-grid_title = 'Anzahl änderbare Meldungen'.
  CALL METHOD gc_meld->set_table_for_first_display
    EXPORTING
      is_layout       = ls_layout
    CHANGING
      it_outtab       = gt_overview
      it_fieldcatalog = lt_fieldcat.

ENDFORM.                    " SHOW_ACTFORCHANGE
*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_CUST_area_ID  text
*      -->P_GV_STOERID  text
*      <--P_LT_TEXT  text
*----------------------------------------------------------------------*
FORM read_text  USING    pv_area TYPE tdid
                         pv_stoerid TYPE /msh/stoerid
                CHANGING pt_text TYPE ism_tline_tab.

  DATA: lv_name TYPE thead-tdname.

* Text lesen
  lv_name = pv_stoerid.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = pv_area
      language                = 'D'
      name                    = lv_name
      object                  = '/MSH/STOER'
    TABLES
      lines                   = pt_text
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
  CHECK sy-subrc = 0.

ENDFORM.                    " READ_TEXT
*&---------------------------------------------------------------------*
*&      Form  DELETE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0057   text
*----------------------------------------------------------------------*
FORM delete  USING pv_dynnr TYPE sy-dynnr.

  DATA: lv_answ(1) TYPE c,
        dref       TYPE REF TO data.

  FIELD-SYMBOLS: <fs_dyn> TYPE any.

* Datum muß in der Zukunft sein
  IF /msh/stoer_s_top-gueltigvon LT sy-datum.
    MESSAGE i015.
    CLEAR ok_0100.
    EXIT.
  ENDIF.

* Abfragen
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = 'Soll der Datensatz gelöscht werden?'
      text_button_1         = 'Ja'
      text_button_2         = 'Nein'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answ
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0 OR lv_answ NE '1'.
    CLEAR ok_0100.
    EXIT.
  ENDIF.

* Datensatz löschen
  CHECK NOT gv_stoerid IS INITIAL.
  DELETE FROM (gs_cust-area_dbtab) WHERE stoerid = gv_stoerid.

* DB-Update
  IF sy-subrc = 0.
    CLEAR ok_0100.
    COMMIT WORK.
* Tet löschen
    PERFORM delete_text USING pv_dynnr.
    MESSAGE s016 WITH gv_stoerid.
* Startscreen
    PERFORM back_to_start.
  ELSE.
    MESSAGE e009.
  ENDIF.
ENDFORM.                    " DELETE
*&---------------------------------------------------------------------*
*&      Form  DELETE_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_PV_DYNNR  text
*----------------------------------------------------------------------*
FORM delete_text  USING    pv_dynnr TYPE sy-dynnr.

  DATA: lv_name TYPE thead-tdname,
        lv_id   TYPE thead-tdid.

* Daten zuweisen
  lv_name = gv_stoerid.
  CASE pv_dynnr.
    WHEN '0210'.
      lv_id = 'DIG'.
    WHEN '0220'.
      lv_id = 'GPNR'.
    WHEN '0240'.
      lv_id = 'PROD'.
    WHEN '0230'.
      lv_id = 'LIEF'.
  ENDCASE.

* Text löschen
  CALL FUNCTION 'DELETE_TEXT'
    EXPORTING
      id        = lv_id
      language  = 'D'
      name      = lv_name
      object    = '/MSH/STOER'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc = 0.
    COMMIT WORK.
  ENDIF.

ENDFORM.                    " DELETE_TEXT
*&---------------------------------------------------------------------*
*&      Form  ASK_LOSS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ask_loss .

  DATA: lv_answ(1) TYPE c.

  CHECK gv_changemode IS INITIAL.
  CHECK gv_openforedit = 'X'.
  CHECK NOT ok_0100 IS INITIAL.
  CHECK ok_0100 NS 'SAV'.
  CHECK ok_0100 NS 'CHK'.
  CHECK ok_0100 NS 'DEL'.
  CHECK ok_0100 NS 'SNEW'.
* Abfrage
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = 'Daten gehen verloren. Fortsetzen?'
      text_button_1         = 'Ja'
      text_button_2         = 'Nein'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answ
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  CHECK sy-subrc NE 0 OR lv_answ EQ '2'.
  CLEAR ok_0100.

ENDFORM.                    " ASK_LOSS
*&---------------------------------------------------------------------*
*&      Form  GET_FVART
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_fvart .

  DATA: lt_chose TYPE TABLE OF spopli,
        ls_chose TYPE spopli.

  REFRESH lt_chose[].

* ZUSTELLUNG:
* DRERZ UND PVA UND LIEFERART UND ( BEZIRK oder ROUTE oder (ABLADESTELLE UND ROUTE )) UND LIEFERRUNDE
  IF gv_lfartlog = 'X'.
    IF NOT /msh/stoer_s_lief-drerz IS INITIAL
       AND NOT /msh/stoer_s_lief-pva IS INITIAL
       AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL
       AND NOT /msh/stoer_s_lief-bezrunde IS INITIAL
       AND NOT ( /msh/stoer_s_lief-bezirk IS INITIAL AND /msh/stoer_s_lief-route IS INITIAL AND /msh/stoer_s_lief-beablst IS INITIAL ).
      ls_chose-varoption = 'Zustellung'.
      APPEND ls_chose TO lt_chose.

* LIEFERRUNDE:
* LIEFERRUNDE UND BEZIRK
    ELSEIF NOT /msh/stoer_s_lief-bezrunde IS INITIAL
           AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL
           AND NOT /msh/stoer_s_lief-bezirk IS INITIAL.
      ls_chose-varoption = 'Lieferrunde'.
      APPEND ls_chose TO lt_chose.

* BEZIRK:
* BEZIRK oder ROUTE oder ( ABLADESTELLE und ROUTE )
    ELSEIF ( NOT /msh/stoer_s_lief-bezirk IS INITIAL OR NOT ( /msh/stoer_s_lief-beablst IS INITIAL AND /msh/stoer_s_lief-route IS INITIAL ) )
        AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL.
      ls_chose-varoption = 'Bezirk'.
      APPEND ls_chose TO lt_chose.

* PVA:
* DRERZ UND PVA
    ELSEIF ( NOT /msh/stoer_s_lief-drerz IS INITIAL
           AND NOT /msh/stoer_s_lief-pva IS INITIAL
           AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL ) OR gv_lfartlog IS INITIAL.
      ls_chose-varoption = 'PVA oder nicht zustellrelevant'.
      APPEND ls_chose TO lt_chose.
    ENDIF.
  ELSE.
    IF ( NOT /msh/stoer_s_lief-drerz IS INITIAL
           AND NOT /msh/stoer_s_lief-pva IS INITIAL
           AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL ) OR gv_lfartlog IS INITIAL.
      ls_chose-varoption = 'PVA oder nicht zustellrelevant'.
      APPEND ls_chose TO lt_chose.
    ENDIF.
  ENDIF.
* Erstmal kann LT_CHOSE nur einen Eintrag haben, ggf. späterer Ausbau
  IF lt_chose[] IS INITIAL.
    MESSAGE e019.
  ELSE.
    READ TABLE lt_chose INTO ls_chose INDEX 1.
    CASE ls_chose-varoption.
      WHEN 'Zustellung'.
        /msh/stoer_s_lief-fvart = con_fvart_zustellung.
        gv_stoertext = ls_chose-varoption.
      WHEN 'Bezirk'.
        /msh/stoer_s_lief-fvart = con_fvart_bezirk.
        gv_stoertext = ls_chose-varoption.
      WHEN 'Lieferrunde'.
        /msh/stoer_s_lief-fvart = con_fvart_bezrunde.
        gv_stoertext = ls_chose-varoption.
      WHEN 'PVA oder nicht zustellrelevant'.
        /msh/stoer_s_lief-fvart = con_fvart_pva.
        gv_stoertext = ls_chose-varoption.
    ENDCASE.
  ENDIF.
ENDFORM.                    " GET_FVART
*&---------------------------------------------------------------------*
*&      Form  CHECK_CONST_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_const_0230 CHANGING es_bezirk TYPE ty_bezirk.

  DATA: lv_checkdate  TYPE dats,
        lv_idx        TYPE i,
        lv_targetdate TYPE dats.

* Für's Protokoll
  DATA: ls_log_handle TYPE balloghndl,
        lv_extnumber  TYPE bal_s_log-extnumber,
        ls_message    TYPE string,
        lv_cnt        TYPE i,
        ls_tjv42      TYPE tjv42,
        lv_notfound   TYPE xfeld,
        ls_jdtvausgb  TYPE jdtvausgb.

  DATA: xrjv4101    LIKE rjv4101.
  DATA: fvtab       LIKE STANDARD TABLE OF jvtfehler WITH DEFAULT KEY.
  DATA: feld_typ(1) TYPE c.
  DATA: entries     TYPE i.

  RANGES:
        r_bezirk FOR jvtbezirk-bezirk,
        r_drerz FOR jdtdrer-drerz,
        r_pva FOR jdtpva-pva,
        r_lieferart FOR jrtablg-lfartlog,
        r_bezrunde FOR jrtablg-bezrundtat,
        r_route FOR jvtfehler-route.

  FIELD-SYMBOLS: <poi> TYPE any.


* Fehlerart muß passen
  CHECK NOT /msh/stoer_s_lief-fvart IS INITIAL.
  IF /msh/stoer_s_lief-fvart EQ con_fvart_bezirk OR /msh/stoer_s_lief-fvart EQ con_fvart_zustellung
        OR /msh/stoer_s_lief-fvart EQ con_fvart_bezrunde.

* In der Zukunft Ranges und Bezirk füllen
    IF /msh/stoer_s_top-gueltigvon GT sy-datum.
      lv_checkdate = sy-datum.

*Route prüfen
      IF NOT /msh/stoer_s_lief-route IS INITIAL.
        sy-subrc = 4.
        WHILE sy-subrc NE 0.
          SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = /msh/stoer_s_lief-route AND dispodat = lv_checkdate.
          IF sy-subrc NE 0.
            lv_checkdate = lv_checkdate - 1.
          ENDIF.
        ENDWHILE.
      ENDIF.

* Ranges aufbauen
      REFRESH: r_bezirk[], r_drerz[], r_pva[], r_lieferart[], r_bezrunde[], r_route[].
      IF NOT /msh/stoer_s_lief-drerz IS INITIAL.
        r_drerz-sign = 'I'.
        r_drerz-option = 'EQ'.
        r_drerz-low = /msh/stoer_s_lief-drerz.
        APPEND r_drerz.
      ENDIF.
      IF NOT /msh/stoer_s_lief-pva IS INITIAL.
        r_pva-sign = 'I'.
        r_pva-option = 'EQ'.
        r_pva-low = /msh/stoer_s_lief-pva.
        APPEND r_pva.
      ENDIF.
      IF NOT /msh/stoer_s_lief-lfartlog IS INITIAL.
        r_lieferart-sign = 'I'.
        r_lieferart-option = 'EQ'.
        r_lieferart-low = /msh/stoer_s_lief-lfartlog.
        APPEND r_lieferart.
      ENDIF.
      IF NOT /msh/stoer_s_lief-bezrunde IS INITIAL.
        r_bezrunde-sign = 'I'.
        r_bezrunde-option = 'EQ'.
        r_bezrunde-low = /msh/stoer_s_lief-bezrunde.
        APPEND r_bezrunde.
      ENDIF.
      IF NOT /msh/stoer_s_lief-route IS INITIAL.
        r_route-sign = 'I'.
        r_route-option = 'EQ'.
        r_route-low = /msh/stoer_s_lief-route.
        APPEND r_route.
      ENDIF.
      IF NOT /msh/stoer_s_lief-bezirk IS INITIAL.
        r_bezirk-sign = 'I'.
        r_bezirk-option = 'EQ'.
        r_bezirk-low = /msh/stoer_s_lief-bezirk.
        APPEND r_bezirk.
      ENDIF.
* Selektion je nach Fall
      CASE /msh/stoer_s_lief-fvart.
        WHEN con_fvart_bezirk.      "Bezirk
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
          INTO TABLE gt_bezirk
          FROM jrtablg
         WHERE route      IN r_route
           AND versanddat EQ lv_checkdate
           AND lfartlog   IN r_lieferart
           AND bezirktat  IN r_bezirk.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_zustellung.  "Zustellung
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                  FROM jrtablg
                 WHERE route      IN r_route
                   AND versanddat EQ lv_checkdate
                   AND lfartlog   IN r_lieferart
                   AND bezirktat  IN r_bezirk
                   AND pvatat     IN r_pva
                   AND drerztat   IN r_drerz.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_bezrunde. "Lieferrunde
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                FROM jrtablg
               WHERE versanddat EQ lv_checkdate
                 AND lfartlog   IN r_lieferart
                 AND bezirktat  IN r_bezirk
                 AND bezrundtat IN r_bezrunde.
          IF NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY bezirktat lfartlog.
            DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
          ENDIF.
      ENDCASE.
      IF NOT gt_bezirk[] IS INITIAL.
        READ TABLE gt_bezirk INTO es_bezirk INDEX 1.
      ENDIF.
      EXIT.
    ENDIF.
* Beginndatum heute oder in der Vergangenheit
    CHECK /msh/stoer_s_top-gueltigvon LE sy-datum.

* Message als Information
    MESSAGE i018.

* Bei Zustellung oder Bezirk muß bei Abladestelle auch eine Route angegeben werden
    IF /msh/stoer_s_lief-fvart EQ con_fvart_bezirk OR /msh/stoer_s_lief-fvart EQ con_fvart_zustellung.
      IF /msh/stoer_s_lief-bezirk IS INITIAL.
        IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND /msh/stoer_s_lief-route IS INITIAL.
          MESSAGE e020.
        ENDIF.
      ENDIF.
    ENDIF.

* Checkdatum (Versanddat) auf den Gültigkeitsbeginn der Meldung setzen
    lv_checkdate = /msh/stoer_s_top-gueltigvon.
    IF /msh/stoer_s_top-gueltigbis LT sy-datum.
      lv_targetdate = /msh/stoer_s_top-gueltigbis.
    ELSE.
      lv_targetdate = sy-datum.
    ENDIF.

* Ranges aufbauen
    REFRESH: r_bezirk[], r_drerz[], r_pva[], r_lieferart[], r_bezrunde[], r_route[].
    IF NOT /msh/stoer_s_lief-drerz IS INITIAL.
      r_drerz-sign = 'I'.
      r_drerz-option = 'EQ'.
      r_drerz-low = /msh/stoer_s_lief-drerz.
      APPEND r_drerz.
    ENDIF.
    IF NOT /msh/stoer_s_lief-pva IS INITIAL.
      r_pva-sign = 'I'.
      r_pva-option = 'EQ'.
      r_pva-low = /msh/stoer_s_lief-pva.
      APPEND r_pva.
    ENDIF.
    IF NOT /msh/stoer_s_lief-lfartlog IS INITIAL.
      r_lieferart-sign = 'I'.
      r_lieferart-option = 'EQ'.
      r_lieferart-low = /msh/stoer_s_lief-lfartlog.
      APPEND r_lieferart.
    ENDIF.
    IF NOT /msh/stoer_s_lief-bezrunde IS INITIAL.
      r_bezrunde-sign = 'I'.
      r_bezrunde-option = 'EQ'.
      r_bezrunde-low = /msh/stoer_s_lief-bezrunde.
      APPEND r_bezrunde.
    ENDIF.
    IF NOT /msh/stoer_s_lief-route IS INITIAL.
      r_route-sign = 'I'.
      r_route-option = 'EQ'.
      r_route-low = /msh/stoer_s_lief-route.
      APPEND r_route.
    ENDIF.
    IF NOT /msh/stoer_s_lief-bezirk IS INITIAL.
      r_bezirk-sign = 'I'.
      r_bezirk-option = 'EQ'.
      r_bezirk-low = /msh/stoer_s_lief-bezirk.
      APPEND r_bezirk.
    ENDIF.

* Message-Objekt anlegen
    PERFORM log_create USING '/MSH/STOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.

* Meldung für Störungsart initialisieren
    SELECT SINGLE * FROM tjv42 INTO ls_tjv42 WHERE spras EQ sy-langu AND fvart EQ /msh/stoer_s_lief-fvart.
    MESSAGE i025 WITH ls_tjv42-langtext INTO ls_message.
    PERFORM msg_add_handle USING probclass_none
                                 ls_log_handle.

* Im Änderungsmodus werden die Prüfungen nicht weiter durchlaufen
    IF gv_changemode EQ 'X'.
      MESSAGE i038 INTO ls_message.
      PERFORM msg_add_handle USING probclass_none
                                   ls_log_handle.
* Log ausgeben
      IF con_no_display_popop EQ abap_false.
        PERFORM log_display_popup USING ls_log_handle.
      ENDIF.
* Log löschen
      CALL FUNCTION 'BAL_LOG_REFRESH'
        EXPORTING
          i_log_handle  = ls_log_handle
        EXCEPTIONS
          log_not_found = 1
          OTHERS        = 2.
      lv_checkdate = sy-datum.

*Route prüfen
      IF NOT /msh/stoer_s_lief-route IS INITIAL.
        sy-subrc = 4.
        WHILE sy-subrc NE 0.
          SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = /msh/stoer_s_lief-route AND dispodat = lv_checkdate.
          IF sy-subrc NE 0.
            lv_checkdate = lv_checkdate - 1.
          ENDIF.
        ENDWHILE.
      ENDIF.

* Ranges aufbauen
      REFRESH: r_bezirk[], r_drerz[], r_pva[], r_lieferart[], r_bezrunde[], r_route[].
      IF NOT /msh/stoer_s_lief-drerz IS INITIAL.
        r_drerz-sign = 'I'.
        r_drerz-option = 'EQ'.
        r_drerz-low = /msh/stoer_s_lief-drerz.
        APPEND r_drerz.
      ENDIF.
      IF NOT /msh/stoer_s_lief-pva IS INITIAL.
        r_pva-sign = 'I'.
        r_pva-option = 'EQ'.
        r_pva-low = /msh/stoer_s_lief-pva.
        APPEND r_pva.
      ENDIF.
      IF NOT /msh/stoer_s_lief-lfartlog IS INITIAL.
        r_lieferart-sign = 'I'.
        r_lieferart-option = 'EQ'.
        r_lieferart-low = /msh/stoer_s_lief-lfartlog.
        APPEND r_lieferart.
      ENDIF.
      IF NOT /msh/stoer_s_lief-bezrunde IS INITIAL.
        r_bezrunde-sign = 'I'.
        r_bezrunde-option = 'EQ'.
        r_bezrunde-low = /msh/stoer_s_lief-bezrunde.
        APPEND r_bezrunde.
      ENDIF.
      IF NOT /msh/stoer_s_lief-route IS INITIAL.
        r_route-sign = 'I'.
        r_route-option = 'EQ'.
        r_route-low = /msh/stoer_s_lief-route.
        APPEND r_route.
      ENDIF.
      IF NOT /msh/stoer_s_lief-bezirk IS INITIAL.
        r_bezirk-sign = 'I'.
        r_bezirk-option = 'EQ'.
        r_bezirk-low = /msh/stoer_s_lief-bezirk.
        APPEND r_bezirk.
      ENDIF.
* Selektion je nach Fall
      CASE /msh/stoer_s_lief-fvart.
        WHEN con_fvart_bezirk.      "Bezirk
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
          INTO TABLE gt_bezirk
          FROM jrtablg
         WHERE route      IN r_route
           AND versanddat EQ lv_checkdate
           AND lfartlog   IN r_lieferart
           AND bezirktat  IN r_bezirk.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_zustellung.  "Zustellung
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                  FROM jrtablg
                 WHERE route      IN r_route
                   AND versanddat EQ lv_checkdate
                   AND lfartlog   IN r_lieferart
                   AND bezirktat  IN r_bezirk
                   AND pvatat     IN r_pva
                   AND drerztat   IN r_drerz.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_bezrunde. "Lieferrunde
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                FROM jrtablg
               WHERE versanddat EQ lv_checkdate
                 AND lfartlog   IN r_lieferart
                 AND bezirktat  IN r_bezirk
                 AND bezrundtat IN r_bezrunde.
          IF NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY bezirktat lfartlog.
            DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
          ENDIF.
      ENDCASE.
      IF NOT gt_bezirk[] IS INITIAL.
        READ TABLE gt_bezirk INTO es_bezirk INDEX 1.
      ENDIF.
      EXIT.
    ENDIF.
* Anzulegende Bezirke initialisieren
    REFRESH gt_bezirk_cre[].

* Verarbeitung nur für die Datensatzanteile in der Vergangenheit
    WHILE lv_checkdate LE lv_targetdate.

* Beginn protokollieren
      MESSAGE i021 WITH lv_checkdate INTO ls_message.
      PERFORM msg_add_handle USING probclass_none
                                   ls_log_handle.

* Route prüfen und Datum ggf. ignorieren
      IF NOT /msh/stoer_s_lief-route IS INITIAL.
        SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = /msh/stoer_s_lief-route AND dispodat = lv_checkdate.
        IF sy-subrc NE 0.
          lv_checkdate = lv_checkdate + 1.
          CONTINUE.
        ENDIF.
      ENDIF.

* Keine Prüfungen bei nicht logistisch relevanter Lieferart
      IF gv_lfartlog NE 'X'.
* Keine Prüfung
        MESSAGE i030 WITH /msh/stoer_s_lief-lfartlog INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
* Log ausgeben
        IF con_no_display_popop EQ abap_false.
          PERFORM log_display_popup USING ls_log_handle.
        ENDIF.
* Log löschen
        CALL FUNCTION 'BAL_LOG_REFRESH'
          EXPORTING
            i_log_handle  = ls_log_handle
          EXCEPTIONS
            log_not_found = 1
            OTHERS        = 2.
        EXIT.
      ENDIF.

* Einen Bezirk braucht es auf jeden Fall (mindestens), wenn nicht angegeben, wird dieser aus den anderen
* Daten ermittelt

      REFRESH: gt_bezirk[], gt_jdtvausgb[].
      CLEAR lv_notfound.

* Selektion je nach Fall
      CASE /msh/stoer_s_lief-fvart.
        WHEN con_fvart_bezirk.      "Bezirk
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
          INTO TABLE gt_bezirk
          FROM jrtablg
         WHERE route      IN r_route
           AND versanddat EQ lv_checkdate
           AND lfartlog   IN r_lieferart
           AND bezirktat  IN r_bezirk.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_zustellung.  "Zustellung
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                  FROM jrtablg
                 WHERE route      IN r_route
                   AND versanddat EQ lv_checkdate
                   AND lfartlog   IN r_lieferart
                   AND bezirktat  IN r_bezirk
                   AND pvatat     IN r_pva
                   AND drerztat   IN r_drerz.
          IF NOT /msh/stoer_s_lief-beablst IS INITIAL AND NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY route numbeablst.
            READ TABLE gt_bezirk WITH KEY beablst = /msh/stoer_s_lief-beablst
                                 TRANSPORTING NO FIELDS.
            IF sy-tabix NE 1.
              lv_idx = sy-tabix - 1.
            ELSE.
              lv_idx = sy-tabix.
            ENDIF.
            DELETE gt_bezirk FROM 1 TO lv_idx.
          ENDIF.
          SORT gt_bezirk BY bezirktat lfartlog.
          DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
        WHEN con_fvart_bezrunde. "Lieferrunde
          SELECT route numbeablst bezirktat beablst lfartlog bezrundtat versanddat
                INTO TABLE gt_bezirk
                FROM jrtablg
               WHERE versanddat EQ lv_checkdate
                 AND lfartlog   IN r_lieferart
                 AND bezirktat  IN r_bezirk
                 AND bezrundtat IN r_bezrunde.
          IF NOT gt_bezirk[] IS INITIAL.
            SORT gt_bezirk BY bezirktat lfartlog.
            DELETE ADJACENT DUPLICATES FROM gt_bezirk COMPARING bezirktat lfartlog.
          ENDIF.
      ENDCASE.

* Wenn wir keine Bezirkstabelle haben, dann ist irgendetwas falsch
      IF gt_bezirk[] IS INITIAL.
        MESSAGE e022 WITH lv_checkdate INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
        lv_notfound = 'X'.
      ELSE.
        lv_cnt = lines( gt_bezirk ).
        MESSAGE i023 WITH lv_checkdate lv_cnt INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                               ls_log_handle.
      ENDIF.

* Gibt es schon eine entsprechende Meldung für den Versandtag und den Bezirk?
      REFRESH gt_jvtfehler_exist[].
      LOOP AT gt_bezirk INTO gs_bezirk.
        IF es_bezirk IS INITIAL.
          es_bezirk = gs_bezirk.
        ENDIF.
        CLEAR xrjv4101.
        xrjv4101-fvart      = /msh/stoer_s_lief-fvart.
        xrjv4101-vtweg      = /msh/stoer_s_lief-vtweg.
        xrjv4101-vkorg      = /msh/stoer_s_lief-vkorg.
        xrjv4101-lfartlog   = /msh/stoer_s_lief-lfartlog.
        xrjv4101-druckerei  = /msh/stoer_s_lief-druckerei.
        xrjv4101-drerz      = /msh/stoer_s_lief-drerz.
        xrjv4101-pva        = /msh/stoer_s_lief-pva.
        xrjv4101-bezirk     = gs_bezirk-bezirktat.
        xrjv4101-bezrunde   = /msh/stoer_s_lief-bezrunde.
        xrjv4101-vrsnddatum = lv_checkdate.
        DO.
          ASSIGN COMPONENT sy-index OF STRUCTURE xrjv4101 TO <poi>.
          IF sy-subrc NE 0. EXIT. ENDIF.
          DESCRIBE FIELD <poi> TYPE feld_typ.
          IF ( feld_typ = 'C'   ) AND
             ( <poi> IS INITIAL ).
            <poi> = con_maske_stern.
          ENDIF.
        ENDDO.
        REFRESH fvtab[].
        CALL FUNCTION 'ISP_JVTFEHLER_READ'
          EXPORTING
            selektion = xrjv4101
          TABLES
            fvselect  = fvtab.
        IF lines( fvtab ) GT 0.
          gv_exist = 'X'.
          MESSAGE e024 WITH lv_checkdate gs_bezirk-bezirktat INTO ls_message.
          PERFORM msg_add_handle USING probclass_high
                                       ls_log_handle.
          APPEND LINES OF fvtab TO gt_jvtfehler_exist.    "Für spätere Anzeige der bestehenden Meldungen
          APPEND gs_bezirk TO gt_bezirk_cre.
        ELSE.
* Datensatz wird angefügt
          APPEND gs_bezirk TO gt_bezirk_cre.
        ENDIF.
      ENDLOOP.

* Letztendlich Datum um einen Tag hochsetzen
      lv_checkdate = lv_checkdate + 1.
    ENDWHILE.

* Infomeldung wenn Ende in der Zukunft
    lv_targetdate = lv_targetdate + 1.
    IF /msh/stoer_s_top-gueltigbis GE lv_targetdate.
      MESSAGE i028 WITH lv_targetdate /msh/stoer_s_top-gueltigbis INTO ls_message.
      PERFORM msg_add_handle USING probclass_none
                                   ls_log_handle.
    ENDIF.

* Log ausgeben
    IF con_no_display_popop EQ abap_false.
      PERFORM log_display_popup USING ls_log_handle.
    ENDIF.

* Log löschen
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.

* Message ggf. ausgeben
    IF lv_notfound EQ 'X' AND es_bezirk IS INITIAL.
      MESSAGE e026.
    ENDIF.
  ELSE.
    CHECK /msh/stoer_s_lief-fvart EQ con_fvart_pva.

* Bei PVA nur die ET gegen den Zeitraum prüfen

* Beginndatum heute oder in der Vergangenheit
    CHECK /msh/stoer_s_top-gueltigvon LE sy-datum.
* Message als Information
    MESSAGE i018.
* Checkdatum (Versanddat) auf den Gültigkeitsbeginn der Meldung setzen
    lv_checkdate = /msh/stoer_s_top-gueltigvon.
    IF /msh/stoer_s_top-gueltigbis LT sy-datum.
      lv_targetdate = /msh/stoer_s_top-gueltigbis.
    ELSE.
      lv_targetdate = sy-datum.
    ENDIF.
* Message-Objekt anlegen
    PERFORM log_create USING '/MSH/STOER' "in SLG0 angelegt
                             space
                             lv_extnumber
                    CHANGING ls_log_handle.
* Meldung für Störungsart initialisieren
    SELECT SINGLE * FROM tjv42 INTO ls_tjv42 WHERE spras EQ sy-langu AND fvart EQ /msh/stoer_s_lief-fvart.
    MESSAGE i025 WITH ls_tjv42-langtext INTO ls_message.
    PERFORM msg_add_handle USING probclass_none
                                 ls_log_handle.
* Verarbeitung nur für die Datensatzanteile in der Vergangenheit
    WHILE lv_checkdate LE lv_targetdate.
      SELECT SINGLE * FROM jdtvausgb INTO ls_jdtvausgb WHERE drerz = /msh/stoer_s_lief-drerz
                                              AND pva = /msh/stoer_s_lief-pva
                                              AND erschdat = lv_checkdate.
      IF sy-subrc NE 0 AND gv_lfartlog = 'X'.
        MESSAGE e029 WITH /msh/stoer_s_lief-pva /msh/stoer_s_lief-drerz lv_checkdate INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
        lv_checkdate = lv_checkdate + 1.
        CONTINUE.
      ELSE.
        MESSAGE i034 WITH /msh/stoer_s_lief-pva /msh/stoer_s_lief-drerz lv_checkdate INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
      ENDIF.

* Im Änderungsmodus werden die Prüfungen nicht weiter durchlaufen
      IF gv_changemode EQ 'X'.
        MESSAGE i038 INTO ls_message.
        PERFORM msg_add_handle USING probclass_none
                                     ls_log_handle.
* Log ausgeben
        IF con_no_display_popop EQ abap_false.
          PERFORM log_display_popup USING ls_log_handle.
        ENDIF.
* Log löschen
        CALL FUNCTION 'BAL_LOG_REFRESH'
          EXPORTING
            i_log_handle  = ls_log_handle
          EXCEPTIONS
            log_not_found = 1
            OTHERS        = 2.
        EXIT.
      ENDIF.

* Prüfung auf doppelte Meldung
      CLEAR xrjv4101.
      xrjv4101-fvart      = /msh/stoer_s_lief-fvart.
      xrjv4101-vtweg      = /msh/stoer_s_lief-vtweg.
      xrjv4101-vkorg      = /msh/stoer_s_lief-vkorg.
      xrjv4101-lfartlog   = /msh/stoer_s_lief-lfartlog.
      xrjv4101-drerz      = /msh/stoer_s_lief-drerz.
      xrjv4101-pva        = /msh/stoer_s_lief-pva.
      xrjv4101-vrsnddatum = lv_checkdate.
      DO.
        ASSIGN COMPONENT sy-index OF STRUCTURE xrjv4101 TO <poi>.
        IF sy-subrc NE 0. EXIT. ENDIF.
        DESCRIBE FIELD <poi> TYPE feld_typ.
        IF ( feld_typ = 'C'   ) AND
           ( <poi> IS INITIAL ).
          <poi> = con_maske_stern.
        ENDIF.
      ENDDO.
      REFRESH fvtab[].
      CALL FUNCTION 'ISP_JVTFEHLER_READ'
        EXPORTING
          selektion = xrjv4101
        TABLES
          fvselect  = fvtab.
      IF lines( fvtab ) GT 0.
        gv_exist = 'X'.
        MESSAGE e037 WITH lv_checkdate /msh/stoer_s_lief-drerz /msh/stoer_s_lief-pva INTO ls_message.
        PERFORM msg_add_handle USING probclass_high
                                     ls_log_handle.
        APPEND LINES OF fvtab TO gt_jvtfehler_exist.    "Für spätere Anzeige der bestehenden Meldungen
      ENDIF.
* Satz anhängen
      APPEND ls_jdtvausgb TO gt_jdtvausgb.
* Letztendlich Datum um einen Tag hochsetzen
      lv_checkdate = lv_checkdate + 1.
    ENDWHILE.
* Infomeldung wenn Ende in der Zukunft
    lv_targetdate = lv_targetdate + 1.
    IF /msh/stoer_s_top-gueltigbis GE lv_targetdate.
      MESSAGE i028 WITH lv_targetdate /msh/stoer_s_top-gueltigbis INTO ls_message.
      PERFORM msg_add_handle USING probclass_none
                                   ls_log_handle.
    ENDIF.
* Log ausgeben
    IF con_no_display_popop EQ abap_false.
      PERFORM log_display_popup USING ls_log_handle.
    ENDIF.
* Log löschen
    CALL FUNCTION 'BAL_LOG_REFRESH'
      EXPORTING
        i_log_handle  = ls_log_handle
      EXCEPTIONS
        log_not_found = 1
        OTHERS        = 2.
  ENDIF.
ENDFORM.                    " CHECK_CONST_0230
*&---------------------------------------------------------------------*
*&      Form  SAVE_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_0230 .

  DATA: lv_error TYPE xfeld.

* Abfrage
  CLEAR lv_error.
  PERFORM ask_save CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    EXIT.
  ENDIF.

* Sicherungsroutine je nach ermittelter Fehlerart
  CASE /msh/stoer_s_lief-fvart.
    WHEN con_fvart_bezirk.
      PERFORM save_230_bezirk.
    WHEN con_fvart_zustellung.
      PERFORM save_230_zustellung.
    WHEN con_fvart_bezrunde.
      PERFORM save_230_bezrunde.
    WHEN con_fvart_pva.
      PERFORM save_230_pva.
  ENDCASE.
ENDFORM.                    " SAVE_0230
