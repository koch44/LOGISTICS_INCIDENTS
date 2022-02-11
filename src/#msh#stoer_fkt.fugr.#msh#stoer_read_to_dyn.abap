FUNCTION /MSH/STOER_READ_TO_DYN.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_GPNR) TYPE  GPNR
*"----------------------------------------------------------------------

DATA: lcl_hist TYPE REF TO /MSH/CL_STOER_HELPER,
        lcl_akt  TYPE REF TO /MSH/CL_STOER_HELPER.
  DATA: lt_child_tab   TYPE TABLE OF isu_badi_cic_env,
        ls_child       TYPE isu_badi_cic_env,
        lv_nr_of_lines TYPE i.
  DATA: lt_messages TYPE /MSH/CL_STOER_HELPER=>tt_msg,
        lv_message  TYPE /MSH/CL_STOER_HELPER=>ty_msg.

  DATA: lt_lief       TYPE TABLE OF /msh/stoer_t_lf,
        lt_dig        TYPE TABLE OF /msh/stoer_t_dig,
        lt_gp         TYPE TABLE OF /msh/stoer_t_gp,
        lt_prod       TYPE TABLE OF /msh/stoer_t_prd,
        lt_lief_hist  TYPE TABLE OF /msh/stoer_t_lf,
        lt_dig_hist   TYPE TABLE OF /msh/stoer_t_dig,
        lt_gp_hist    TYPE TABLE OF /msh/stoer_t_gp,
        lt_prod_hist  TYPE TABLE OF /msh/stoer_t_prd,
        lv_datvon(10) TYPE c,
        lv_datbis(10) TYPE c,
        lv_datakt(10) TYPE c,
        lv_areaid     TYPE /msh/stoer_area_id,
        lv_help       TYPE char4,
        lt_item       TYPE rjycic_msditemdatatab,
        ls_item       LIKE LINE OF lt_item,
        lv_found      TYPE abap_bool.

  FIELD-SYMBOLS: <fs_lief> LIKE LINE OF lt_lief,
                 <fs_prod> LIKE LINE OF lt_prod,
                 <fs_gp>   LIKE LINE OF lt_gp,
                 <fs_dig>  LIKE LINE OF lt_dig,
                 <fs_hist> LIKE LINE OF gt_hist.

  REFRESH: gt_hist[], gt_akt[].

* Historische Vertriebsstörungen lesen
  CREATE OBJECT lcl_hist
    EXPORTING
      li_gpnr     = iv_gpnr
      li_akttage  = 1
      li_histtage = 366.
  lt_child_tab = lcl_hist->ermittle_stoerungen_cic( ).
  SORT lt_child_tab BY text3 DESCENDING.
  LOOP AT lt_child_tab INTO ls_child.
    CLEAR gs_hist.
    gs_hist-key = ls_child-key.
    gs_hist-icon = icon_alert.
    gs_hist-text1 = ls_child-text1.
    gs_hist-text2 = ls_child-text2.
    APPEND gs_hist TO gt_hist.
  ENDLOOP.

* Aktuelle Vertriebsstörungen lesen
  CREATE OBJECT lcl_akt
    EXPORTING
      li_gpnr     = iv_gpnr
      li_akttage  = 0
      li_histtage = 0.
  lt_child_tab = lcl_akt->ermittle_stoerungen_cic( ).
  LOOP AT lt_child_tab INTO ls_child.
    CLEAR gs_akt.
    gs_akt-key = ls_child-key.
    gs_akt-icon = icon_alert.
    gs_akt-text1 = ls_child-text1.
    gs_akt-text2 = ls_child-text2.
    APPEND gs_akt TO gt_akt.
  ENDLOOP.

* Z-Tabellen der Störungsmeldungen selektieren
  CALL FUNCTION '/MSH/STOER_AKT_READ'
    EXPORTING
      iv_gpnr  = iv_gpnr
      iv_class = lcl_akt
    IMPORTING
      et_item  = lt_item
    TABLES
      et_lief  = lt_lief
      et_prod  = lt_prod
      et_gp    = lt_gp
      et_dig   = lt_dig.

* Z-Tabellen der Störungsmeldungen selektieren
  CALL FUNCTION '/MSH/STOER_HIST_READ'
    EXPORTING
      iv_gpnr  = iv_gpnr
      iv_class = lcl_hist
    TABLES
      et_lief  = lt_lief_hist
      et_prod  = lt_prod_hist
      et_gp    = lt_gp_hist
      et_dig   = lt_dig_hist.

*Tagedatum konvertieren
  CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
    EXPORTING
      date_internal            = sy-datum
    IMPORTING
      date_external            = lv_datakt
    EXCEPTIONS
      date_internal_is_invalid = 1
      OTHERS                   = 2.

* Aus den ITABS ggf. zusätzliche aufbauen
*-> /msh/stoer_t_lf
  CLEAR lv_areaid.
  SELECT SINGLE area_id FROM /msh/stoer_t_cst INTO lv_areaid WHERE area_dbtab = '/MSH/STOER_T_LF'.
  LOOP AT lt_lief ASSIGNING <fs_lief>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_lief>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_lief>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid <fs_lief>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datakt '-' <fs_lief>-fvgrund '-' <fs_lief>-bezirk INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Lieferstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_akt.
  ENDLOOP.
  LOOP AT lt_lief_hist ASSIGNING <fs_lief>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_lief>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_lief>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid <fs_lief>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datvon '-' <fs_lief>-fvgrund '-' <fs_lief>-bezirk INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Lieferstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_hist.
  ENDLOOP.

*-> ZJKT_STOER_GP
  CLEAR lv_areaid.
  SELECT SINGLE area_id FROM /msh/stoer_t_cst INTO lv_areaid WHERE area_dbtab = '/MSH/STOER_T_GP'.
  LOOP AT lt_gp ASSIGNING <fs_gp>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_gp>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_gp>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_gp>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datakt '-' <fs_gp>-fvgrund '-' <fs_gp>-drerz '/' <fs_gp>-pva INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Kundenstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_akt.
  ENDLOOP.
  LOOP AT lt_gp_hist ASSIGNING <fs_gp>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_gp>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_gp>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_gp>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datvon '-' <fs_gp>-fvgrund '-' <fs_gp>-drerz '/' <fs_gp>-pva INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Kundenstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_hist.
  ENDLOOP.

*-> ZJKT_STOER_PROD
  CLEAR lv_areaid.
  SELECT SINGLE area_id FROM /msh/stoer_t_cst INTO lv_areaid WHERE area_dbtab = '/MSH/STOER_T_PRD'.
  LOOP AT lt_prod ASSIGNING <fs_prod>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_prod>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_prod>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_prod>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datakt '-' <fs_prod>-fvgrund '-' <fs_prod>-drerz_prod '/' <fs_prod>-pva_prod  INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Produktionsstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_akt.
  ENDLOOP.
  LOOP AT lt_prod_hist ASSIGNING <fs_prod>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_prod>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_prod>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_prod>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datvon '-' <fs_prod>-fvgrund '-' <fs_prod>-drerz_prod '/' <fs_prod>-pva_prod  INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Produktionsstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_hist.
  ENDLOOP.

*-> ZJKT_STOER_PROD
  CLEAR lv_areaid.
  SELECT SINGLE area_id FROM /msh/stoer_t_cst INTO lv_areaid WHERE area_dbtab = '/MSH/STOER_T_DIG'.
  LOOP AT lt_dig ASSIGNING <fs_dig>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_dig>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_dig>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_dig>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datakt '-' <fs_dig>-fvgrund '-' <fs_dig>-drerz_dig '/' <fs_dig>-pva_dig INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Digitalstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_akt.
  ENDLOOP.
  LOOP AT lt_dig_hist ASSIGNING <fs_dig>.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_dig>-gueltigvon
      IMPORTING
        date_external            = lv_datvon
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
      EXPORTING
        date_internal            = <fs_dig>-gueltigbis
      IMPORTING
        date_external            = lv_datbis
      EXCEPTIONS
        date_internal_is_invalid = 1
        OTHERS                   = 2.
    CLEAR gs_akt.
    CONCATENATE lv_areaid  <fs_dig>-stoerid INTO gs_akt-key.
    gs_akt-icon = icon_alert.
    CONCATENATE lv_datvon '-' <fs_dig>-fvgrund '-' <fs_dig>-drerz_dig '/' <fs_dig>-pva_dig INTO gs_akt-text1 RESPECTING BLANKS.
    CONCATENATE 'Digitalstörung von' lv_datvon '-' lv_datbis INTO gs_akt-text2 SEPARATED BY space.
    APPEND gs_akt TO gt_hist.
  ENDLOOP.

  LOOP AT gt_hist ASSIGNING <fs_hist>.
    lv_datbis = <fs_hist>-text1(10).
    lv_help = lv_datbis+6(4).
    IF lv_help CA '-ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
      CONCATENATE '20' lv_help(2) INTO lv_help.
      lv_datbis+6(4) = lv_help.
    ENDIF.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external            = lv_datbis
      IMPORTING
        date_internal            = <fs_hist>-sortdat
      EXCEPTIONS
        date_external_is_invalid = 1
        OTHERS                   = 2.
  ENDLOOP.
  SORT gt_hist BY sortdat DESCENDING.
  LOOP AT gt_akt ASSIGNING <fs_hist>.
    lv_datbis = <fs_hist>-text1(10).
    lv_help = lv_datbis+6(4).
    IF lv_help CA '-ABCDEFGHIJKLMNOPQRSTUVWXYZ'.
      CONCATENATE '20' lv_help(2) INTO lv_help.
      lv_datbis+6(4) = lv_help.
    ENDIF.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external            = lv_datbis
      IMPORTING
        date_internal            = <fs_hist>-sortdat
      EXCEPTIONS
        date_external_is_invalid = 1
        OTHERS                   = 2.
  ENDLOOP.
  SORT gt_akt BY sortdat DESCENDING.

  CLEAR lv_found.

  IF NOT lt_item[] IS INITIAL.
    LOOP AT lt_item INTO ls_item.
* Prüfung ob GPNR auch WE ist unter Einbezug der Auftragsnr und Zeitraum
      SELECT SINGLE COUNT(*)
        FROM jkpa
        WHERE vbeln = ls_item-vbeln
        AND   gueltigvon = ls_item-gueltigvon
        AND   gueltigbis = ls_item-gueltigbis
        AND   gpnr = iv_gpnr
        AND   jparvw = 'WE'.
      IF sy-subrc = 0.
        lv_found = abap_true.
      ELSE.
        SELECT SINGLE COUNT(*)
          FROM jkpa
          WHERE vbeln = ls_item-vbeln
          AND   gueltigvon = ls_item-gueltigvon
          AND   gpnr = iv_gpnr
          AND   jparvw = 'WE'.
        IF sy-subrc = 0.
          SELECT SINGLE COUNT(*)
          FROM jkpa
          WHERE vbeln = ls_item-vbeln
          AND   gueltigbis = ls_item-gueltigbis
          AND   gpnr = iv_gpnr
          AND   jparvw = 'WE'.
          IF sy-subrc = 0.
            lv_found = abap_true.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

* Wurde nichts gefunden, dann dürfen auch keine Meldungen angezeigt werden
    IF lv_found = abap_false.
      CLEAR: gt_akt[], gt_hist[].
    ENDIF.
  ENDIF.

* Aktuelle und historische Meldungen anhand Anlagedatum GP prüfen
  CALL METHOD lcl_akt->check_stoerungen
    EXPORTING
      iv_gpnr = iv_gpnr
      it_item = lt_item
    CHANGING
      ct_akt  = gt_akt
      ct_hist = gt_hist.

* Messages ausgeben
  IF NOT gt_akt[] IS INITIAL.
    CALL METHOD lcl_akt->hole_nachrichten
      EXPORTING
        it_item     = lt_item
      IMPORTING
        et_messages = lt_messages.
    CALL METHOD lcl_akt->check_nachrichten
      EXPORTING
        iv_gpnr     = iv_gpnr
        it_item     = lt_item
      CHANGING
        ct_messages = lt_messages.
    LOOP AT lt_messages INTO lv_message.
      CASE lv_message-state.
        WHEN /MSH/CL_STOER_HELPER=>cc_state_act_on.
          MESSAGE i108 WITH lv_message-time_as_string.
*         Achtung! Es liegt eine aktuelle, aktive Vertriebsstörung bis &1 vor.
        WHEN /MSH/CL_STOER_HELPER=>cc_state_act_off.
          MESSAGE i109 WITH lv_message-time_as_string.
*         Hinweis! Für den heutigen Tag lag eine Vertriebsstörung bis &1 vor.
        WHEN /MSH/CL_STOER_HELPER=>cc_state_act_onoff.
          MESSAGE i110.
*         Achtung!Hinweis! Es liegen Vertriebsstörung vor (Aktive und Behobene)
        WHEN lcl_akt->cc_state_act_on_without_time.
          MESSAGE i115.
*         Achtung! Es liegt eine aktuelle Vertriebsstörung für heute vor.
      ENDCASE.
    ENDLOOP.
  ENDIF.



ENDFUNCTION.
