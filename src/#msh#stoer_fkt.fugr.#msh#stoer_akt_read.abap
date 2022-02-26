FUNCTION /msh/stoer_akt_read.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_GPNR) TYPE  GPNR
*"     REFERENCE(IV_CLASS) TYPE REF TO  /MSH/CL_STOER_HELPER
*"  EXPORTING
*"     REFERENCE(ET_ITEM) TYPE  RJYCIC_MSDITEMDATATAB
*"  TABLES
*"      ET_LIEF STRUCTURE  /MSH/STOER_T_LF
*"      ET_PROD STRUCTURE  /MSH/STOER_T_PRD
*"      ET_GP STRUCTURE  /MSH/STOER_T_GP
*"      ET_DIG STRUCTURE  /MSH/STOER_T_DIG
*"----------------------------------------------------------------------

  DATA: lt_item  TYPE rjycic_msditemdatatab,
        lf_tabix TYPE sy-tabix.
  DATA: lr_bezirk   TYPE RANGE OF bezirk,
        lr_bezrunde TYPE RANGE OF bezrunde,
        lr_pva      TYPE RANGE OF pva,
        lr_drerz    TYPE RANGE OF drerz,
        lr_route    TYPE RANGE OF tagroute,
        ls_drerz    LIKE LINE OF lr_drerz,
        lv_plz      TYPE plz_isp,
        lr_lfart    TYPE RANGE OF lieferart,
        ls_lfart    LIKE LINE OF lr_lfart,
        lv_postleit TYPE /msh/postleit,
        ls_lief_sel TYPE /msh/stoer_t_lf,
        ls_search   TYPE rjycic_search.

  STATICS: lr_lfart_zust TYPE RANGE OF lieferart.

  FIELD-SYMBOLS: <fs_item>   TYPE rjycic_msditemdata,
                 <fs_parvw>  TYPE jparvw,
                 <fs_search> TYPE rjycic_search,
                 <fs_lief>   LIKE LINE OF et_lief,
                 <fs_prod>   LIKE LINE OF et_prod.

* Vorselektion
  IF lr_lfart_zust[] IS INITIAL.
    SELECT * FROM tjv01 INTO @DATA(ls_tjv01) WHERE xlaauftrag = 'X' AND xlalogist = 'X' AND xzustllung = 'X'.
      APPEND INITIAL LINE TO lr_lfart_zust ASSIGNING FIELD-SYMBOL(<fs_lr>).
      <fs_lr>-sign = 'I'.
      <fs_lr>-option = 'EQ'.
      <fs_lr>-low = ls_tjv01-lieferart.
    ENDSELECT.
  ENDIF.

* Daten holen
  CALL METHOD iv_class->export_liefdat
    IMPORTING
      er_bezirk   = lr_bezirk
      er_bezrunde = lr_bezrunde
      er_pva      = lr_pva
      er_route    = lr_route.

* Auftragsliste
  CALL FUNCTION 'ISM_CIC_MSDORDER_DATA_READ'
    EXPORTING
      gpnr    = iv_gpnr
      date    = sy-datum
    IMPORTING
      itemtab = et_item.
  lt_item[] = et_item[].

* Suchdaten (dirty) auslesen
  UNASSIGN <fs_search>.
  ASSIGN ('(SAPLJYCIC_SEARCH)RJYCIC_SEARCH') TO <fs_search>.
  IF NOT <fs_search> IS ASSIGNED.
    ASSIGN ls_search TO <fs_search>.
    SELECT SINGLE * FROM jgtsadr INTO CORRESPONDING FIELDS OF ls_search WHERE gp_ref = iv_gpnr.
  ENDIF.
  IF <fs_search> IS ASSIGNED AND NOT <fs_search>-hausn IS INITIAL.
    SHIFT <fs_search>-hausn LEFT DELETING LEADING space.
  ENDIF.
  IF <fs_search> IS ASSIGNED AND NOT <fs_search>-pstlz IS INITIAL.
    lv_plz =  <fs_search>-pstlz.
    SHIFT lv_plz LEFT DELETING LEADING space.
    lv_postleit = lv_plz(2).
  ENDIF.

  DATA(lt_help) = lt_item.

* Lieferart
  SORT lt_item BY lieferart ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_item COMPARING lieferart.
  LOOP AT lt_item ASSIGNING <fs_item>.
    READ TABLE <fs_item>-jparvwtab ASSIGNING FIELD-SYMBOL(<fs_check>) WITH KEY table_line = |WE|.
    CHECK sy-subrc = 0.
    ls_lfart-sign = 'I'.
    ls_lfart-option = 'EQ'.
    ls_lfart-low = <fs_item>-lieferart.
    APPEND ls_lfart TO lr_lfart.
    "Logistische Lieferart auch
    SELECT SINGLE lfartlog FROM tjv01 INTO ls_lfart-low WHERE lieferart = <fs_item>-lieferart AND lfartlog NE space.
    IF sy-subrc = 0.
      APPEND ls_lfart TO lr_lfart.
    ENDIF.
  ENDLOOP.

* DRERZ-Range aufbauen
  lt_item = lt_help.
  SORT lt_item BY drerz ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_item COMPARING drerz.
  LOOP AT lt_item ASSIGNING <fs_item>.
    ls_drerz-sign = 'I'.
    ls_drerz-option = 'EQ'.
    ls_drerz-low = <fs_item>-drerz.
    APPEND ls_drerz TO lr_drerz.
  ENDLOOP.

* ZJKT_STOER_LIEF (Nur PVA, den Rest selektiert schon die CIC-Klasse ausser bei Lieferart Post)
  SELECT * FROM /msh/stoer_t_lf INTO TABLE et_lief
            WHERE ( drerz EQ space OR drerz IN lr_drerz )
            AND fvart EQ '0005'
            AND gueltigvon LE sy-datum
            AND gueltigbis GE sy-datum
            AND ( pva EQ space OR pva IN lr_pva )
            AND ( route EQ space OR route IN lr_route )
            AND ( postleit = '*' OR postleit = lv_postleit ).
  SELECT * FROM /msh/stoer_t_lf APPENDING TABLE et_lief
                WHERE ( drerz EQ space OR drerz IN lr_drerz )
              AND gueltigvon LE sy-datum
              AND gueltigbis GE sy-datum
              AND lfartlog NE '01'
              AND lfartlog NE '11'
              AND lfartlog IN lr_lfart
              AND ( bezrunde EQ space OR bezrunde IN lr_bezrunde )
              AND ( route EQ space OR route IN lr_route )
              AND ( postleit = '*' OR postleit = lv_postleit )
              AND ( bezirk EQ space OR bezirk IN lr_bezirk )
              AND ( pva EQ space OR pva IN lr_pva ).

* Auch die aktuellen Störungsmeldungen lesen
* Bei Zustellung (s. Lieferart) muss es einen Bezirk geben
  IF NOT lr_bezirk[] IS INITIAL.
    SELECT * FROM /msh/stoer_t_lf INTO ls_lief_sel "APPENDING TABLE et_lief
                  WHERE ( drerz EQ space OR drerz IN lr_drerz )
                AND gueltigvon LE sy-datum
                AND gueltigbis GE sy-datum
                AND lfartlog IN lr_lfart_zust "( lfartlog EQ '01' OR lfartlog EQ '11' )
                AND lfartlog IN lr_lfart
                AND fvart NE '0005'
                AND ( bezrunde EQ space OR bezrunde IN lr_bezrunde )
                AND ( route EQ space OR route IN lr_route )
                AND ( bezirk EQ space OR bezirk IN lr_bezirk )
                AND ( pva EQ space OR pva IN lr_pva ).
      IF NOT ls_lief_sel-bezirk IS INITIAL.
        "Bezirk gefüllt, also passt er per se durch die im Ragen vorgegebenen
        APPEND ls_lief_sel TO et_lief.
      ELSE.
        "Wenn Bezirk initial, Zuordnung (s. auch unten) prüfen
        SELECT * FROM /msh/stoer_t_lz INTO TABLE @DATA(lt_zuo) WHERE stoerid EQ @ls_lief_sel-stoerid.
        CHECK sy-subrc = 0.
        SELECT COUNT(*) FROM jvtfehler FOR ALL ENTRIES IN lt_zuo
                                WHERE bezirk IN lr_bezirk
                                AND fvnr EQ lt_zuo-fvnr.
        CHECK sy-dbcnt GT 0.
        APPEND ls_lief_sel TO et_lief.
      ENDIF.
    ENDSELECT.
  ENDIF.

  SORT et_lief BY stoerid DESCENDING.
  DELETE ADJACENT DUPLICATES FROM et_lief COMPARING stoerid.

* Route prüfen
  LOOP AT et_lief ASSIGNING <fs_lief> WHERE NOT route IS INITIAL.
    lf_tabix = sy-tabix.
    SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = <fs_lief>-route AND dispodat = sy-datum.
    CHECK sy-subrc NE 0.
    DELETE et_lief INDEX lf_tabix.
  ENDLOOP.

* Route auf Bezirk prüfen
  IF NOT lr_bezirk[] IS INITIAL.
    LOOP AT et_lief ASSIGNING <fs_lief> WHERE NOT route IS INITIAL.
      lf_tabix = sy-tabix.
      SELECT * FROM /msh/stoer_t_lz INTO TABLE lt_zuo WHERE stoerid EQ <fs_lief>-stoerid.
      CHECK sy-subrc = 0.
      SELECT COUNT(*) FROM jvtfehler FOR ALL ENTRIES IN lt_zuo
                              WHERE bezirk IN lr_bezirk
                              AND fvnr EQ lt_zuo-fvnr.
      CHECK sy-subrc NE 0.
      DELETE et_lief INDEX lf_tabix.
    ENDLOOP.
  ENDIF.

* ZJKT_STOER_DIG
  IF NOT lt_item[] IS INITIAL.
    SELECT * FROM /msh/stoer_t_dig INTO TABLE et_dig
              WHERE ( drerz_dig EQ space OR drerz_dig IN lr_drerz )
              AND gueltigvon LE sy-datum
              AND gueltigbis GE sy-datum
              AND ( pva_dig EQ space OR pva_dig IN lr_pva ).
  ENDIF.

* ZJKT_STOER_GP
  SELECT * FROM /msh/stoer_t_gp INTO TABLE et_gp
        WHERE gpnr EQ iv_gpnr
        AND ( drerz EQ space OR drerz IN lr_drerz )
        AND ( pva EQ space OR pva IN lr_pva )
        AND gueltigvon LE sy-datum
        AND gueltigbis GE sy-datum.
* Störungsmeldungen zusätzlich nach Adresse
  IF NOT <fs_search> IS INITIAL.
    SELECT * FROM /msh/stoer_t_gp APPENDING TABLE et_gp
          WHERE gpnr EQ space
          AND ( drerz EQ space OR drerz IN lr_drerz )
          AND ( pva EQ space OR pva IN lr_pva )
          AND gueltigvon LE sy-datum
          AND gueltigbis GE sy-datum
          AND name1 EQ '*'
          AND ort01 EQ <fs_search>-ort01
          AND stras EQ <fs_search>-stras
          AND pstlz EQ <fs_search>-pstlz
          AND hausn EQ <fs_search>-hausn.
  ENDIF.

* ZJKT_STOER_PROD
  IF NOT lt_item[] IS INITIAL.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE et_prod
              WHERE ( drerz_prod EQ space OR drerz_prod IN lr_drerz )
              AND gueltigvon LE sy-datum
              AND gueltigbis GE sy-datum
              AND ( bezirk_prod EQ space OR bezirk_prod IN lr_bezirk )
              AND ( pva_prod EQ space OR pva_prod IN lr_pva )
              AND ( route EQ space OR route IN lr_route ).
  ENDIF.

* Route prüfen
  LOOP AT et_prod ASSIGNING <fs_prod> WHERE NOT route IS INITIAL.
    lf_tabix = sy-tabix.
    SELECT SINGLE COUNT(*) FROM jrttroute WHERE route = <fs_prod>-route AND dispodat = sy-datum.
    CHECK sy-subrc NE 0.
    DELETE et_prod INDEX lf_tabix.
  ENDLOOP.



ENDFUNCTION.
