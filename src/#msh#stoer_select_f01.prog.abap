*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_SELECT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init .
  REFRESH: gt_jvtfehler[],
           gt_stoer_dig[],
           gt_stoer_prod[],
           gt_stoer_gp[],
           gt_stoer_lief[].
ENDFORM.                    " INIT
*&---------------------------------------------------------------------*
*&      Form  SELECT_AUFTRAGSREKLA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_auftragsrekla .

  DATA: lf_tabix     TYPE sy-tabix,
        lv_checkdate TYPE dats,
        lv_ok        TYPE xfeld,
        ls_jkap      TYPE jkap,
        ls_selstring TYPE string.

  FIELD-SYMBOLS: <fs_jvtfehler> TYPE jvtfehler.

* Nur wenn p_ord gesetzt ist
  CHECK p_ord EQ 'X'.


    IF NOT s_fdat[] IS INITIAL.
      PERFORM set_selstring_ord CHANGING ls_selstring.
    ENDIF.
    IF NOT ls_selstring IS INITIAL.
      SELECT * FROM /msh/stoer_v_ord
        INTO CORRESPONDING FIELDS OF TABLE gt_jvtfehler
                    WHERE erfuser IN s_erfus
                      AND fvart EQ '0001'
                      AND erfdate IN s_erfd
                      AND erftime IN s_erft
                      AND aenuser IN s_aenus
                      AND aendate IN s_aend
                      AND aentime IN s_aent
                      AND vsgzustlr IN s_vsg
                      AND bezirk IN s_bezirk
                      AND fvgrund IN s_grund
                      AND bezrunde IN s_bezrd
                      AND route IN s_route
                      AND drerz IN s_drerz
                      AND pva IN s_pva
                      AND lfartlog IN s_lfart
                      AND fvverurs IN s_verurs
                      AND vbeln_bas IN s_vbeln
                      AND kunwe IN s_gpnr
                      AND xnachlief IN s_nlr
                      AND (ls_selstring).
    ELSE.
      SELECT * FROM /msh/stoer_v_ord
          INTO CORRESPONDING FIELDS OF TABLE gt_jvtfehler
             WHERE erfuser IN s_erfus
               AND fvart EQ '0001'
               AND erfdate IN s_erfd
               AND erftime IN s_erft
               AND aenuser IN s_aenus
               AND aendate IN s_aend
               AND aentime IN s_aent
               AND vsgzustlr IN s_vsg
               AND bezirk IN s_bezirk
               AND bezrunde IN s_bezrd
               AND fvgrund IN s_grund
               AND route IN s_route
               AND drerz IN s_drerz
               AND pva IN s_pva
               AND lfartlog IN s_lfart
               AND fvverurs IN s_verurs
               AND kunwe IN s_gpnr
               AND xnachlief IN s_nlr
               AND vbeln_bas IN s_vbeln.
    ENDIF.

ENDFORM.                    " SELECT_AUFTRAGSREKLA
*&---------------------------------------------------------------------*
*&      Form  SET_SELSTRING_ORD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_SELSTRING  text
*----------------------------------------------------------------------*
FORM set_selstring_ord  CHANGING ps_selstring TYPE string.

  DATA: lv_dathigh TYPE string,
        lv_datlow  TYPE string.

* Select-Option kann nur eine Zeile haben
  READ TABLE s_fdat INDEX 1.
  CONCATENATE '''' s_fdat-high '''' INTO lv_dathigh.
  CONCATENATE '''' s_fdat-low '''' INTO lv_datlow.
* Unterscheidung je nach Fall
* Fall 1: HIGH gesetzt LOW initial
  IF NOT s_fdat-high IS INITIAL AND s_fdat-low IS INITIAL.
    CONCATENATE 'GUELTIGBIS LE' lv_dathigh INTO ps_selstring SEPARATED BY space.
* Fall 2: HIGH und LOW gesetzt
  ELSEIF NOT s_fdat-high IS INITIAL AND NOT s_fdat-low IS INITIAL.
    CONCATENATE 'GUELTIGBIS LE' lv_dathigh 'AND GUELTIGBIS GE' lv_datlow INTO ps_selstring SEPARATED BY space.
* Fall 3: Nur LOW gesetzt
  ELSEIF s_fdat-high IS INITIAL AND NOT s_fdat-low IS INITIAL.
    CASE s_fdat-option(1).
      WHEN 'E'.
        CONCATENATE 'GUELTIGBIS GE' lv_datlow 'AND GUELTIGVON LE' lv_datlow INTO ps_selstring SEPARATED BY space.
      WHEN 'G'.
        CONCATENATE 'GUELTIGBIS' s_fdat-option lv_datlow INTO ps_selstring SEPARATED BY space.
      WHEN 'L'.
        CONCATENATE 'GUELTIGVON' s_fdat-option lv_datlow INTO ps_selstring SEPARATED BY space.
    ENDCASE.
  ENDIF.
ENDFORM.                    " SET_SELSTRING_ORD
*&---------------------------------------------------------------------*
*&      Form  SELECT_STOER_STANDARD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_stoer_standard .

  DATA: lf_tabix TYPE sy-tabix.

  FIELD-SYMBOLS: <fs_jvtfehler> TYPE jvtfehler.
* Nur wenn p_slief gesetzt ist
  CHECK p_slief EQ 'X'.

  SELECT * FROM jvtfehler
      APPENDING TABLE gt_jvtfehler
         WHERE erfuser IN s_erfus
           AND fvart IN s_fvart
           AND fvart NE '0001'
           AND erfdate IN s_erfd
           AND erftime IN s_erft
           AND aenuser IN s_aenus
           AND aendate IN s_aend
           AND aentime IN s_aent
           AND vsgzustlr IN s_vsg
           AND bezirk IN s_bezirk
           AND bezrunde IN s_bezrd
           AND route IN s_route
           AND drerz IN s_drerz
           AND pva IN s_pva
           AND fvgrund IN s_grund
           AND lfartlog IN s_lfart
           AND fvverurs IN s_verurs
           AND vbeln_bas IN s_vbeln
           AND xnachlief IN s_nlr
           AND vrsnddatum IN s_fdat.

* Die Standardmeldungen sollen nciht aus dem Cockpit kommen
  LOOP AT gt_jvtfehler ASSIGNING <fs_jvtfehler>.
    lf_tabix = sy-tabix.
    SELECT SINGLE COUNT(*) FROM /msh/stoer_t_lz WHERE fvnr = <fs_jvtfehler>-fvnr.
    CHECK sy-subrc = 0.
    DELETE gt_jvtfehler INDEX lf_tabix.
  ENDLOOP.
ENDFORM.                    " SELECT_STOER_STANDARD
*&---------------------------------------------------------------------*
*&      Form  SELECT_STOER_ENHANCED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_stoer_enhanced .

  DATA: lt_cust TYPE TABLE OF /msh/stoer_t_cst.

  FIELD-SYMBOLS: <fs_cust> TYPE /msh/stoer_t_cst.

* Nur wenn Parameter gesetzt
  CHECK p_elief EQ 'X'.

* Notwendige Bereiche ermitteln
  SELECT * FROM /msh/stoer_t_cst INTO TABLE lt_cust WHERE area_id IN s_areaid.

* Befüllungsroutinen je nach Bereich individuell
  LOOP AT lt_cust ASSIGNING <fs_cust>.
    CASE <fs_cust>-area_id.
      WHEN 'DG'.    "Digitalstörung
        PERFORM select_enh_digital.
      WHEN 'GP'.
        PERFORM select_enh_gp.
      WHEN 'LF'.
        PERFORM select_enh_lief.
      WHEN 'PR'.
        PERFORM select_enh_prod.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " SELECT_STOER_ENHANCED
*&---------------------------------------------------------------------*
*&      Form  SELECT_ENH_DIGITAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_enh_digital .

  DATA: lt_seltab    TYPE TABLE OF /msh/stoer_t_dig,
        ls_seltab    TYPE /msh/stoer_t_dig,
        ls_selstring TYPE string.
  DATA: ls_out     TYPE /msh/stoer_s_rek_out,
        lt_rektext TYPE TABLE OF tline.
  IF NOT s_fdat[] IS INITIAL.
    PERFORM set_selstring_ord CHANGING ls_selstring.
  ENDIF.

  "Nur wenn Bezirk nicht vorgegeben
  CHECK s_bezirk[] IS INITIAL.

  IF ls_selstring IS INITIAL.
    SELECT * FROM /msh/stoer_t_dig INTO TABLE lt_seltab WHERE
                  fvgrund IN s_grund AND
                  drerz_dig IN s_drerz AND
                  pva_dig IN s_pva AND
                  erfuser IN s_erfus AND
                  erfdate IN s_erfd
                  AND erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent.
  ELSE.
    SELECT * FROM /msh/stoer_t_dig INTO TABLE lt_seltab WHERE
            fvgrund IN s_grund AND
            drerz_dig IN s_drerz AND
            pva_dig IN s_pva AND
            erfuser IN s_erfus AND
            erfdate IN s_erfd AND
            erftime IN s_erft
            AND aenuser IN s_aenus
            AND aendate IN s_aend
            AND aentime IN s_aent AND
            (ls_selstring).
  ENDIF.

* In die Ausgabestruktur stellen
  LOOP AT lt_seltab INTO ls_seltab.
    CLEAR ls_out.
    MOVE-CORRESPONDING ls_seltab TO ls_out.
    ls_out-fehlerseit = ls_seltab-gueltigvon.
    ls_out-fehlerbis = ls_seltab-gueltigbis.
    SELECT SINGLE area FROM /msh/stoer_t_cst INTO ls_out-fvart WHERE area_id = 'DG'.
    SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = ls_seltab-fvgrund.
    ls_out-drerz = ls_seltab-drerz_dig.
    ls_out-pva = ls_seltab-pva_dig.
    IF ls_seltab-xcomment_dig EQ 'X'.
      REFRESH lt_rektext[].
      PERFORM read_text  IN PROGRAM /msh/stoer_maint USING 'DIG'
                                                           ls_seltab-stoerid
                                                     CHANGING lt_rektext.
      IF NOT lt_rektext[] IS INITIAL.
        CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
          EXPORTING
            it_tline       = lt_rektext
          IMPORTING
            ev_text_string = ls_out-t_beschw.
        REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ls_out-t_beschw WITH '/'.
      ENDIF.
    ENDIF.
    DATA: lv_short   TYPE t246-kurzt.
    "Sonntags bei DRERZ RHP auf RAS ändern
    IF ls_out-drerz = 'RHP'.
      CLEAR lv_short.
      CALL FUNCTION 'ISP_GET_WEEKDAY_NAME'
        EXPORTING
          date        = ls_out-fehlerseit
          language    = sy-langu
        IMPORTING
          shorttext   = lv_short
        EXCEPTIONS
          calendar_id = 1
          date_error  = 2
          not_found   = 3
          wrong_input = 4
          OTHERS      = 5.
      IF sy-subrc = 0 AND lv_short = 'SO'.
        ls_out-drerz = 'RAS'.
      ENDIF.
    ENDIF.
    APPEND ls_out TO gt_out.
*** Beschwerdetext bei einer Länge von > 54 trennen, da dieser sonst abgeschnitten wird.
*    PERFORM append_wrapped_lines
*                USING
*                  54
*                  ls_out.
  ENDLOOP.
ENDFORM.                    " SELECT_ENH_DIGITAL
*&---------------------------------------------------------------------*
*&      Form  BUILD_OUTTAB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_outtab .

  DATA: ls_out     TYPE /msh/stoer_s_rek_out,
        ls_jkpa    TYPE jkpa,
        ls_jgtsadr TYPE jgtsadr,
        lv_short   TYPE t246-kurzt.

  FIELD-SYMBOLS: <fs_jvtfehler> TYPE jvtfehler.

  LOOP AT gt_jvtfehler ASSIGNING <fs_jvtfehler>.
    CLEAR ls_out.
    MOVE-CORRESPONDING <fs_jvtfehler> TO ls_out.
    ls_out-vbeln = <fs_jvtfehler>-vbeln_bas.
    SELECT SINGLE gueltigvon FROM jkap INTO ls_out-fehlerseit WHERE vbeln = <fs_jvtfehler>-kvbeln.
    IF ls_out-fehlerseit IS INITIAL.
      ls_out-fehlerseit = <fs_jvtfehler>-vrsnddatum.
    ENDIF.
    SELECT SINGLE gueltigbis FROM jkap INTO ls_out-fehlerbis WHERE vbeln = <fs_jvtfehler>-kvbeln.
    IF ls_out-fehlerbis IS INITIAL.
      ls_out-fehlerbis = <fs_jvtfehler>-vrsnddatum.
    ENDIF.
    SELECT SINGLE langtext FROM tjv42 INTO ls_out-fvart WHERE spras EQ 'D' AND fvart = <fs_jvtfehler>-fvart.
    SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = <fs_jvtfehler>-fvgrund.
    PERFORM get_text USING <fs_jvtfehler>
                     CHANGING ls_out.
    IF <fs_jvtfehler>-fvart EQ '0001' AND NOT <fs_jvtfehler>-kvbeln IS INITIAL AND NOT <fs_jvtfehler>-kposnr IS INITIAL.
      SELECT SINGLE * FROM jkpa INTO ls_jkpa WHERE vbeln = <fs_jvtfehler>-kvbeln AND posnr = <fs_jvtfehler>-kposnr AND jparvw = 'WE'.
      IF sy-subrc = 0 AND NOT ls_jkpa-adrnr IS INITIAL.
        ls_out-gpnr = ls_jkpa-gpnr.
        SELECT SINGLE * FROM jgtsadr INTO ls_jgtsadr WHERE adrnr = ls_jkpa-adrnr.
        CALL FUNCTION 'ISP_ADDRESS_INTO_PRINTFORM'
          EXPORTING
            anschr_typ           = '1'
            sadrwa_in            = ls_jgtsadr
            zeilenzahl           = 5
          IMPORTING
            address_short_form_s = ls_out-shortaddr.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " BUILD_OUTTAB
*&---------------------------------------------------------------------*
*&      Form  GET_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<FS_JVTFEHLER>  text
*      <--P_LS_OUT  text
*----------------------------------------------------------------------*
FORM get_text  USING    ps_jvtfehler TYPE jvtfehler
               CHANGING ps_out TYPE /msh/stoer_s_rek_out.

* Nur wen Standardtext vorhanden
  CHECK NOT ( ps_jvtfehler-xkom1 IS INITIAL AND
              ps_jvtfehler-xkom2 IS INITIAL AND
              ps_jvtfehler-xkom3 IS INITIAL AND
              ps_jvtfehler-xkom4 IS INITIAL ).

  IF ps_jvtfehler-xkom1 EQ 'X'.
    PERFORM read_text USING 'KOM1'
                            ps_jvtfehler-fvnr
                      CHANGING ps_out-t_beschw.
    REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ps_out-t_beschw WITH '/'.
  ENDIF.
  IF ps_jvtfehler-xkom2 EQ 'X'.
    PERFORM read_text USING 'KOM2'
                            ps_jvtfehler-fvnr
                      CHANGING ps_out-t_nlinfo.
    REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ps_out-t_nlinfo WITH '/'.
  ENDIF.
  IF ps_jvtfehler-xkom3 EQ 'X'.
    PERFORM read_text USING 'KOM3'
                            ps_jvtfehler-fvnr
                      CHANGING ps_out-t_zusinfo.
    REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ps_out-t_zusinfo WITH '/'.
  ENDIF.
  IF ps_jvtfehler-xkom4 EQ 'X'.
    PERFORM read_text USING 'KOM4'
                            ps_jvtfehler-fvnr
                      CHANGING ps_out-t_stell.
    REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ps_out-t_stell WITH '/'.
  ENDIF.
ENDFORM.                    " GET_TEXT
*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0720   text
*      -->P_PS_JVTFEHLER_FVNR  text
*      <--P_PS_OUT_T_BESCHW  text
*----------------------------------------------------------------------*
FORM read_text  USING    pv_id TYPE tdid
                         pv_fvnr TYPE fvnr
                CHANGING ps_textstring TYPE cacl_string.

  DATA: wa_rekhead TYPE thead,
        lt_rektext TYPE TABLE OF tline.

  REFRESH lt_rektext[].

* Rekhead aufbauen (STELLUNGNAHME)
  wa_rekhead-tdid = pv_id.
  wa_rekhead-tdspras = 'D'.
  wa_rekhead-tdname = pv_fvnr.
  wa_rekhead-tdobject = 'JVTFEHLER'.

* Text lesen
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id       = wa_rekhead-tdid
      language = wa_rekhead-tdspras
      name     = wa_rekhead-tdname
      object   = wa_rekhead-tdobject
    TABLES
      lines    = lt_rektext
    EXCEPTIONS
      OTHERS   = 1.
  CHECK sy-subrc = 0.
  CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
    EXPORTING
      it_tline       = lt_rektext
    IMPORTING
      ev_text_string = ps_textstring.

ENDFORM.                    " READ_TEXT
*&---------------------------------------------------------------------*
*&      Form  SELECT_ENH_PROD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_enh_prod .
  DATA: lt_seltab    TYPE TABLE OF /msh/stoer_t_prd,
        ls_seltab    TYPE /msh/stoer_t_prd,
        ls_selstring TYPE string.
  DATA: ls_out     TYPE /msh/stoer_s_rek_out,
        lt_rektext TYPE TABLE OF tline.
  IF NOT s_fdat[] IS INITIAL.
    PERFORM set_selstring_ord CHANGING ls_selstring.
  ENDIF.

  IF ls_selstring IS INITIAL.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_seltab WHERE
                  fvgrund IN s_grund AND
                  drerz_prod IN s_drerz AND
                  pva_prod IN s_pva AND
                  bezirk_prod IN s_bezirk AND
                  erfuser IN s_erfus AND
                  erfdate IN s_erfd
                  AND erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent.
  ELSE.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_seltab WHERE
                  fvgrund IN s_grund AND
                  drerz_prod IN s_drerz AND
                  pva_prod IN s_pva AND
                  bezirk_prod IN s_bezirk AND
                  erfuser IN s_erfus AND
                  erfdate IN s_erfd AND
                  erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent AND
                  (ls_selstring).
  ENDIF.

* In die Ausgabestruktur stellen
  LOOP AT lt_seltab INTO ls_seltab.
    CLEAR ls_out.
    MOVE-CORRESPONDING ls_seltab TO ls_out.
    ls_out-fehlerseit = ls_seltab-gueltigvon.
    ls_out-fehlerbis = ls_seltab-gueltigbis.
*    ls_out-fvart = 'Produktionsstörung'.
    SELECT SINGLE area FROM /msh/stoer_t_cst INTO ls_out-fvart WHERE area_id = 'PR'.
    SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = ls_seltab-fvgrund.
    ls_out-drerz = ls_seltab-drerz_prod.
    ls_out-pva = ls_seltab-pva_prod.
    ls_out-bezirk = ls_seltab-bezirk_prod.
    IF ls_seltab-xcomment_prod EQ 'X'.
      REFRESH lt_rektext[].
      PERFORM read_text  IN PROGRAM /msh/stoer_maint USING 'PROD'
                                                           ls_seltab-stoerid
                                                     CHANGING lt_rektext.
      IF NOT lt_rektext[] IS INITIAL.
        CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
          EXPORTING
            it_tline       = lt_rektext
          IMPORTING
            ev_text_string = ls_out-t_beschw.
        REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ls_out-t_beschw WITH '/'.
      ENDIF.
    ENDIF.
    DATA: lv_short   TYPE t246-kurzt.
    "Sonntags bei DRERZ RHP auf RAS ändern
    IF ls_out-drerz = 'RHP'.
      CLEAR lv_short.
      CALL FUNCTION 'ISP_GET_WEEKDAY_NAME'
        EXPORTING
          date        = ls_out-fehlerseit
          language    = sy-langu
        IMPORTING
          shorttext   = lv_short
        EXCEPTIONS
          calendar_id = 1
          date_error  = 2
          not_found   = 3
          wrong_input = 4
          OTHERS      = 5.
      IF sy-subrc = 0 AND lv_short = 'SO'.
        ls_out-drerz = 'RAS'.
      ENDIF.
    ENDIF.
    APPEND ls_out TO gt_out.
*** Beschwerdetext bei einer Länge von > 54 trennen, da dieser sonst abgeschnitten wird.
*    PERFORM append_wrapped_lines
*                USING
*                  54
*                  ls_out.
  ENDLOOP.
ENDFORM.                    " SELECT_ENH_PROD
*&---------------------------------------------------------------------*
*&      Form  SELECT_ENH_GP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_enh_gp .
  DATA: lt_seltab    TYPE TABLE OF /msh/stoer_t_gp,
        ls_seltab    TYPE /msh/stoer_t_gp,
        ls_selstring TYPE string.
  DATA: ls_out     TYPE /msh/stoer_s_rek_out,
        lt_rektext TYPE TABLE OF tline.

  IF NOT s_fdat[] IS INITIAL.
    PERFORM set_selstring_ord CHANGING ls_selstring.
  ENDIF.

  IF ls_selstring IS INITIAL.
    SELECT * FROM /msh/stoer_t_gp INTO TABLE lt_seltab WHERE
                  fvgrund IN s_grund AND
                  gpnr IN s_gpnr AND
                  drerz IN s_drerz AND
                  pva IN s_pva AND
                  bezirk_gp IN s_bezirk AND
                  vsgzustlr IN s_vsg AND
                  route IN s_route AND
                  erfuser IN s_erfus AND
                  erfdate IN s_erfd
                  AND xnachlief IN s_nlr      "STOMSD-88
                  AND erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent.
  ELSE.
    SELECT * FROM /msh/stoer_t_gp INTO TABLE lt_seltab WHERE
                  fvgrund IN s_grund AND
                  gpnr IN s_gpnr AND
                  bezirk_gp IN s_bezirk AND
                  drerz IN s_drerz AND
                  pva IN s_pva AND
                  route IN s_route AND
                  vsgzustlr IN s_vsg AND
                  erfuser IN s_erfus AND
                  erfdate IN s_erfd AND
                  erftime IN s_erft
                  AND xnachlief IN s_nlr      "STOMSD-88
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent AND
                  (ls_selstring).
  ENDIF.

* In die Ausgabestruktur stellen
  LOOP AT lt_seltab INTO ls_seltab.
    CLEAR ls_out.
    MOVE-CORRESPONDING ls_seltab TO ls_out.
    ls_out-fehlerseit = ls_seltab-gueltigvon.
    ls_out-fehlerbis = ls_seltab-gueltigbis.
*    ls_out-fvart = 'Geschäftspartnerstörung'.
    SELECT SINGLE area FROM /msh/stoer_t_cst INTO ls_out-fvart WHERE area_id = 'GP'.
    SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = ls_seltab-fvgrund.
    ls_out-bezirk = ls_seltab-bezirk_gp.
    PERFORM build_addr_gp USING ls_seltab
                          CHANGING ls_out.
    IF ls_seltab-xcomment_gp EQ 'X'.
      REFRESH lt_rektext[].
      PERFORM read_text  IN PROGRAM /msh/stoer_maint USING 'GPNR'
                                                           ls_seltab-stoerid
                                                     CHANGING lt_rektext.
      IF NOT lt_rektext[] IS INITIAL.
        CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
          EXPORTING
            it_tline       = lt_rektext
          IMPORTING
            ev_text_string = ls_out-t_beschw.
        REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ls_out-t_beschw WITH '/'.
      ENDIF.
    ENDIF.
    DATA: lv_short   TYPE t246-kurzt.
    "Sonntags bei DRERZ RHP auf RAS ändern
    IF ls_out-drerz = 'RHP'.
      CLEAR lv_short.
      CALL FUNCTION 'ISP_GET_WEEKDAY_NAME'
        EXPORTING
          date        = ls_out-fehlerseit
          language    = sy-langu
        IMPORTING
          shorttext   = lv_short
        EXCEPTIONS
          calendar_id = 1
          date_error  = 2
          not_found   = 3
          wrong_input = 4
          OTHERS      = 5.
      IF sy-subrc = 0 AND lv_short = 'SO'.
        ls_out-drerz = 'RAS'.
      ENDIF.
    ENDIF.
    APPEND ls_out TO gt_out.
*** Beschwerdetext bei einer Länge von > 54 trennen, da dieser sonst abgeschnitten wird.
*    PERFORM append_wrapped_lines
*                USING
*                  54
*                  ls_out.

  ENDLOOP.
ENDFORM.                    " SELECT_ENH_GP
*&---------------------------------------------------------------------*
*&      Form  BUILD_ADDR_GP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_SELTAB  text
*      <--P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_addr_gp  USING    ps_seltab TYPE /msh/stoer_t_gp
                    CHANGING ps_out TYPE /msh/stoer_s_rek_out.

  DATA: ls_check TYPE rjkwww_address,
        ls_addr  TYPE jgtsadr.

  MOVE-CORRESPONDING ps_seltab TO ls_check.
  IF ls_check-name1 IS INITIAL.
    ls_check-name1 = '*'.
  ENDIF.

  CALL FUNCTION 'ISM_WWW_ADDRESS_CHECK_DIALOG'
    EXPORTING
      pv_xbatchmode     = 'X'
    CHANGING
      ps_rjkwww_address = ls_check
    EXCEPTIONS
      error_occurred    = 1
      warning_occurred  = 2
      OTHERS            = 3.
  CLEAR ls_addr.
  MOVE-CORRESPONDING ls_check TO ls_addr.
  CALL FUNCTION 'ISP_ADDRESS_INTO_PRINTFORM'
    EXPORTING
      anschr_typ           = '1'
      sadrwa_in            = ls_addr
      zeilenzahl           = 5
    IMPORTING
      address_short_form_s = ps_out-shortaddr.
  ps_out-name1 = ps_seltab-name1.
  ps_out-name2 = ps_seltab-name2.
  ps_out-stras = ps_seltab-stras.
  ps_out-hausn = ps_seltab-hausn.
  ps_out-hsnmr2 = ps_seltab-hsnmr2.
  ps_out-pstlz = ps_seltab-pstlz.
  ps_out-ort01 = ps_seltab-ort01.
ENDFORM.                    " BUILD_ADDR_GP
*&---------------------------------------------------------------------*
*&      Form  SELECT_ENH_LIEF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_enh_lief .
  DATA: lt_seltab    TYPE TABLE OF /msh/stoer_t_lf,
        ls_seltab    TYPE /msh/stoer_t_lf,
        ls_selstring TYPE string.
  DATA: ls_out       TYPE /msh/stoer_s_rek_out,
        lt_rektext   TYPE TABLE OF tline,
        lt_zuo       TYPE TABLE OF /msh/stoer_t_lz,
        ls_zuo       TYPE /msh/stoer_t_lz,
        ls_jvtfehler TYPE jvtfehler.

  IF NOT s_fdat[] IS INITIAL.
    PERFORM set_selstring_ord CHANGING ls_selstring.
  ENDIF.

  IF ls_selstring IS INITIAL.
    SELECT * FROM /msh/stoer_t_lf
       INTO TABLE lt_seltab
          WHERE erfuser IN s_erfus
            AND fvart IN s_fvart
            AND fvart NE '0001'
            AND erfdate IN s_erfd
            AND erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent
    AND vsgzustlr IN s_vsg
    AND bezirk IN s_bezirk
    AND bezrunde IN s_bezrd
    AND route IN s_route
    AND drerz IN s_drerz
    AND pva IN s_pva
    AND xnachlief IN s_nlr      "STOMSD-88
    AND fvgrund IN s_grund
    AND lfartlog IN s_lfart
    AND fvverurs IN s_verurs.
*    AND vkorg IN s_vkorg.        "Ausgeblendet STOMSD-88
  ELSE.
    SELECT * FROM /msh/stoer_t_lf
 INTO TABLE lt_seltab
    WHERE erfuser IN s_erfus
      AND fvart IN s_fvart
      AND fvart NE '0001'
      AND erfdate IN s_erfd
      AND erftime IN s_erft
                  AND aenuser IN s_aenus
                  AND aendate IN s_aend
                  AND aentime IN s_aent
    AND vsgzustlr IN s_vsg
    AND bezirk IN s_bezirk
    AND bezrunde IN s_bezrd
    AND route IN s_route
    AND drerz IN s_drerz
    AND pva IN s_pva
    AND fvgrund IN s_grund
    AND lfartlog IN s_lfart
    AND xnachlief IN s_nlr      "STOMSD-88
    AND fvverurs IN s_verurs AND
*    AND vkorg IN s_vkorg AND       "Ausgeblendet STOMSD-88
    (ls_selstring).
  ENDIF.

* Daten aufbereiten
  LOOP AT lt_seltab INTO ls_seltab.
    CLEAR ls_out.
    MOVE-CORRESPONDING ls_seltab TO ls_out.
*    ls_out-fvart = 'Lieferstörung erweitert'.
    SELECT SINGLE area FROM /msh/stoer_t_cst INTO ls_out-fvart WHERE area_id = 'LF'.
    SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = ls_seltab-fvgrund.
    IF ls_seltab-xcomment_lief EQ 'X'.
      REFRESH lt_rektext[].
      PERFORM read_text  IN PROGRAM /msh/stoer_maint USING 'LIEF'
                                                           ls_seltab-stoerid
                                                     CHANGING lt_rektext.
      IF NOT lt_rektext[] IS INITIAL.
        CALL FUNCTION 'IDMX_DI_TLINE_INTO_STRING'
          EXPORTING
            it_tline       = lt_rektext
          IMPORTING
            ev_text_string = ls_out-t_beschw.
        REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]' IN ls_out-t_beschw WITH '/'.
      ENDIF.
    ENDIF.
    IF ls_out-fehlerseit IS INITIAL.
      ls_out-fehlerseit = ls_seltab-gueltigvon.
    ENDIF.
    IF ls_out-fehlerbis IS INITIAL.
      ls_out-fehlerbis = ls_seltab-gueltigbis.
    ENDIF.
    DATA: lv_short   TYPE t246-kurzt.
    "Sonntags bei DRERZ RHP auf RAS ändern
    IF ls_out-drerz = 'RHP'.
      CLEAR lv_short.
      CALL FUNCTION 'ISP_GET_WEEKDAY_NAME'
        EXPORTING
          date        = ls_out-fehlerseit
          language    = sy-langu
        IMPORTING
          shorttext   = lv_short
        EXCEPTIONS
          calendar_id = 1
          date_error  = 2
          not_found   = 3
          wrong_input = 4
          OTHERS      = 5.
      IF sy-subrc = 0 AND lv_short = 'SO'.
        ls_out-drerz = 'RAS'.
      ENDIF.
    ENDIF.
    APPEND ls_out TO gt_out.
*** Beschwerdetext bei einer Länge von > 54 trennen, da dieser sonst abgeschnitten wird.
*    PERFORM append_wrapped_lines
*                USING
*                  54
*                  ls_out.

* Für jeden Eintrag die angelegten Standardmeldungen lesen
    IF p_mano IS INITIAL.
      REFRESH lt_zuo[].
      SELECT * FROM /msh/stoer_t_lz INTO TABLE lt_zuo WHERE stoerid = ls_seltab-stoerid.
      CHECK sy-subrc = 0.
      LOOP AT lt_zuo INTO ls_zuo.
        SELECT SINGLE * FROM jvtfehler INTO ls_jvtfehler WHERE fvnr = ls_zuo-fvnr.
        CHECK sy-subrc = 0.
        CLEAR ls_out.
        MOVE-CORRESPONDING ls_jvtfehler TO ls_out.
        ls_out-z_linec = 'C610'.
        ls_out-xauto = 'X'.
        ls_out-vbeln = ls_jvtfehler-vbeln_bas.
        SELECT SINGLE gueltigvon FROM jkap INTO ls_out-fehlerseit WHERE vbeln = ls_jvtfehler-kvbeln.
        IF ls_out-fehlerseit IS INITIAL.
          ls_out-fehlerseit = ls_jvtfehler-vrsnddatum.
        ENDIF.
        SELECT SINGLE gueltigbis FROM jkap INTO ls_out-fehlerbis WHERE vbeln = ls_jvtfehler-kvbeln.
        IF ls_out-fehlerbis IS INITIAL.
          ls_out-fehlerbis = ls_jvtfehler-vrsnddatum.
        ENDIF.
        SELECT SINGLE langtext FROM tjv42 INTO ls_out-fvart WHERE spras EQ 'D' AND fvart = ls_jvtfehler-fvart.
        SELECT SINGLE langtext FROM tjv44 INTO ls_out-fvgrund WHERE spras EQ 'D' AND fvgrund = ls_jvtfehler-fvgrund.
        PERFORM get_text USING ls_jvtfehler
                         CHANGING ls_out.
        APPEND ls_out TO gt_out.
*** Beschwerdetext bei einer Länge von > 54 trennen, da dieser sonst abgeschnitten wird.
*        PERFORM append_wrapped_lines
*                    USING
*                      54
*                      ls_out.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " SELECT_ENH_LIEF
*&---------------------------------------------------------------------*
*&      Form  OUT_ALV_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM out_alv_list .

  DATA: lv_repid   TYPE sy-repid,
*        ls_variant  TYPE disvariant,
*        ls_layout   TYPE slis_layout_alv,
        ls_exit_us TYPE slis_exit_by_user.
*        lt_fieldcat TYPE slis_t_fieldcat_alv.

  CLEAR lt_fieldcat.
  REFRESH lt_fieldcat.
* Programmname merken
  MOVE sy-repid TO lv_repid.

* Kein Deckblatt
  ls_print-no_print_selinfos  = 'X'.
  ls_print-no_print_listinfos = 'X'.

* Feldkatalog aufbereiten
  PERFORM set_fieldcat_alv CHANGING lt_fieldcat.

* Listdarstellung
  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  ls_layout-info_fieldname = 'Z_LINEC'.

* Varianten.
  ls_variant-report = lv_repid.

* Nur wenn angefordert
  CHECK p_alv EQ 'X'.

* Liste ausgeben
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_structure_name       = '/msh/stoer_s_rek_out'
      i_callback_program     = lv_repid
      is_layout              = ls_layout
      it_fieldcat            = lt_fieldcat
      it_sort                = lt_sortinfo
      i_save                 = 'A'
      is_variant             = ls_variant
      is_print               = ls_print
      i_grid_title           = 'Selektierte Meldungen'
    IMPORTING
      es_exit_caused_by_user = ls_exit_us
    TABLES
      t_outtab               = gt_out.

ENDFORM.                    " OUT_ALV_LIST
*&---------------------------------------------------------------------*
*&      Form  SET_FIELDCAT_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM set_fieldcat_alv  CHANGING pt_fieldcat TYPE slis_t_fieldcat_alv.

  DATA: ls_fieldcat LIKE LINE OF pt_fieldcat.

* Feldkatalog holen
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/msh/stoer_s_rek_out'
    CHANGING
      ct_fieldcat            = pt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  CHECK sy-subrc = 0.

  LOOP AT pt_fieldcat INTO ls_fieldcat.
    CASE ls_fieldcat-fieldname.
      WHEN 'SHORTADDR'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Kurzadresse'.
        ls_fieldcat-seltext_s = 'Kurzadr.'.
      WHEN 'FVART'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Störungsart'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Art'.
      WHEN 'FVGRUND'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Reklamationsgrund'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Grund'.
      WHEN 'FEHLERBIS'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Fehlt bis'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Fehlt bis'.
      WHEN 'T_BESCHW'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Beschwerdetext'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Bechwerde'.
      WHEN 'T_NLINFO'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Nachlieferinfo'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'NL-Info'.
      WHEN 'T_ZUSINFO'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Zustellerinfo'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'ZU-Info'.
      WHEN 'T_STELL'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Stellungnahme'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Stellg.'.
      WHEN 'XAUTO'.
        ls_fieldcat-seltext_m = ls_fieldcat-seltext_l = 'Autom. angelegt'.
        ls_fieldcat-seltext_s = ls_fieldcat-reptext_ddic = 'Autom.'.
    ENDCASE.
    MODIFY pt_fieldcat FROM ls_fieldcat.
  ENDLOOP.
ENDFORM.                    " SET_FIELDCAT_ALV
*&---------------------------------------------------------------------*
*&      Form  OUT_SPOOL_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM out_spool_list .

* Typ für Ausgabe Selektionsbild
  TYPES: BEGIN OF t_varinfo,
           flag    TYPE c,
           olength TYPE x,
           line    LIKE raldb-infoline,
         END OF t_varinfo.
* Daten für Ausgabe Selektionsbild
  DATA: tables  TYPE trdir-name OCCURS 0 WITH HEADER LINE,
        infotab TYPE t_varinfo OCCURS 0 WITH HEADER LINE.
  DATA: vl_spool TYPE tsp01-rqident.
  DATA: vl_layout TYPE pri_params-paart,
        vl_lines  TYPE pri_params-linct,
        vl_cols   TYPE pri_params-linsz,
        vl_valid  TYPE c,
        ls_print  TYPE slis_print_alv,
        lv_error  TYPE xfeld,
        lv_spono  TYPE sy-spono.

  DATA: lv_repid       TYPE sy-repid,
        ls_variant_tmp TYPE disvariant,
        ls_layout      TYPE slis_layout_alv,
        ls_exit_us     TYPE slis_exit_by_user,
        lt_fieldcat    TYPE slis_t_fieldcat_alv,
        lt_list        TYPE sp01r_id_list,
        ls_list        LIKE LINE OF lt_list.

* Nur wenn angefordert
  CHECK p_spo EQ 'X'.

  vl_layout  = 'X_65_255'.
  vl_lines   = 65.
  vl_cols    = 255.
  CALL FUNCTION 'GET_PRINT_PARAMETERS'
    EXPORTING
      no_dialog              = 'X'
      layout                 = vl_layout
      line_count             = vl_lines
      line_size              = vl_cols
    IMPORTING
      out_archive_parameters = ls_print-print_ctrl-arc_params
      out_parameters         = ls_print-print_ctrl-pri_params
      valid                  = vl_valid
    EXCEPTIONS
      archive_info_not_found = 1
      invalid_print_params   = 2
      invalid_archive_params = 3
      OTHERS                 = 4.
  IF vl_valid NE space AND sy-subrc = 0.
    CLEAR lv_error.
    ls_print-print_ctrl-pri_params-prrel = space.
*    ls_print-print_ctrl-pri_params-primm = space.
    NEW-PAGE PRINT ON
    NEW-SECTION
    PARAMETERS ls_print-print_ctrl-pri_params
    ARCHIVE PARAMETERS ls_print-print_ctrl-arc_params
    NO DIALOG.

    ls_print-print              = 'X'.
    ls_print-no_print_selinfos  = space.
    ls_print-no_print_listinfos = space.

* Layout aufbauen
    IF NOT p_vari IS INITIAL.
      MOVE-CORRESPONDING ls_variant TO ls_variant_tmp.
    ELSE.
      ls_variant_tmp-report = lv_repid = sy-repid.
    ENDIF.

    ls_layout-colwidth_optimize = 'X'.
    ls_layout-zebra = 'X'.
    ls_layout-info_fieldname = 'Z_LINEC'.

* Feldkatalog aufbereiten
    PERFORM set_fieldcat_alv CHANGING lt_fieldcat.

* Liste ausgeben
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_structure_name = '/msh/stoer_s_rek_out'
        is_layout        = ls_layout
        it_fieldcat      = lt_fieldcat
        i_save           = 'A'
        is_variant       = ls_variant_tmp
        i_grid_title     = 'Selektierte Meldungen'
        is_print         = ls_print
      TABLES
        t_outtab         = gt_out.
    NEW-PAGE PRINT OFF.
    lv_spono = sy-spono.
  ELSE.
    lv_error = 'X'.
  ENDIF.

  IF sy-batch EQ 'X'.
* STEP1: Selektionsbild ausgeben
*    CALL FUNCTION 'PRINT_SELECTIONS'
*      EXPORTING
*        mode      = tables
*        rname     = sy-repid
*        rvariante = space
*      TABLES
*        infotab   = infotab.
*    LOOP AT infotab.
*      WRITE: / infotab-line.
*    ENDLOOP.
*    SKIP 1.
*    WRITE sy-uline NO-GAP.
*    SKIP 1.
*    IF lv_error = 'X'.
*      WRITE: / 'Fehler bei der Anlage der Spoolliste.'.
*    ELSE.
*      WRITE: / 'Spool Liste', lv_spono, 'wurde erstellt'.
*    ENDIF.
  ELSE.
    REFRESH lt_list[].
    ls_list-id = lv_spono.
    ls_list-sysid = sy-sysid.
    APPEND ls_list TO lt_list.
    CALL FUNCTION 'RSPO_RID_SPOOLREQ_DISP'
      EXPORTING
        id_list = lt_list
      EXCEPTIONS
        error   = 1
        OTHERS  = 2.
  ENDIF.



ENDFORM.                    " OUT_SPOOL_LIST
*&---------------------------------------------------------------------*
*&      Form  OUT_CSV_MAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM out_csv_mail .

  DATA: lv_tablestring  TYPE string,
        lv_tablexstring TYPE xstring.
  DATA:   lt_binarytable TYPE solix_tab.
  DATA:  lc_send_request TYPE REF TO cl_bcs VALUE IS INITIAL.
  DATA: lo_sender TYPE REF TO if_sender_bcs VALUE IS INITIAL.
  DATA: lo_recipient TYPE REF TO if_recipient_bcs VALUE IS INITIAL.
  DATA: lv_adr TYPE ad_smtpadr.

  DATA: lo_document TYPE REF TO cl_document_bcs VALUE IS INITIAL.
  DATA: i_text TYPE bcsy_text.
  DATA: w_text LIKE LINE OF i_text.
  DATA: lv_sub TYPE so_obj_des.
  DATA: lv_datex(10) TYPE c.

* Spezielle Variantendaten
  DATA: lt_fcat_vari TYPE slis_t_fieldcat_alv.

* Daten für Ausgabe Selektionsbild
  TYPES: BEGIN OF t_varinfo,
           flag    TYPE c,
           olength TYPE x,
           line    LIKE raldb-infoline,
         END OF t_varinfo.
  DATA: tables  TYPE trdir-name OCCURS 0 WITH HEADER LINE,
        infotab TYPE t_varinfo OCCURS 0 WITH HEADER LINE.

* Nur wenn angefordert
  CHECK p_mail EQ 'X'.

* Mailobjekt anlegen
  CLASS cl_bcs DEFINITION LOAD.
  lc_send_request = cl_bcs=>create_persistent( ).

* Mailbody
  CONCATENATE 'Anbei die selektierten Reklamationen und Störungsmeldungen.' cl_abap_char_utilities=>cr_lf INTO w_text-line.
  APPEND w_text TO i_text.
  CLEAR w_text.
  CONCATENATE 'Sie finden die Daten als CSV-File im Anhang..' cl_abap_char_utilities=>cr_lf INTO w_text-line.
  APPEND w_text TO i_text.
  CLEAR w_text.
  CONCATENATE 'Die Selektion erfolge mit folgenden Parametern:' cl_abap_char_utilities=>cr_lf INTO w_text-line.
  APPEND w_text TO i_text.
  CLEAR w_text.
  w_text-line = cl_abap_char_utilities=>cr_lf.
  APPEND w_text TO i_text.
  CALL FUNCTION 'PRINT_SELECTIONS'
    EXPORTING
      mode      = tables
      rname     = sy-repid
      rvariante = space
    TABLES
      infotab   = infotab.
  LOOP AT infotab.
    CLEAR w_text.
    w_text-line = infotab-line.
    APPEND w_text TO i_text.
  ENDLOOP.
* Subjekt und Dokument anlegen
  CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
    EXPORTING
      date_internal            = sy-datum
    IMPORTING
      date_external            = lv_datex
    EXCEPTIONS
      date_internal_is_invalid = 1
      OTHERS                   = 2.
  CONCATENATE 'Reklamationsliste vom' lv_datex INTO lv_sub SEPARATED BY space.
  lo_document = cl_document_bcs=>create_document(
                                  i_type = 'TXT'
                                  i_text =  i_text
                                  i_subject = lv_sub ).

* Dokument übergeben
  lc_send_request->set_document( lo_document ).

* Tabelle in einen CSV-String umwandeln
  IF p_vari IS INITIAL.
    PERFORM convert_to_string CHANGING lv_tablestring.
  ELSE.
    PERFORM get_fieldcat_vari CHANGING lt_fcat_vari.
    IF lt_fcat_vari[] IS INITIAL.
      PERFORM convert_to_string CHANGING lv_tablestring.
    ELSE.
      PERFORM convert_to_string_vari  USING lt_fcat_vari
                                      CHANGING lv_tablestring.
    ENDIF.
  ENDIF.
* String in UTF8-XSTRING
*  TRY.
*      CALL METHOD cl_bics_cons_webitem_util=>string_2_utf8_xstring
*        EXPORTING
*          i_string       = lv_tablestring
*        RECEIVING
*          r_utf8_xstring = lv_tablexstring.
*    CATCH cx_bics_cons_webitem_error .
*      EXIT.
*  ENDTRY.
  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text     = lv_tablestring
*     MIMETYPE = ' '
      encoding = '1101'
    IMPORTING
      buffer   = lv_tablexstring
    EXCEPTIONS
      failed   = 1
      OTHERS   = 2.
  IF  sy-subrc NE 0.
    PERFORM mess_mail USING 'X'.
    EXIT.
  ENDIF.


* XSTRING in Binärtabelle
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer     = lv_tablexstring
    TABLES
      binary_tab = lt_binarytable.

* Attachment anhängen
  CONCATENATE 'reklist_' sy-datum '_' sy-uzeit INTO lv_sub.
  CONDENSE lv_sub.
  TRY.
      lo_document->add_attachment( EXPORTING
                                      i_attachment_type = 'CSV'
                                      i_attachment_subject = lv_sub
                                      i_att_content_hex = lt_binarytable  ).
    CATCH cx_document_bcs.
      PERFORM mess_mail USING 'X'.
      EXIT.
  ENDTRY.

* Sender
  TRY.
      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
      lc_send_request->set_sender(
      EXPORTING
      i_sender = lo_sender ).
    CATCH cx_address_bcs.
      PERFORM mess_mail USING 'X'.
      EXIT.
  ENDTRY.

* Empfänger
  lv_adr = p_madr.
  lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_adr ).
  TRY.
      lc_send_request->add_recipient(
          EXPORTING
          i_recipient = lo_recipient
          i_express = 'X' ).
    CATCH cx_send_req_bcs.
      PERFORM mess_mail USING 'X'.
      EXIT.
  ENDTRY.

*Sofort senden setzen
  TRY.
      CALL METHOD lc_send_request->set_send_immediately
        EXPORTING
          i_send_immediately = 'X'.
    CATCH cx_send_req_bcs.
      PERFORM mess_mail USING 'X'.
      EXIT.
  ENDTRY.

* Senden
  TRY.
      lc_send_request->send(
      EXPORTING
      i_with_error_screen = 'X' ).
      COMMIT WORK.
      IF sy-subrc = 0.
*???
      ENDIF.
    CATCH cx_send_req_bcs.
      PERFORM mess_mail USING 'X'.
      EXIT.
  ENDTRY.

* MEssage
  PERFORM mess_mail USING space.
ENDFORM.                    " OUT_CSV_MAIL
*&---------------------------------------------------------------------*
*&      Form  CONVERT_TO_STRING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LV_TABLESTRING  text
*----------------------------------------------------------------------*
FORM convert_to_string  CHANGING cv_tablestring TYPE string.

  DATA: lt_dfies   TYPE TABLE OF dfies,
        lv_tabline TYPE string,
        lv_field   TYPE string,
        lv_set     TYPE abap_bool.

  FIELD-SYMBOLS: <fs_dfies> TYPE dfies,
                 <fs_out>   TYPE /msh/stoer_s_rek_out,
                 <fv_val>   TYPE any.

  DATA : lc(1) TYPE c VALUE ' '.

* Löschen
  CLEAR cv_tablestring.

* FEldstruktur lesen
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = '/msh/stoer_s_rek_out'
    TABLES
      dfies_tab      = lt_dfies
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  CHECK sy-subrc = 0.

* HEADER
  CLEAR lv_tabline.
  LOOP AT lt_dfies ASSIGNING <fs_dfies>.
    CHECK <fs_dfies>-fieldname NE 'Z_LINEC'.
    IF lv_tabline IS INITIAL.
      lv_tabline =  <fs_dfies>-fieldname.
    ELSE.
      CONCATENATE lv_tabline <fs_dfies>-fieldname INTO lv_tabline SEPARATED BY ';'.
    ENDIF.
  ENDLOOP.
  cv_tablestring = lv_tabline.

* Loop je Zeile der GT_OUT
  CLEAR lv_set.
  LOOP AT gt_out ASSIGNING <fs_out>.
    CLEAR lv_tabline.
    LOOP AT lt_dfies ASSIGNING <fs_dfies>.
      CHECK <fs_dfies>-fieldname NE 'Z_LINEC'.
      CONCATENATE '<FS_OUT>-' <fs_dfies>-fieldname INTO lv_field.
      UNASSIGN <fv_val>.
      ASSIGN (lv_field) TO <fv_val>.
      CHECK <fv_val> IS ASSIGNED.
      REPLACE ALL OCCURRENCES OF ';' IN <fv_val> WITH space.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]+(?!$)' IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]+$' IN <fv_val> WITH ` `.
      IF sy-tabix = 1.
        IF NOT <fv_val> IS INITIAL.
          lv_tabline = <fv_val>.
        ELSE.
          lv_tabline = space.
        ENDIF.
      ELSE.
        CONCATENATE lv_tabline <fv_val> INTO lv_tabline SEPARATED BY ';'.
      ENDIF.
*      IF lv_tabline IS INITIAL.
*        IF NOT <fv_val> IS INITIAL.
*          lv_tabline = <fv_val>.
*        ELSE.
*          IF sy-tabix = 1.
*            lv_tabline = space.
*            lv_set = abap_true.
*          ELSE.
*            lv_tabline = ';'.
*          ENDIF.
*        ENDIF.
*      ELSE.
*        CONCATENATE lv_tabline <fv_val> INTO lv_tabline SEPARATED BY ';'.
*      ENDIF.
    ENDLOOP.
    CONCATENATE cv_tablestring lv_tabline INTO cv_tablestring SEPARATED BY cl_abap_char_utilities=>newline.
    CLEAR lv_tabline.
  ENDLOOP.
ENDFORM.                    " CONVERT_TO_STRING
*&---------------------------------------------------------------------*
*&      Form  MESS_MAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_3218   text
*----------------------------------------------------------------------*
FORM mess_mail  USING    pv_error TYPE xfeld.
  DATA: ls_mess TYPE string.
  IF pv_error = 'X'.
    IF sy-batch IS INITIAL.
      MESSAGE e039 WITH p_madr.
    ELSE.
      MESSAGE e039 WITH p_madr INTO ls_mess.
      WRITE: / ls_mess.
    ENDIF.
  ELSE.
    IF sy-batch IS INITIAL.
      MESSAGE i040 WITH p_madr.
    ELSE.
      MESSAGE i040 WITH p_madr INTO ls_mess.
      WRITE: / ls_mess.
    ENDIF.
  ENDIF.
ENDFORM.                    " MESS_MAIL
*&---------------------------------------------------------------------*
*&      Form  GET_FIELDCAT_VARI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FCAT_VARI  text
*----------------------------------------------------------------------*
FORM get_fieldcat_vari  CHANGING   pt_fcat_vari TYPE slis_t_fieldcat_alv.

  REFRESH pt_fcat_vari[].

  CALL FUNCTION 'REUSE_ALV_VARIANT_SELECT'
    EXPORTING
      i_dialog            = space
      i_user_specific     = 'X'
*     I_DEFAULT           = 'X'
*     I_TABNAME_HEADER    =
*     I_TABNAME_ITEM      =
      it_default_fieldcat = lt_fieldcat
      i_layout            = ls_layout
*     I_BYPASSING_BUFFER  =
*     I_BUFFER_ACTIVE     =
    IMPORTING
*     E_EXIT              =
      et_fieldcat         = pt_fcat_vari
*     ET_SORT             =
*     ET_FILTER           =
*     ES_LAYOUT           =
    CHANGING
      cs_variant          = ls_variant
    EXCEPTIONS
      wrong_input         = 1
      fc_not_complete     = 2
      not_found           = 3
      program_error       = 4
      OTHERS              = 5.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  DELETE pt_fcat_vari WHERE no_out EQ 'X'.
  SORT pt_fcat_vari BY col_pos.
ENDFORM.                    " GET_FIELDCAT_VARI
*&---------------------------------------------------------------------*
*&      Form  CONVERT_TO_STRING_VARI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_FCAT_VARI  text
*      <--P_LV_TABLESTRING  text
*----------------------------------------------------------------------*
FORM convert_to_string_vari  USING    pt_fcat_vari TYPE slis_t_fieldcat_alv
                             CHANGING cv_tablestring TYPE string.

  DATA: lt_fieldc TYPE lvc_t_fcat,
        dyn_tab   TYPE REF TO data,
        ls_out    LIKE LINE OF gt_out.

  DATA: lt_dfies   TYPE TABLE OF dfies,
        lv_tabline TYPE string,
        lv_field   TYPE string.

  FIELD-SYMBOLS: <fs_dfies> TYPE lvc_s_fcat,
                 <fs_out>   TYPE /msh/stoer_s_rek_out,
                 <fv_val>   TYPE any.

  DATA : lc(1) TYPE c VALUE ' '.

  FIELD-SYMBOLS: <dyn_tab>  TYPE STANDARD TABLE,
                 <dyn_line> TYPE any.
* Feldkatalog
  CALL FUNCTION 'LVC_TRANSFER_FROM_SLIS'
    EXPORTING
      it_fieldcat_alv = pt_fcat_vari
    IMPORTING
      et_fieldcat_lvc = lt_fieldc
    TABLES
      it_data         = gt_out
    EXCEPTIONS
      it_data_missing = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

* Dynamische Tabelle
  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog  = lt_fieldc
      i_length_in_byte = 'X'
    IMPORTING
      ep_table         = dyn_tab.
  ASSIGN dyn_tab->* TO <dyn_tab>.
  CHECK <dyn_tab> IS ASSIGNED.

* Daten überstellen
  LOOP AT gt_out INTO ls_out.
    APPEND INITIAL LINE TO <dyn_tab> ASSIGNING <dyn_line>.
    MOVE-CORRESPONDING ls_out TO <dyn_line>.
  ENDLOOP.

* HEADER
  CLEAR lv_tabline.
  LOOP AT lt_fieldc ASSIGNING <fs_dfies>.
    CHECK <fs_dfies>-fieldname NE 'Z_LINEC'.
    IF lv_tabline IS INITIAL.
      lv_tabline =  <fs_dfies>-fieldname.
    ELSE.
      CONCATENATE lv_tabline <fs_dfies>-fieldname INTO lv_tabline SEPARATED BY ';'.
    ENDIF.
  ENDLOOP.
  cv_tablestring = lv_tabline.

* Loop je Zeile der GT_OUT
  LOOP AT <dyn_tab> ASSIGNING <dyn_line>.
    CLEAR lv_tabline.
    LOOP AT lt_fieldc ASSIGNING <fs_dfies>.
      CHECK <fs_dfies>-fieldname NE 'Z_LINEC'.
      CONCATENATE '<DYN_LINE>-' <fs_dfies>-fieldname INTO lv_field.
      UNASSIGN <fv_val>.
      ASSIGN (lv_field) TO <fv_val>.
      CHECK <fv_val> IS ASSIGNED.
      REPLACE ALL OCCURRENCES OF ';' IN <fv_val> WITH space.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]+(?!$)' IN <fv_val> WITH ` `.
      REPLACE ALL OCCURRENCES OF REGEX '[^[:print:]]+$' IN <fv_val> WITH ` `.
      IF sy-tabix = 1.
        IF NOT <fv_val> IS INITIAL.
          lv_tabline = <fv_val>.
        ELSE.
          lv_tabline = space.
        ENDIF.
      ELSE.
        CONCATENATE lv_tabline <fv_val> INTO lv_tabline SEPARATED BY ';'.
      ENDIF.
*      IF lv_tabline IS INITIAL.
*        IF NOT <fv_val> IS INITIAL.
*          lv_tabline = <fv_val>.
*        ELSE.
*          IF sy-tabix = 1.
*            lv_tabline = space.
*          ELSE.
*            lv_tabline = ';'.
*          ENDIF.
*        ENDIF.
*      ELSE.
*        CONCATENATE lv_tabline <fv_val> INTO lv_tabline SEPARATED BY ';'.
*      ENDIF.
    ENDLOOP.
    CONCATENATE cv_tablestring lv_tabline INTO cv_tablestring SEPARATED BY cl_abap_char_utilities=>newline.
    CLEAR lv_tabline.
  ENDLOOP.
ENDFORM.                    " CONVERT_TO_STRING_VARI
*&---------------------------------------------------------------------*
*&      Form  WRAP_LINE_AT_POS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM wrap_line_at_pos USING ps_txtline TYPE string
                            pv_index TYPE i
                      CHANGING pt_itab TYPE string_table.
  FIELD-SYMBOLS: <fs_char> TYPE any.

  DATA:  lv_len  TYPE i,
         lr_data TYPE REF TO data.
  CLEAR: pt_itab.

  lv_len = strlen( ps_txtline ).

  CREATE DATA lr_data TYPE c LENGTH lv_len.

  ASSIGN lr_data->* TO <fs_char>.

  MOVE ps_txtline TO <fs_char>.
*  <fs_char> = ps_txtline.

  CALL FUNCTION 'RKD_WORD_WRAP'
    EXPORTING
      textline            = <fs_char>
      outputlen           = pv_index
    TABLES
      out_lines           = pt_itab
    EXCEPTIONS
      outputlen_too_large = 1
      OTHERS              = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.                    " WRAP_LINE_AT_POS
*&---------------------------------------------------------------------*
*&      Form  APPEND_WRAPPED_LINES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM append_wrapped_lines USING pv_offset TYPE i
                                ps_out TYPE /msh/stoer_s_rek_out.
  DATA:
    lt_itab_str TYPE TABLE OF string,
    ls_line     LIKE LINE OF lt_itab_str,
    lv_str      TYPE string,
    lv_stoerid  TYPE /msh/stoerid,
    lv_cr_lf    TYPE abap_cr_lf.

  CLEAR: lt_itab_str, ls_line, lv_str.

  lv_stoerid = ps_out-stoerid.

  IF strlen( ps_out-t_beschw ) > pv_offset.
* String vorher nach cr_lf durchsuchen und ein Leerzeichen davor setzen.
    lv_cr_lf = cl_abap_char_utilities=>cr_lf.
    IF ps_out-t_beschw CS lv_cr_lf.
      lv_str = ps_out-t_beschw.
      REPLACE ALL OCCURRENCES OF lv_cr_lf IN lv_str WITH ` ` IN CHARACTER MODE.
    ELSE.
      lv_str = ps_out-t_beschw.
    ENDIF.

    PERFORM wrap_line_at_pos
                USING
                   lv_str
                   pv_offset
                CHANGING
                   lt_itab_str
                  .

    LOOP AT lt_itab_str INTO ls_line.
      ps_out-t_beschw = ls_line.
      ps_out-stoerid = lv_stoerid.
      APPEND ps_out TO gt_out.
      CLEAR: ps_out.
    ENDLOOP.

  ELSE.
    APPEND ps_out TO gt_out.
  ENDIF.
ENDFORM.                    " APPEND_WRAPPED_LINES
*&---------------------------------------------------------------------*
*&      Form  OUT_SPOOL_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM out_spool_layout .
* <-- aw20180409
  DATA: ls_out      TYPE /msh/stoer_s_rek_out,
        lt_copy_out TYPE TABLE OF /msh/stoer_s_rek_out,
        lv_index    TYPE i,
        save_vsg    TYPE vsgzustlr.

  CLEAR:    save_vsg,
            ls_out,
            lv_vdat_von,
            lv_vdat_bis,
            lt_copy_out.
  REFRESH:  lt_copy_out.

* Initialisierung globale Felder
  CLEAR: lv_vbeln, lv_vsgzustlr.

  IF p_spo EQ 'X'.

* Tabelle vorher nach VSG sortieren
    SORT gt_out BY vsgzustlr erfdate erftime aendate aentime.

* Versanddatum von (min) and bis(max) festlegen
    lt_copy_out = gt_out.

    DESCRIBE TABLE lt_copy_out LINES lv_index.

    SORT lt_copy_out BY fehlerseit fehlerbis ASCENDING.
    READ TABLE lt_copy_out INDEX 1 INTO ls_out.
    IF NOT s_fdat[] IS INITIAL.
      READ TABLE s_fdat ASSIGNING FIELD-SYMBOL(<fs_fdat>) INDEX 1.
      lv_vdat_von = <fs_fdat>-low.
    ELSE.
      lv_vdat_von = ls_out-fehlerseit.
    ENDIF.


    READ TABLE lt_copy_out INDEX lv_index INTO ls_out.
    lv_vdat_bis = ls_out-fehlerbis.

*Ausgabe der Störungsmeldungen
    LOOP AT gt_out INTO ls_out.
*    lv_index = sy-tabix.
*    IF lv_index = 1.
*      lv_count = 1.
**      PERFORM build_header USING ls_out lv_count.
*    ENDIF.

*    lv_vbeln      = ls_out-vbeln.
      lv_vsgzustlr  = ls_out-vsgzustlr.

      IF save_vsg NE ls_out-vsgzustlr.
*      lv_count      = lv_count + 1.
*     Seitenwechsel
*      PERFORM build_header USING ls_out lv_count.
        NEW-PAGE.
      ENDIF.
*   Merker setzen
      save_vsg = ls_out-vsgzustlr.

*   Ausgabe der Daten
      PERFORM build_first_line  USING ls_out.
      PERFORM build_second_line USING ls_out.
      PERFORM build_third_line  USING ls_out.
      PERFORM build_fourth_line USING ls_out.
      PERFORM build_fifth_line USING ls_out.

      SKIP 2.

    ENDLOOP.
  ENDIF.

ENDFORM.                    " OUT_SPOOL_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIRST_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_first_line USING ps_out TYPE /msh/stoer_s_rek_out.

  WRITE: /000 ps_out-route(6),
              010 ps_out-drerz(8),
              020 ps_out-pva(8).

  IF ps_out-zgemvon IS NOT INITIAL.
    WRITE: 036 ps_out-zgemvon(30).
  ENDIF.

  IF ps_out-erfdate IS NOT INITIAL.
    WRITE:  60  ps_out-erfdate.
  ENDIF.

  IF ps_out-erftime IS NOT INITIAL.
    WRITE:  71  ps_out-erftime.
  ENDIF.

  IF  ps_out-route    IS INITIAL AND
      ps_out-drerz    IS INITIAL AND
      ps_out-pva      IS INITIAL AND
      ps_out-zgemvon  IS INITIAL AND
      ps_out-erfdate  IS INITIAL AND
      ps_out-erftime  IS INITIAL.
    SKIP.
  ENDIF.

ENDFORM.                    " BUILD_FIRST_LINE
*&---------------------------------------------------------------------*
*&      Form  BUILD_SECOND_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_second_line  USING ps_out TYPE /msh/stoer_s_rek_out.
  DATA: lt_str TYPE TABLE OF swastrtab,
        lv_str TYPE string,
        ls_str TYPE swastrtab,
        lv_len TYPE i.

  CLEAR: lv_str, lt_str, lv_len.

  REFRESH: lt_str.

  WRITE: /000 ps_out-bezirk(10),
          010 ps_out-xbezliegt(1),
          020 ps_out-xbezspaet(1).

  IF ps_out-nleuhrzeit IS NOT INITIAL.
    WRITE: 024 ps_out-nleuhrzeit.
  ENDIF.
* Zeilenumbruch ab 23 Zeichen, da Länge = 50 (<= 80 insgesamt)

  lv_len = strlen( ps_out-fvgrund ).
  IF lv_len >= 23.
    lv_str = ps_out-fvgrund.

    CALL FUNCTION 'SWA_STRING_SPLIT'
      EXPORTING
        input_string                 = lv_str
        max_component_length         = 23
      TABLES
        string_components            = lt_str
      EXCEPTIONS
        max_component_length_invalid = 1
        OTHERS                       = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    LOOP AT lt_str INTO ls_str.
      IF sy-tabix = 1.
        WRITE: 036 ls_str-str.
      ELSE.
        WRITE: /036 ls_str-str.
      ENDIF.

    ENDLOOP.

  ELSE.
    WRITE:  036 ps_out-fvgrund(23).
  ENDIF.

  IF ps_out-aendate IS NOT INITIAL.
    WRITE:  60  ps_out-aendate.
  ENDIF.

  IF ps_out-aentime IS NOT INITIAL.
    WRITE:  71  ps_out-aentime.
  ENDIF.

  IF  ps_out-bezirk     IS INITIAL AND
      ps_out-xbezliegt  IS INITIAL AND
      ps_out-xbezspaet  IS INITIAL AND
      ps_out-nledatum   IS INITIAL AND
      ps_out-fvgrund    IS INITIAL AND
      ps_out-aendate    IS INITIAL AND
      ps_out-aentime    IS INITIAL.
    SKIP.
  ENDIF.

ENDFORM.                    " BUILD_SECOND_LINE
*&---------------------------------------------------------------------*
*&      Form  BUILD_THIRD_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_third_line  USING ps_out TYPE /msh/stoer_s_rek_out.

  DATA: lt_str   TYPE TABLE OF swastrtab,
        lv_str   TYPE string,
        t_beschw TYPE string,
        ls_str   TYPE swastrtab,
        lv_len   TYPE i.

  CLEAR: lv_str, lt_str, lv_len.

  WRITE: /000 ps_out-xnachlief(1),
          010 ps_out-gpnr(10).

* Zeilenumbruch ab 60 Zeichen, da Länge = 80 (<= 80 insgesamt)
  lv_len = strlen( ps_out-shortaddr ).
  IF lv_len > 60.
    lv_str = ps_out-shortaddr.
    CALL FUNCTION 'SWA_STRING_SPLIT'
      EXPORTING
        input_string                 = lv_str
        max_component_length         = 60
      TABLES
        string_components            = lt_str
      EXCEPTIONS
        max_component_length_invalid = 1
        OTHERS                       = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    LOOP AT lt_str INTO ls_str.
      t_beschw = replace(  val   = ls_str-str
                regex = '#+'
                with  = ' '
                occ   = 0           ).
      IF sy-tabix = 1.
        WRITE: 020 t_beschw.
      ELSE.
        WRITE: /020 t_beschw.
      ENDIF.

    ENDLOOP.

  ELSE.
    WRITE:  020 ps_out-shortaddr(60).
  ENDIF.


  IF  ps_out-xnachlief  IS INITIAL AND
      ps_out-gpnr       IS INITIAL AND
      ps_out-shortaddr  IS INITIAL.
    SKIP.
  ENDIF.

ENDFORM.                    " BUILD_THIRD_LINE
*&---------------------------------------------------------------------*
*&      Form  BUILD_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_header.

*  DATA: lv_site   TYPE string,
*        lv_numstr TYPE string.
*
*  CLEAR: lv_site.
*
*  lv_numstr = lv_count.
*
*  CONCATENATE con_seite lv_numstr INTO lv_site SEPARATED BY space.

* Versandservicegesellschaftsinfo
  WRITE: /000 lv_vsgzustlr(10).
*          072 lv_site.

* 1. Zeile
  WRITE: /000 con_route(5),
          010 con_drerz(5),
          020 con_pva(3),
          036 con_gemeldet_von(12),
          060 con_angelegt_am(9),
          071 con_angelegt_um(9).

* 2. Zeile
  WRITE: /000 con_bezirk(6),
          010 con_xbezliegt(9),
          020 con_verspaetung(3),
          024 con_zustellende(11),
          036 con_rekla_grd(17),
          060 con_geaendert_am(9),
          071 con_geaendert_um(9).

* 3. Zeile
  WRITE: /000 con_nachliefern(3),
          010 con_gpnr(6),
          020 con_kurzadresse(11).

  ULINE AT /000(80).

ENDFORM.                    " BUILD_HEADER
*&---------------------------------------------------------------------*
*&      Form  BUILD_TOP_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_top_header.

  DATA: lv_site   TYPE string,
        lv_numstr TYPE string.

  CLEAR: lv_site.

  lv_numstr = lv_count.

  CONCATENATE con_seite lv_numstr INTO lv_site SEPARATED BY space.

* Titelzeilen
  WRITE: /000 con_title_stmsd(24),
          072 lv_site.
  WRITE: /000 con_versanddatum(10),
          015 lv_vdat_von,
*          025 con_bis_zeichen,
*          026 lv_vdat_bis,
          045 con_listerzeugung(14),
          060 sy-datum,
          071 sy-uzeit.

  ULINE AT /000(80).

ENDFORM.                    " BUILD_TOP_HEADER
*&---------------------------------------------------------------------*
*&      Form  BUILD_FOURTH_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_fourth_line USING ps_out TYPE /msh/stoer_s_rek_out.

  DATA: lv_len TYPE i,
        lv_str TYPE string,
        lt_str TYPE TABLE OF swastrtab,
        ls_str TYPE swastrtab.

* Optional, wenn Beschwerdetext vorhanden ist.
  IF ps_out-t_beschw IS NOT INITIAL.
    WRITE: /010 'Beschwerdetext:'.
    lv_len = strlen( ps_out-t_beschw ).
    IF lv_len > 70.
      lv_str = ps_out-t_beschw.
      CALL FUNCTION 'SWA_STRING_SPLIT'
        EXPORTING
          input_string                 = lv_str
          max_component_length         = 70
        TABLES
          string_components            = lt_str
        EXCEPTIONS
          max_component_length_invalid = 1
          OTHERS                       = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

      LOOP AT lt_str INTO ls_str.
        IF sy-tabix = 1.
          IF NOT ps_out-shortaddr IS INITIAL.
            WRITE: /010 ls_str-str.
          ENDIF.
          WRITE: 010 ls_str-str.
        ELSE.
          WRITE: /010 ls_str-str.
        ENDIF.
      ENDLOOP.
    ELSE.
      WRITE: /010 ps_out-t_beschw.
    ENDIF.
  ENDIF.

ENDFORM.                    " BUILD_FOURTH_LINE
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIFTH_LINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_OUT  text
*----------------------------------------------------------------------*
FORM build_fifth_line  USING ps_out TYPE /msh/stoer_s_rek_out.

  DATA: lv_len TYPE i,
        lv_str TYPE string,
        lt_str TYPE TABLE OF swastrtab,
        ls_str TYPE swastrtab.

* Optional, wenn Beschwerdetext vorhanden ist.
  IF ps_out-t_nlinfo IS NOT INITIAL.
    WRITE: /010 'Nachlieferinfo::'.
    lv_len = strlen( ps_out-t_nlinfo ).
    IF lv_len > 70.
      lv_str = ps_out-t_nlinfo.
      CALL FUNCTION 'SWA_STRING_SPLIT'
        EXPORTING
          input_string                 = lv_str
          max_component_length         = 70
        TABLES
          string_components            = lt_str
        EXCEPTIONS
          max_component_length_invalid = 1
          OTHERS                       = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

      LOOP AT lt_str INTO ls_str.
        IF sy-tabix = 1.
          IF NOT ps_out-shortaddr IS INITIAL.
            WRITE: /010 ls_str-str.
          ENDIF.
          WRITE: 010 ls_str-str.
        ELSE.
          WRITE: /010 ls_str-str.
        ENDIF.
      ENDLOOP.
    ELSE.
      WRITE: /010 ps_out-t_nlinfo.
    ENDIF.
  ENDIF.

ENDFORM.
