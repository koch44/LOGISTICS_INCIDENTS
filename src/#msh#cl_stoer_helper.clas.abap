CLASS /msh/cl_stoer_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_consdata,
        vbeln      TYPE  avnr,
        posnr      TYPE apnr,
        gueltigvon TYPE  dats,
        gueltigbis TYPE dats,
        poart(2)   TYPE c,
        kunwe      TYPE gpnr,
        drerz      TYPE drerz,
        pva        TYPE pva,
        bezugstyp  TYPE bezugstyp_je_pva,
        jparvw     TYPE jparvw,
        bezirk     TYPE bezirk,
        bezrunde   TYPE bezrunde,
        beablst    TYPE	beablst,
        geoein     TYPE geoein,
        lieferart  TYPE lieferart,
        liefbarnr  TYPE liefbarnr,
      END OF ty_consdata .
    TYPES:
      BEGIN OF ty_msg,
        state          TYPE i,
        time_as_string TYPE string,
      END OF ty_msg .
    TYPES:
      tt_consdata TYPE TABLE OF ty_consdata .
    TYPES:
      tt_msg TYPE TABLE OF ty_msg .

    DATA it_consdata TYPE tt_consdata .
    CLASS-DATA cc_state_act_on TYPE i VALUE 0 ##NO_TEXT.
    CLASS-DATA cc_state_act_off TYPE i VALUE 1 ##NO_TEXT.
    CLASS-DATA cc_state_act_onoff TYPE i VALUE 2 ##NO_TEXT.
    CLASS-DATA cc_state_act_on_without_time TYPE i VALUE 3 ##NO_TEXT.

    METHODS check_nachrichten
      IMPORTING
        !iv_gpnr     TYPE gpnr
        !it_item     TYPE rjycic_msditemdatatab
      CHANGING
        !ct_messages TYPE tt_msg .
    METHODS check_stoerungen
      IMPORTING
        !iv_gpnr TYPE gpnr
        !it_item TYPE rjycic_msditemdatatab
      CHANGING
        !ct_akt  TYPE /msh/stoer_tt_interr
        !ct_hist TYPE /msh/stoer_tt_interr .
    METHODS constructor
      IMPORTING
        !li_gpnr     TYPE gpnr
        !li_akttage  TYPE i
        !li_histtage TYPE i .
    METHODS ermittle_cic_aktuelle
      RETURNING
        VALUE(rt_cic_env) TYPE isu_badi_cic_env_tab .
    METHODS ermittle_stoerungen_cic
      RETURNING
        VALUE(rt_cic_env) TYPE isu_badi_cic_env_tab .
    METHODS hole_nachrichten
      IMPORTING
        !it_item     TYPE rjycic_msditemdatatab OPTIONAL
      EXPORTING
        !et_messages TYPE tt_msg .
    METHODS export_liefdat
      EXPORTING
        !er_bezirk   TYPE ANY TABLE
        !er_bezrunde TYPE ANY TABLE
        !er_pva      TYPE ANY TABLE
        !er_route    TYPE ANY TABLE .
    CLASS-METHODS filter_gp_aktiv_abo
      IMPORTING
        !iv_guevon    TYPE dats
      CHANGING
        !ct_addresses TYPE jg002_adresstab_tab .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
    tt_jvtfehler TYPE TABLE OF jvtfehler .

    DATA iv_gpnr TYPE gpnr .
    DATA it_jvtfehler TYPE tt_jvtfehler .
    DATA iv_anzruecktag TYPE i .
    DATA iv_anzakttag TYPE i .
    DATA iv_refdatum_rueck TYPE dats .
    DATA:
      ir_bezirk TYPE RANGE OF bezirk .
    DATA:
      ir_bezrunde TYPE RANGE OF bezrunde .
    DATA:
      ir_pva TYPE RANGE OF pva .
    DATA it_jvtfehler_hist_forcic TYPE isu_badi_cic_env_tab .
    DATA it_jvtfehler_akt_forcic TYPE isu_badi_cic_env_tab .
    DATA iv_refdatum_akt TYPE dats .

    METHODS lese_abopositionen .
    METHODS lese_jvtfehler .
    METHODS formatiere_datum
      IMPORTING
        !iv_date                 TYPE dats
      RETURNING
        VALUE(rv_date_as_string) TYPE string .
    METHODS formatiere_uhrzeit
      IMPORTING
        !iv_time                 TYPE tims
      RETURNING
        VALUE(rv_time_as_string) TYPE string .
ENDCLASS.



CLASS /MSH/CL_STOER_HELPER IMPLEMENTATION.


  METHOD check_nachrichten.
    CHECK NOT ct_messages[] IS INITIAL.

* Wenn kein Vertriebskunde, dann initialisieren
    SELECT SINGLE COUNT(*) FROM jgvdb_ku WHERE gpnr = iv_gpnr.
    IF sy-subrc NE 0 AND it_item[] IS INITIAL.
      REFRESH ct_messages[].
      EXIT.
    ENDIF.

* Wenn keine Aufträge, dann auch keine Meldung
    IF it_item[] IS INITIAL.
      REFRESH ct_messages[].
      EXIT.
    ENDIF.

  ENDMETHOD.


  METHOD check_stoerungen.

    DATA: lv_crea      TYPE dats,
          lv_minguevon TYPE dats,
          lv_maxguebis TYPE dats,
          lt_item      TYPE rjycic_msditemdatatab,
          ls_item      LIKE LINE OF it_item.

    DATA: lr_bezirk   TYPE RANGE OF bezirk,
          lr_bezrunde TYPE RANGE OF bezrunde,
          lr_pva      TYPE RANGE OF pva,
          lr_drerz    TYPE RANGE OF drerz,
          ls_drerz    LIKE LINE OF lr_drerz,
          lr_route    TYPE /msh/stoer_tt_route,
          dref        TYPE REF TO data,
          lt_jkpaz    TYPE TABLE OF jkpaz,
          lv_found    TYPE abap_bool.

    FIELD-SYMBOLS: <fs_data> TYPE any.

* Nur wenn Meldungen da
    CHECK NOT ( ct_akt[] IS INITIAL AND ct_hist[] IS INITIAL ).

    export_liefdat(
      IMPORTING
        er_bezirk   = lr_bezirk
        er_bezrunde = lr_bezrunde
        er_pva      = lr_pva
        er_route    = lr_route ).

* Anlagedatum des GP
    CHECK NOT iv_gpnr IS INITIAL.
    SELECT SINGLE erfdate FROM jgtgpnr INTO lv_crea WHERE gpnr = iv_gpnr.
    CHECK sy-subrc = 0 AND NOT lv_crea IS INITIAL.

* Frühere Einträge löschen
    DELETE ct_akt WHERE sortdat LT lv_crea.
    DELETE ct_hist WHERE sortdat LT lv_crea.

* Keine Störungen wenn keine Aufträge, für historische auch historisch lesen
    IF it_item[] IS INITIAL.
*    REFRESH: ct_akt[].
      LOOP AT ct_akt ASSIGNING FIELD-SYMBOL(<fs_del>).
        DATA(d_tabix) = sy-tabix.
        CHECK <fs_del>-key(2) NE 'GP'.
        DELETE ct_akt INDEX d_tabix.
      ENDLOOP.
    ENDIF.

    CALL FUNCTION 'ISM_CIC_MSDORDER_DATA_READ'
      EXPORTING
        gpnr    = iv_gpnr
      IMPORTING
        itemtab = lt_item.
    IF lt_item[] IS INITIAL.
*    REFRESH: ct_hist[].
      LOOP AT ct_hist ASSIGNING <fs_del>.
        d_tabix = sy-tabix.
        CHECK <fs_del>-key(2) NE 'GP'.
        DELETE ct_hist INDEX d_tabix.
      ENDLOOP.
    ENDIF.


    CHECK NOT ( ct_akt[] IS INITIAL AND ct_hist[] IS INITIAL ).

    IF NOT lt_item IS INITIAL.
      LOOP AT lt_item INTO ls_item.
        IF lv_minguevon IS INITIAL.
          lv_minguevon = ls_item-gueltigvon.
        ELSEIF ls_item-gueltigvon LT lv_minguevon.
          lv_minguevon = ls_item-gueltigvon.
        ENDIF.
        IF lv_maxguebis IS INITIAL.
          lv_maxguebis = ls_item-gueltigbis.
        ELSEIF ls_item-gueltigbis GT lv_maxguebis.
          lv_maxguebis = ls_item-gueltigbis.
        ENDIF.
      ENDLOOP.
    ELSE.
      LOOP AT it_item INTO ls_item.
        IF lv_minguevon IS INITIAL.
          lv_minguevon = ls_item-gueltigvon.
        ELSEIF ls_item-gueltigvon LT lv_minguevon.
          lv_minguevon = ls_item-gueltigvon.
        ENDIF.
        IF lv_maxguebis IS INITIAL.
          lv_maxguebis = ls_item-gueltigbis.
        ELSEIF ls_item-gueltigbis GT lv_maxguebis.
          lv_maxguebis = ls_item-gueltigbis.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF lv_maxguebis IS INITIAL OR lv_maxguebis EQ '00000000'.
      lv_maxguebis = '99991231'.
    ENDIF.

* Frühere Einträge löschen
    DELETE ct_akt WHERE sortdat LT lv_minguevon.
    DELETE ct_hist WHERE sortdat LT lv_minguevon.

* Ebenso die späteren
    DELETE ct_akt WHERE sortdat GT lv_maxguebis.
    DELETE ct_hist WHERE sortdat GT lv_maxguebis.

* Nur Störungen zu Zeiten, zu denen auch ein Auftrag bestand oder besteht (STOMSD-73)
* vorerst OHNE DRERZ etc.
    LOOP AT ct_akt ASSIGNING FIELD-SYMBOL(<fs_akt>) WHERE key(2) NE 'GP'.
      DATA(l_tabix) = sy-tabix.
      LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE gueltigvon LE <fs_akt>-sortdat AND gueltigbis GE <fs_akt>-sortdat.
        EXIT.
      ENDLOOP.
      CHECK sy-subrc NE 0.
      DELETE ct_akt INDEX l_tabix.
    ENDLOOP.
    LOOP AT ct_hist ASSIGNING FIELD-SYMBOL(<fs_hist>) WHERE key(2) NE 'GP'.
      l_tabix = sy-tabix.
      LOOP AT lt_item ASSIGNING <fs_item> WHERE gueltigvon LE <fs_hist>-sortdat AND gueltigbis GE <fs_hist>-sortdat.
        EXIT.
      ENDLOOP.
      CHECK sy-subrc NE 0.
      DELETE ct_hist INDEX l_tabix.
    ENDLOOP.

* Lieferstörungen mit Bezirk nur bei Kunden, die auch im jeweiligen Bezirk beliefert werden (JKPAZ)

* Aktuelle Störungen
    LOOP AT ct_akt ASSIGNING <fs_akt>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO @DATA(ls_cust) WHERE area_id = @<fs_akt>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_akt>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fv_guevon>).
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fv_guebis>).
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'BEZIRK' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fv_bezirk>).
            IF sy-subrc NE 0.
              ASSIGN COMPONENT 'BEZIRK_PROD' OF STRUCTURE <fs_data> TO <fv_bezirk>.
            ENDIF.
            IF sy-subrc NE 0.
              ASSIGN COMPONENT 'BEZIRK_GP' OF STRUCTURE <fs_data> TO <fv_bezirk>.
            ENDIF.
            CHECK sy-subrc = 0 AND NOT <fv_bezirk> IS INITIAL.
            "Auftragspositionen prüfen
            LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                  AND gueltigvon LE <fv_guebis>
                                                  AND gueltigbis GE <fv_guevon>.
              CHECK lv_found EQ abap_false.
              "JKPAZ lesen
              REFRESH lt_jkpaz[].
              CALL FUNCTION 'ISP_JKPAZ_READ_BY_POSITION'
                EXPORTING
                  posnr         = <fs_item>-posnr
                  vbeln         = <fs_item>-vbeln
                TABLES
                  ojkpaz        = lt_jkpaz
                EXCEPTIONS
                  no_data_found = 1
                  posnr_missing = 2
                  vbeln_missing = 3
                  OTHERS        = 4.
              CHECK sy-subrc = 0 AND NOT lt_jkpaz[] IS INITIAL.
              LOOP AT lt_jkpaz ASSIGNING FIELD-SYMBOL(<fs_jkpaz>) WHERE bezirk = <fv_bezirk>.
                lv_found = abap_true.
                EXIT.
              ENDLOOP.
            ENDLOOP.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_akt>-key(2) NE 'GP'.
            DELETE ct_akt INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
* Historische Störungen
    LOOP AT ct_hist ASSIGNING <fs_hist>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO ls_cust WHERE area_id = <fs_hist>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_hist>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO <fv_guevon>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO <fv_guebis>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'BEZIRK' OF STRUCTURE <fs_data> TO <fv_bezirk>.
            IF sy-subrc NE 0.
              ASSIGN COMPONENT 'BEZIRK_PROD' OF STRUCTURE <fs_data> TO <fv_bezirk>.
            ENDIF.
            IF sy-subrc NE 0.
              ASSIGN COMPONENT 'BEZIRK_GP' OF STRUCTURE <fs_data> TO <fv_bezirk>.
            ENDIF.
            CHECK sy-subrc = 0 AND NOT <fv_bezirk> IS INITIAL.
            "Auftragspositionen prüfen
            LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                  AND gueltigvon LE <fv_guebis>
                                                  AND gueltigbis GE <fv_guevon>.
              CHECK lv_found EQ abap_false.
              "JKPAZ lesen
              REFRESH lt_jkpaz[].
              CALL FUNCTION 'ISP_JKPAZ_READ_BY_POSITION'
                EXPORTING
                  posnr         = <fs_item>-posnr
                  vbeln         = <fs_item>-vbeln
                TABLES
                  ojkpaz        = lt_jkpaz
                EXCEPTIONS
                  no_data_found = 1
                  posnr_missing = 2
                  vbeln_missing = 3
                  OTHERS        = 4.
              CHECK sy-subrc = 0 AND NOT lt_jkpaz[] IS INITIAL.
              LOOP AT lt_jkpaz ASSIGNING <fs_jkpaz> WHERE bezirk = <fv_bezirk>.
                lv_found = abap_true.
                EXIT.
              ENDLOOP.
            ENDLOOP.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_hist>-key(2) NE 'GP'.
            DELETE ct_hist INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.

* Lieferstörungen mit Route nur bei Kunden, die auch im jeweils zugehörigen Bezirk beliefert werden (JKPAZ)

* Aktuelle Störugnen
    LOOP AT ct_akt ASSIGNING <fs_akt>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO ls_cust WHERE area_id = <fs_akt>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_akt>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO <fv_guevon>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO <fv_guebis>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'ROUTE' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fv_route>).
            CHECK sy-subrc = 0 AND NOT <fv_route> IS INITIAL.
            IF NOT lr_route[] IS INITIAL.
              IF <fv_route> IN lr_route.
                lv_found = abap_true.
              ENDIF.
            ELSE.
              "Auftragspositionen prüfen
              LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                    AND gueltigvon LE <fv_guebis>
                                                    AND gueltigbis GE <fv_guevon>.
                CHECK lv_found EQ abap_false.
                "JKPAZ lesen
                REFRESH lt_jkpaz[].
                CALL FUNCTION 'ISP_JKPAZ_READ_BY_POSITION'
                  EXPORTING
                    posnr         = <fs_item>-posnr
                    vbeln         = <fs_item>-vbeln
                  TABLES
                    ojkpaz        = lt_jkpaz
                  EXCEPTIONS
                    no_data_found = 1
                    posnr_missing = 2
                    vbeln_missing = 3
                    OTHERS        = 4.
                CHECK sy-subrc = 0 AND NOT lt_jkpaz[] IS INITIAL.
                LOOP AT lt_jkpaz ASSIGNING <fs_jkpaz> WHERE NOT bezirk IS INITIAL.
                  REFRESH lr_route[].
                  CALL FUNCTION '/MSH/STOER_GET_ROUTE'
                    EXPORTING
                      iv_bezirk = <fs_jkpaz>-bezirk
                      iv_datum  = <fs_akt>-sortdat
                    IMPORTING
                      er_routen = lr_route.
                  IF NOT lr_route[] IS INITIAL.
                    CHECK <fv_route> IN lr_route.
                    lv_found = abap_true.
                  ENDIF.
                ENDLOOP.
                IF lv_found EQ abap_false.
                  LOOP AT lt_jkpaz ASSIGNING <fs_jkpaz>.
                    CHECK lv_found EQ abap_false.
                    SELECT SINGLE * FROM jkpa INTO @DATA(ls_jkpa) WHERE vbeln = @<fs_jkpaz>-vbeln
                                                                    AND posnr = @<fs_jkpaz>-posnr
                                                                    AND jparvw = @<fs_jkpaz>-jparvw
                                                                    AND gueltigvon = @<fs_jkpaz>-jkpavon
                                                                    AND gueltigbis = @<fs_jkpaz>-gueltigbis.
                    CHECK sy-subrc = 0 AND NOT ls_jkpa-beablst IS INITIAL.
                    CALL FUNCTION '/MSH/STOER_CHECK_BEABLST'
                      EXPORTING
                        iv_ablad  = ls_jkpa-beablst
                        iv_route  = <fv_route>
                        iv_guevon = <fv_guevon>
                        iv_guebis = <fv_guebis>
                      IMPORTING
                        ev_found  = lv_found.
                  ENDLOOP.
                ENDIF.
              ENDLOOP.
            ENDIF.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_akt>-key(2) NE 'GP'.
            DELETE ct_akt INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.

* Historische Störungen
    LOOP AT ct_hist ASSIGNING <fs_hist>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO ls_cust WHERE area_id = <fs_hist>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_hist>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO <fv_guevon>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO <fv_guebis>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'ROUTE' OF STRUCTURE <fs_data> TO <fv_route>.
            CHECK sy-subrc = 0 AND NOT <fv_route> IS INITIAL.
            "Auftragspositionen prüfen
            LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                  AND gueltigvon LE <fv_guebis>
                                                  AND gueltigbis GE <fv_guevon>.
              CHECK lv_found EQ abap_false.
              "JKPAZ lesen
              REFRESH lt_jkpaz[].
              CALL FUNCTION 'ISP_JKPAZ_READ_BY_POSITION'
                EXPORTING
                  posnr         = <fs_item>-posnr
                  vbeln         = <fs_item>-vbeln
                TABLES
                  ojkpaz        = lt_jkpaz
                EXCEPTIONS
                  no_data_found = 1
                  posnr_missing = 2
                  vbeln_missing = 3
                  OTHERS        = 4.
              CHECK sy-subrc = 0 AND NOT lt_jkpaz[] IS INITIAL.
              LOOP AT lt_jkpaz ASSIGNING <fs_jkpaz> WHERE NOT bezirk IS INITIAL.
                REFRESH lr_route[].
                CALL FUNCTION '/MSH/STOER_GET_ROUTE'
                  EXPORTING
                    iv_bezirk = <fs_jkpaz>-bezirk
                    iv_datum  = <fs_hist>-sortdat
                  IMPORTING
                    er_routen = lr_route.
                IF NOT lr_route[] IS INITIAL.
                  CHECK <fv_route> IN lr_route.
                  lv_found = abap_true.
                ENDIF.
              ENDLOOP.
              IF lv_found EQ abap_false.
                LOOP AT lt_jkpaz ASSIGNING <fs_jkpaz>.
                  CHECK lv_found EQ abap_false.
                  SELECT SINGLE * FROM jkpa INTO ls_jkpa WHERE vbeln = <fs_jkpaz>-vbeln
                                                                  AND posnr = <fs_jkpaz>-posnr
                                                                  AND jparvw = <fs_jkpaz>-jparvw
                                                                  AND gueltigvon = <fs_jkpaz>-jkpavon
                                                                  AND gueltigbis = <fs_jkpaz>-gueltigbis.
                  CHECK sy-subrc = 0 AND NOT ls_jkpa-beablst IS INITIAL.
                  CALL FUNCTION '/MSH/STOER_CHECK_BEABLST'
                    EXPORTING
                      iv_ablad  = ls_jkpa-beablst
                      iv_route  = <fv_route>
                      iv_guevon = <fv_guevon>
                      iv_guebis = <fv_guebis>
                    IMPORTING
                      ev_found  = lv_found.
                ENDLOOP.
              ENDIF.
            ENDLOOP.
*          ENDIF.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_hist>-key(2) NE 'GP'.
            DELETE ct_hist INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.

* Jegliche Lieferstörungen gegen Auftragspositionen mit der entsprechenden Lieferart prüfen
* Aktuelle Störugnen
    LOOP AT ct_akt ASSIGNING <fs_akt>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO ls_cust WHERE area_id = <fs_akt>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_akt>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO <fv_guevon>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO <fv_guebis>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'LFARTLOG' OF STRUCTURE <fs_data> TO FIELD-SYMBOL(<fv_lfart>).
            CHECK sy-subrc = 0 AND NOT <fv_lfart> IS INITIAL.
            LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                  AND gueltigvon LE <fv_guebis>
                                                  AND gueltigbis GE <fv_guevon>
                                                  AND lieferart EQ <fv_lfart>.
              "GP muss WE sein
              IF NOT <fs_item>-jparvwtab[] IS INITIAL.
                READ TABLE <fs_item>-jparvwtab ASSIGNING FIELD-SYMBOL(<fs_parvw>) WITH KEY table_line = 'WE'.
                CHECK sy-subrc = 0.
              ENDIF.
              "GEfunden
              lv_found = abap_true.
              EXIT.
            ENDLOOP.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_akt>-key(2) NE 'GP'.
            DELETE ct_akt INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
    LOOP AT ct_hist ASSIGNING <fs_hist>.
      l_tabix = sy-tabix.
      lv_found = abap_false.
      "Meldung lesen
      TRY.
          SELECT SINGLE * FROM /msh/stoer_t_cst INTO ls_cust WHERE area_id = <fs_hist>-key(2).
          IF sy-subrc = 0.
            CREATE DATA dref TYPE (ls_cust-area_dbtab).
            UNASSIGN <fs_data>.
            ASSIGN dref->* TO <fs_data>.
            CHECK <fs_data> IS ASSIGNED.
            SELECT SINGLE * FROM (ls_cust-area_dbtab) INTO <fs_data> WHERE stoerid = <fs_hist>-key+2.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGVON' OF STRUCTURE <fs_data> TO <fv_guevon>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'GUELTIGBIS' OF STRUCTURE <fs_data> TO <fv_guebis>.
            CHECK sy-subrc = 0.
            ASSIGN COMPONENT 'LFARTLOG' OF STRUCTURE <fs_data> TO <fv_lfart>.
            CHECK sy-subrc = 0 AND NOT <fv_lfart> IS INITIAL.
            LOOP AT lt_item ASSIGNING <fs_item> WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                  AND gueltigvon LE <fv_guebis>
                                                  AND gueltigbis GE <fv_guevon>
                                                  AND lieferart EQ <fv_lfart>.
              "GP muss WE sein
              IF NOT <fs_item>-jparvwtab[] IS INITIAL.
                READ TABLE <fs_item>-jparvwtab ASSIGNING <fs_parvw> WITH KEY table_line = 'WE'.
                CHECK sy-subrc = 0.
              ENDIF.
              "GEfunden
              lv_found = abap_true.
              EXIT.
            ENDLOOP.
            "Kein Treffer? dann löschen
            CHECK lv_found = abap_false AND <fs_hist>-key(2) NE 'GP'.
            DELETE ct_hist INDEX l_tabix.
          ENDIF.
        CATCH cx_root.
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD constructor.

* GP übergeben
    MOVE li_gpnr TO me->iv_gpnr.
*
* Zeitschiene in die Vergangenheit
    MOVE li_histtage TO me->iv_anzruecktag.
    me->iv_refdatum_rueck = sy-datum - me->iv_anzruecktag.

* Zeitscheiene Gegenwart
    MOVE li_akttage TO me->iv_anzakttag.
    me->iv_refdatum_akt = sy-datum - me->iv_anzakttag.

  ENDMETHOD.


  METHOD ermittle_cic_aktuelle.

    DATA: ls_env       TYPE isu_badi_cic_env,
          ls_jvtfehler TYPE jvtfehler,
          lv_text1     TYPE string,
          lv_text2     TYPE string,
          lv_text3     TYPE string,
          lv_date      TYPE string.

    IF ( me->it_jvtfehler IS INITIAL ).
      me->lese_jvtfehler( ).
    ENDIF.

    IF ( me->it_jvtfehler_akt_forcic IS INITIAL ).
      LOOP AT me->it_jvtfehler INTO ls_jvtfehler.
        CLEAR ls_env.
        MOVE 'MSDACTJVTFEHLER' TO ls_env-cluster_type.
        MOVE '/MSH/CIC' TO ls_env-classid.
        MOVE ls_jvtfehler-fvnr TO ls_env-key.
        IF ( ls_jvtfehler-xnachlief EQ 'X' AND ls_jvtfehler-xbezliegt EQ 'X' AND
             ls_jvtfehler-nledatum = sy-datum AND ls_jvtfehler-nleuhrzeit <= sy-uzeit ).
          MOVE 'ICON_YELLOW_LIGHT' TO ls_env-icon.
        ELSE.
          MOVE 'ICON_RED_LIGHT' TO ls_env-icon.
        ENDIF.
        lv_date = me->formatiere_datum( ls_jvtfehler-vrsnddatum ).

        IF NOT ls_jvtfehler-bezirk IS INITIAL.
          CONCATENATE lv_date '-' ls_jvtfehler-fvgrund '-' ls_jvtfehler-bezirk INTO lv_text1 RESPECTING BLANKS.
        ELSE.
          CONCATENATE lv_date '-' ls_jvtfehler-fvgrund '-' ls_jvtfehler-pva INTO lv_text1 RESPECTING BLANKS.
        ENDIF.
        MOVE lv_text1 TO ls_env-text1.
        SELECT SINGLE kurztext FROM tjv44 INTO lv_text2 WHERE fvgrund = ls_jvtfehler-fvgrund.
        MOVE lv_text2 TO ls_env-text2.
        CONCATENATE ls_jvtfehler-nleuhrzeit+0(2) ':' ls_jvtfehler-nleuhrzeit+2(2) ':' ls_jvtfehler-nleuhrzeit+4(2) INTO ls_env-text3 RESPECTING BLANKS.
        APPEND ls_env TO me->it_jvtfehler_akt_forcic.
      ENDLOOP.
    ENDIF.
    MOVE me->it_jvtfehler_akt_forcic TO rt_cic_env.
  ENDMETHOD.


  METHOD ermittle_stoerungen_cic.

    DATA: ls_env       TYPE isu_badi_cic_env,
          ls_jvtfehler TYPE jvtfehler,
          lv_text1     TYPE string,
          lv_text2     TYPE string,
          lv_text3     TYPE string,
          lv_date      TYPE string.

    IF ( me->it_jvtfehler IS INITIAL ).
      me->lese_jvtfehler( ).
    ENDIF.

    IF ( me->it_jvtfehler_hist_forcic IS INITIAL ).
      LOOP AT me->it_jvtfehler INTO ls_jvtfehler.
        CLEAR ls_env.
        MOVE 'MSDOLDJVTFEHLER' TO ls_env-cluster_type.
        MOVE '/MSH/CIC' TO ls_env-classid.
        MOVE ls_jvtfehler-fvnr TO ls_env-key.
        MOVE 'ICON_ALERT' TO ls_env-icon.
        lv_date = me->formatiere_datum( ls_jvtfehler-vrsnddatum ).

        IF NOT ls_jvtfehler-bezirk IS INITIAL.
          CONCATENATE lv_date '-' ls_jvtfehler-fvgrund '-' ls_jvtfehler-bezirk INTO lv_text1 RESPECTING BLANKS.
        ELSE.
          CONCATENATE lv_date '-' ls_jvtfehler-fvgrund '-' ls_jvtfehler-pva INTO lv_text1 RESPECTING BLANKS.
        ENDIF.
        MOVE lv_text1 TO ls_env-text1.

        SELECT SINGLE kurztext FROM tjv44 INTO lv_text2 WHERE fvgrund = ls_jvtfehler-fvgrund.
        MOVE lv_text2 TO ls_env-text2.
        MOVE ls_jvtfehler-fvnr TO ls_env-text3.
        APPEND ls_env TO me->it_jvtfehler_hist_forcic.
      ENDLOOP.
    ENDIF.

    MOVE me->it_jvtfehler_hist_forcic TO rt_cic_env.
  ENDMETHOD.


  METHOD export_liefdat.

    TYPES: BEGIN OF ty_rout,
             route TYPE isproute,
           END OF ty_rout.

    DATA: lr_route TYPE RANGE OF tagroute,
          lt_route TYPE TABLE OF ty_rout.

    FIELD-SYMBOLS: <fs_route> TYPE ty_rout,
                   <fs_range> LIKE LINE OF lr_route.

    er_bezirk[] = ir_bezirk[].
    er_bezrunde[] = ir_bezrunde[].
    er_pva[] = ir_pva[].

* Route
    IF NOT ir_bezirk[] IS INITIAL.
      SELECT * FROM jrtablg INTO CORRESPONDING FIELDS OF TABLE lt_route WHERE bezirktat IN ir_bezirk
                                                    AND versanddat EQ me->iv_refdatum_akt
                                                    AND pvatat IN ir_pva.
    ENDIF.
    SORT lt_route BY route ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_route COMPARING route.
    LOOP AT lt_route ASSIGNING <fs_route>.
      APPEND INITIAL LINE TO lr_route ASSIGNING <fs_range>.
      <fs_range>-sign = 'I'.
      <fs_range>-option = 'EQ'.
      <fs_range>-low = <fs_route>-route.
    ENDLOOP.
    er_route[] = lr_route[].

  ENDMETHOD.


  METHOD filter_gp_aktiv_abo.

    INCLUDE mjk00tko.

    DATA: l_auartgrp_rangetab TYPE RANGE OF jkak-auartgrp,
          l_auartgrp_range    LIKE LINE OF l_auartgrp_rangetab,
          l_jkvpa_cictab      TYPE TABLE OF jkvpa_cic,
          wa_jkap             TYPE jkap,
          zmandt              TYPE jkap-mandt,
          lv_found            TYPE xfeld,
          wa_jkvpa_cic        TYPE jkvpa_cic.

    DEFINE fill_auartgrp_rangetab.
      l_auartgrp_range-sign   = 'I'.
      l_auartgrp_range-option = 'EQ'.
      l_auartgrp_range-low    = &1.
      append l_auartgrp_range to l_auartgrp_rangetab.
    END-OF-DEFINITION.

    fill_auartgrp_rangetab: con_auartgrp_abonnement,
                        con_auartgrp_reserveauftrag,
                        con_auartgrp_gutschein_auftrag,
                        con_auartgrp_belegversand,
                        con_auartgrp_gutlastschrift.

    LOOP AT ct_addresses ASSIGNING FIELD-SYMBOL(<fs_address>).
      DATA(l_tabix) = sy-tabix.
      REFRESH l_jkvpa_cictab[].
      SELECT DISTINCT * FROM jkvpa_cic INTO TABLE l_jkvpa_cictab
                                            WHERE gpnr        = <fs_address>-gp_ref
                                            AND   jkpabis    >= iv_guevon
                                            AND   auartgrp   IN l_auartgrp_rangetab
                                            ORDER BY vbeln posnr.
      IF sy-subrc NE 0.
        DELETE ct_addresses INDEX l_tabix.
        CONTINUE.
      ENDIF.
      CLEAR lv_found.
      LOOP AT l_jkvpa_cictab INTO wa_jkvpa_cic.
        SELECT SINGLE COUNT(*) FROM jkap WHERE vbeln = wa_jkvpa_cic-vbeln AND
                                      xstorno <> 'X' AND
                                      gueltigvon <= sy-datum AND
                                      gueltigbis >= sy-datum AND
                                      poart IN ('KP', 'PP', 'NP').
        CHECK sy-subrc = 0.
        lv_found = 'X'.
        EXIT.
      ENDLOOP.
      CHECK lv_found IS INITIAL.
      DELETE ct_addresses INDEX l_tabix.
    ENDLOOP.
  ENDMETHOD.


  METHOD formatiere_datum.
    DATA: lv_day(2)   TYPE c,
          lv_month(2) TYPE c,
          lv_year(4)  TYPE c.

    " Datum in Tag, Monat und Jahr aufsplitten
    lv_day    = iv_date+6(2).
    lv_month  = iv_date+4(2).
    lv_year   = iv_date+0(4).

    " Datum in char-Variable im gewünschten Format montieren.
    CONCATENATE lv_day '.' lv_month '.' lv_year+2(2) INTO rv_date_as_string.
  ENDMETHOD.


  METHOD formatiere_uhrzeit.

    DATA: lv_hour(2)   TYPE c,
          lv_minute(2) TYPE c,
          lv_second(2) TYPE c.

    " Datum in Tag, Monat und Jahr aufsplitten
    lv_second  = iv_time+4(2).
    lv_minute  = iv_time+2(2).
    lv_hour   = iv_time+0(2).

    " Datum in char-Variable im gewünschten Format montieren.
    CONCATENATE lv_hour ':' lv_minute '.' lv_second INTO rv_time_as_string.

  ENDMETHOD.


  METHOD hole_nachrichten.

    DATA: ls_jvtfehler     TYPE jvtfehler,
          ls_message       TYPE ty_msg,
          lv_anz_jvtfehler TYPE i,
          lv_found         TYPE abap_bool,
          lt_jkpaz         TYPE TABLE OF jkpaz.

    IF ( me->it_jvtfehler IS INITIAL ).
      me->lese_jvtfehler( ).
    ENDIF.

    "Meldungen nach Bezirk prüfen
    IF NOT it_item[] IS INITIAL.
      LOOP AT me->it_jvtfehler ASSIGNING FIELD-SYMBOL(<fs_jvtfehler>) WHERE NOT bezirk IS INITIAL.
        DATA(l_tabix) = sy-tabix.
        lv_found = abap_false.
        "Auftragspositionen prüfen
        LOOP AT it_item ASSIGNING FIELD-SYMBOL(<fs_item>) WHERE ( poart EQ 'KP' OR poart EQ 'NP' OR poart EQ 'PP' )
                                                          AND gueltigvon LE <fs_jvtfehler>-vrsnddatum
                                                          AND gueltigbis GE <fs_jvtfehler>-vrsnddatum.
          CHECK lv_found EQ abap_false.
          "JKPAZ lesen
          REFRESH lt_jkpaz[].
          CALL FUNCTION 'ISP_JKPAZ_READ_BY_POSITION'
            EXPORTING
              posnr         = <fs_item>-posnr
              vbeln         = <fs_item>-vbeln
            TABLES
              ojkpaz        = lt_jkpaz
            EXCEPTIONS
              no_data_found = 1
              posnr_missing = 2
              vbeln_missing = 3
              OTHERS        = 4.
          CHECK sy-subrc = 0 AND NOT lt_jkpaz[] IS INITIAL.
          LOOP AT lt_jkpaz ASSIGNING FIELD-SYMBOL(<fs_jkpaz>) WHERE bezirk = <fs_jvtfehler>-bezirk.
            lv_found = abap_true.
            EXIT.
          ENDLOOP.
        ENDLOOP.
        CHECK lv_found IS INITIAL.
        DELETE me->it_jvtfehler INDEX l_tabix.
      ENDLOOP.
    ENDIF.

    DESCRIBE TABLE me->it_jvtfehler LINES lv_anz_jvtfehler.
    CASE lv_anz_jvtfehler.
      WHEN 1.
        READ TABLE me->it_jvtfehler INTO ls_jvtfehler INDEX 1.
        IF ls_jvtfehler-nleuhrzeit IS INITIAL.
          MOVE me->cc_state_act_on_without_time TO ls_message-state.
        ELSEIF ls_jvtfehler-nleuhrzeit <= sy-uzeit AND ls_jvtfehler-nledatum <= sy-datum.
          MOVE me->cc_state_act_off TO ls_message-state.
          MOVE me->formatiere_uhrzeit( ls_jvtfehler-nleuhrzeit ) TO ls_message-time_as_string.
        ELSEIF ls_jvtfehler-nleuhrzeit >= sy-uzeit AND ls_jvtfehler-nledatum >= sy-datum.
          MOVE me->cc_state_act_on TO ls_message-state.
          MOVE me->formatiere_uhrzeit( ls_jvtfehler-nleuhrzeit ) TO ls_message-time_as_string.
        ENDIF.
        APPEND ls_message TO et_messages.
      WHEN OTHERS.
        MOVE me->cc_state_act_onoff TO ls_message-state.
        APPEND ls_message TO et_messages.
    ENDCASE.
  ENDMETHOD.


  METHOD lese_abopositionen.
    DATA: ls_consdata          TYPE ty_consdata,
          ls_range_of_bezirk   LIKE LINE OF ir_bezirk,
          ls_range_of_bezrunde LIKE LINE OF ir_bezrunde,
          ls_range_of_pva      LIKE LINE OF ir_pva,
          lf_tabix             TYPE sy-tabix.

* alle Positionen mit GP = WE
    SELECT * FROM jkap
      INNER JOIN jkpa ON jkap~vbeln = jkpa~vbeln AND jkap~posnr = jkpa~posnr
      INNER JOIN jkpaz ON jkpa~vbeln = jkpaz~vbeln AND jkpa~posnr = jkpaz~posnr
      INTO CORRESPONDING FIELDS OF TABLE me->it_consdata
      WHERE jkpa~gpnr = me->iv_gpnr AND jkpa~jparvw = 'WE'
        AND jkpa~gueltigbis >= me->iv_refdatum_rueck.

    SORT me->it_consdata.
    DELETE ADJACENT DUPLICATES FROM me->it_consdata COMPARING ALL FIELDS.

* Nur die, die jeweils gültig sind
    LOOP AT me->it_consdata INTO ls_consdata.
      lf_tabix = sy-tabix.
      CHECK ls_consdata-gueltigbis LT me->iv_refdatum_rueck.
      DELETE me->it_consdata INDEX lf_tabix.
    ENDLOOP.

    LOOP AT me->it_consdata INTO ls_consdata.
*   Liefernummer
      SELECT SINGLE bezrunde abholstell FROM jvtliefbar
        INTO (ls_consdata-bezrunde,ls_consdata-beablst)
        WHERE liefbarnr = ls_consdata-liefbarnr.
*   Bezirkrange
      IF NOT ls_consdata-bezirk IS INITIAL.
        READ TABLE me->ir_bezirk WITH KEY low = ls_consdata-bezirk TRANSPORTING NO FIELDS.
        IF ( sy-subrc NE 0 ).
          ls_range_of_bezirk-sign = 'I'.
          ls_range_of_bezirk-option = 'EQ'.
          ls_range_of_bezirk-low = ls_consdata-bezirk.
          APPEND ls_range_of_bezirk TO me->ir_bezirk.
          CLEAR ls_range_of_bezirk.
        ENDIF.
      ENDIF.
*    Lieferrunde
      IF NOT ls_consdata-bezrunde IS INITIAL.
        READ TABLE me->ir_bezrunde WITH KEY low = ls_consdata-bezrunde TRANSPORTING NO FIELDS.
        IF ( sy-subrc NE 0 ).
          ls_range_of_bezrunde-sign = 'I'.
          ls_range_of_bezrunde-option = 'EQ'.
          ls_range_of_bezrunde-low = ls_consdata-bezrunde.
          APPEND ls_range_of_bezrunde TO me->ir_bezrunde.
          CLEAR ls_range_of_bezrunde.
        ENDIF.
      ENDIF.
*    PVA
      READ TABLE me->ir_pva WITH KEY low = ls_consdata-pva TRANSPORTING NO FIELDS.
      IF ( sy-subrc NE 0 ).
        ls_range_of_pva-sign = 'I'.
        ls_range_of_pva-option = 'EQ'.
        ls_range_of_pva-low = ls_consdata-pva.
        APPEND ls_range_of_pva TO me->ir_pva.
        CLEAR ls_range_of_pva.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD lese_jvtfehler.
    DATA: ls_consdata      TYPE ty_consdata,
          lt_consdata      TYPE me->tt_consdata,
          ls_jvtfehler     TYPE jvtfehler,
          lt_all_jvtfehler TYPE TABLE OF jvtfehler,
          lf_tabix         TYPE sy-tabix.

* Abopositionen lesen
    IF ( me->it_consdata IS INITIAL ).
      me->lese_abopositionen( ).
    ENDIF.

* Zugriffe auf JVTFEHLER
    IF NOT me->ir_bezirk[] IS INITIAL.
      SELECT * FROM jvtfehler INTO TABLE lt_all_jvtfehler
        WHERE vrsnddatum >= me->iv_refdatum_rueck AND vrsnddatum <= me->iv_refdatum_akt
          AND bezirk IN me->ir_bezirk
          AND fvart IN ('0002','0003','0004').
    ENDIF.
    IF NOT me->ir_pva[] IS INITIAL.
      SELECT * FROM jvtfehler APPENDING TABLE lt_all_jvtfehler
        WHERE fvart EQ '0005'
          AND vrsnddatum >= me->iv_refdatum_rueck AND vrsnddatum <= me->iv_refdatum_akt
          AND pva   IN me->ir_pva.
    ENDIF.

    SORT lt_all_jvtfehler BY fvnr.
    DELETE ADJACENT DUPLICATES FROM lt_all_jvtfehler COMPARING fvnr.

    LOOP AT lt_all_jvtfehler INTO ls_jvtfehler.
      LOOP AT me->it_consdata INTO ls_consdata.
        IF (     ls_consdata-gueltigvon <= ls_jvtfehler-vrsnddatum
             AND ls_consdata-gueltigbis >= ls_jvtfehler-vrsnddatum ).
          CASE ls_jvtfehler-fvart.
            WHEN '0002'.
              IF  ( ls_consdata-lieferart = ls_jvtfehler-lfartlog
                AND ls_consdata-bezirk = ls_jvtfehler-bezirk
                AND ls_consdata-pva = ls_jvtfehler-pva ).
                APPEND ls_jvtfehler TO me->it_jvtfehler.
              ENDIF.
            WHEN '0003'.
              IF  ( ls_consdata-lieferart = ls_jvtfehler-lfartlog
                AND ls_consdata-bezirk = ls_jvtfehler-bezirk ).
                APPEND ls_jvtfehler TO me->it_jvtfehler.
              ENDIF.
            WHEN '0004'.
              IF  ( ls_consdata-lieferart = ls_jvtfehler-lfartlog
                AND ls_consdata-bezirk = ls_jvtfehler-bezirk
                AND ls_consdata-bezrunde = ls_jvtfehler-bezrunde ).
                APPEND ls_jvtfehler TO me->it_jvtfehler.
              ENDIF.
            WHEN '0005'.
              IF ( ls_consdata-lieferart = ls_jvtfehler-lfartlog
                AND ls_consdata-pva = ls_jvtfehler-pva ).
                APPEND ls_jvtfehler TO me->it_jvtfehler.
              ENDIF.
          ENDCASE.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    SORT me->it_jvtfehler BY fvnr.
    DELETE ADJACENT DUPLICATES FROM me->it_jvtfehler COMPARING fvnr.

* Nur die Meldungen, zu denen keine Cockpitmeldung existiert
    LOOP AT me->it_jvtfehler INTO ls_jvtfehler.
      lf_tabix = sy-tabix.
      SELECT SINGLE COUNT(*) FROM /msh/stoer_t_lz WHERE fvnr = ls_jvtfehler-fvnr.
      CHECK sy-subrc = 0.
      DELETE me->it_jvtfehler INDEX lf_tabix.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
