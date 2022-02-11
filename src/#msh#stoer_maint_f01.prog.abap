*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize .
  IF gv_snew IS INITIAL.
    CLEAR: gv_called,
           gv_changemode,
           gv_time,
           gv_rektext,
           /msh/stoer_s_top,
           /msh/stoer_s_dig,
           /msh/stoer_s_prod,
           /msh/stoer_s_gp,
           /msh/stoer_s_lief,
           gs_cust,
           gv_area,
           gv_exist,
           gv_stoerid,
           gv_openforedit,
           gv_stoertext,
           gv_stoerid_old,
           gs_0230_old.

    REFRESH: gt_cust[],
             gt_chgtext[],
             gt_jvtfehler_exist[].

    PERFORM clear_subsequent .
  ELSE.

  ENDIF.
ENDFORM.                    " INITIALIZE
*&---------------------------------------------------------------------*
*&      Form  CHECK_DATES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_dates .

* Gültigkeitsbeginn muß gefüllt sein
  IF /msh/stoer_s_top-gueltigvon IS INITIAL.
    CLEAR ok_0100.
    MESSAGE e001.
  ENDIF.

* Gültigkeitsende darf nicht kleiner als der Beginn sein
  IF NOT /msh/stoer_s_top-gueltigbis IS INITIAL AND /msh/stoer_s_top-gueltigbis LT /msh/stoer_s_top-gueltigvon.
    CLEAR ok_0100.
    MESSAGE e002.
  ENDIF.
ENDFORM.                    " CHECK_DATES
*&---------------------------------------------------------------------*
*&      Form  SWITCH_TO_0120
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM switch_to_0120 .
* Wenn kein Gültigkeitsende angegeben, dann den Beginn nehmen
  IF /msh/stoer_s_top-gueltigbis IS INITIAL.
    /msh/stoer_s_top-gueltigbis = /msh/stoer_s_top-gueltigvon.
  ENDIF.
* Screen setzen
  IF gv_changemode IS INITIAL.
    gv_dynnr = '0120'.
  ELSE.
    gv_dynnr = gv_dynnr_change.
  ENDIF.
ENDFORM.                    " SWITCH_TO_0120
*&---------------------------------------------------------------------*
*&      Form  SET_TEXT_0120
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_text_0120 .
  MESSAGE i003 WITH /msh/stoer_s_top-gueltigvon /msh/stoer_s_top-gueltigbis INTO gv_time.
ENDFORM.                    " SET_TEXT_0120
*&---------------------------------------------------------------------*
*&      Form  CHANGE_DATES_0110
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM change_dates_0110 .
* Alle Eingaben danach gehen verloren
  PERFORM clear_subsequent.
  gv_dynnr = '0110'.
ENDFORM.                    " CHANGE_DATES_0110
*&---------------------------------------------------------------------*
*&      Form  PRELOAD_GLOBAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM preload_global .
* Globale Datenstrukturen vorfüllen (Performance)
  SELECT * FROM /msh/stoer_t_cst INTO TABLE gt_cust.
  SORT gt_cust BY area_order ASCENDING.
ENDFORM.                    " PRELOAD_GLOBAL
*&---------------------------------------------------------------------*
*&      Form  F4_AREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_area .
  DATA: ld_field   TYPE vrm_id,
        it_listbox TYPE vrm_values,
        wa_listbox LIKE LINE OF it_listbox.

* Feld setzen
  ld_field = 'GV_AREA'.

  REFRESH it_listbox[].

  LOOP AT gt_cust INTO gs_cust.
    wa_listbox-key = gs_cust-area_id.
    wa_listbox-text = gs_cust-area.
    APPEND wa_listbox TO it_listbox.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = ld_field
      values = it_listbox.
ENDFORM.                    " F4_AREA
*&---------------------------------------------------------------------*
*&      Form  CHECK_AREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_area .
  DATA: lv_cnt TYPE i.

* Störungsbereich muß vorhanden sein
  IF gv_area IS INITIAL.
    MESSAGE e004.
  ENDIF.

* Störungsbereich muß valide sein und nur 1x vorhanden
  CLEAR lv_cnt.
  LOOP AT gt_cust INTO gs_cust WHERE area_id = gv_area.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.
  IF sy-subrc NE 0 OR lv_cnt NE 1.
    MESSAGE e005.
  ENDIF.

* Das angegebene Pflegebild muß vorhanden sein
  SELECT SINGLE COUNT(*) FROM d020s
          WHERE prog = gs_cust-area_repid AND
                dnum = gs_cust-area_dynnr AND
                type = 'I'.
  IF sy-subrc NE 0.
    MESSAGE e006 WITH gs_cust-area_dynnr gs_cust-area_repid.
  ENDIF.

ENDFORM.                    " CHECK_AREA
*&---------------------------------------------------------------------*
*&      Form  SWITCH_TO_NEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM switch_to_next .
* Screen setzen, ebenso Report-ID
  gv_dynnr = gs_cust-area_dynnr.
  gv_repid = gs_cust-area_repid.

* Editmodus setzen
  gv_openforedit = 'X'.
ENDFORM.                    " SWITCH_TO_NEXT
*&---------------------------------------------------------------------*
*&      Form  CLEAR_SUBSEQUENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_subsequent .
  CHECK gv_changemode IS INITIAL.
  CLEAR: gv_area,
         gs_cust,
         gv_openforedit.
  IF NOT gc_meld IS INITIAL.
    CALL METHOD gc_meld->free.
    CLEAR gc_meld.
  ENDIF.
  IF NOT gc_meld_det IS INITIAL.
    CALL METHOD gc_meld_det->free.
    CLEAR gc_meld_det.
  ENDIF.
  PERFORM clear_textviews.
  PERFORM clear_0210.
  PERFORM clear_0240.
  PERFORM clear_0220.
  PERFORM clear_0230.
ENDFORM.                    " CLEAR_SUBSEQUENT
*&---------------------------------------------------------------------*
*&      Form  CHANGE_AREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM change_area .
  gv_dynnr = '0120'.
  gv_repid = sy-repid.
  IF NOT gc_meld IS INITIAL.
    CALL METHOD gc_meld->free.
    CLEAR gc_meld.
  ENDIF.
  PERFORM clear_subsequent.
ENDFORM.                    " CHANGE_AREA
*&---------------------------------------------------------------------*
*&      Form  F4_GRUND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_grund .
  TYPES: BEGIN OF ty_help,
           fvgrund  TYPE fvgrund,
           langtext TYPE bezeichn50,
         END OF ty_help.

  DATA: lt_help   TYPE TABLE OF ty_help,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_field  TYPE TABLE OF dynpread,
        ls_field  TYPE dynpread.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'FVGRUND'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = '/MSH/STOER_S_TOP-FVGRUND'
      window_title    = 'Grund wählen'
      display         = ' '
    TABLES
      value_tab       = lt_help
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  CHECK sy-subrc = 0.
* SH kann nur eine Zeile haben
  READ TABLE lt_return INTO ls_return INDEX 1.
  CHECK sy-subrc = 0.
  SELECT SINGLE langtext FROM tjv44 INTO gv_rektext WHERE spras = sy-langu AND fvgrund = ls_return-fieldval.

* Dynprofeld updaten
  IF NOT gv_rektext IS INITIAL.
    REFRESH lt_field[].
    ls_field-fieldname = 'GV_REKTEXT'.
    ls_field-fieldvalue = gv_rektext.
    APPEND ls_field TO lt_field.
    ls_field-fieldname = '/MSH/STOER_S_TOP-FVGRUND'.
    ls_field-fieldvalue = ls_return-fieldval.
    APPEND ls_field TO lt_field.
    CALL FUNCTION 'DYNP_VALUES_UPDATE'
      EXPORTING
        dyname               = sy-repid
        dynumb               = sy-dynnr
      TABLES
        dynpfields           = lt_field
      EXCEPTIONS
        invalid_abapworkarea = 1
        invalid_dynprofield  = 2
        invalid_dynproname   = 3
        invalid_dynpronummer = 4
        invalid_request      = 5
        no_fielddescription  = 6
        undefind_error       = 7
        OTHERS               = 8.
  ENDIF.
ENDFORM.                    " F4_GRUND
*&---------------------------------------------------------------------*
*&      Form  CREATE_CONT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0082   text
*      -->P_GV_TEXTDISPLAY_0210  text
*      -->P_GV_TEXTVIEW_0210  text
*----------------------------------------------------------------------*
FORM create_cont  USING    cont_name TYPE scrfname
                  CHANGING pv_textdisplay TYPE REF TO cl_gui_custom_container
                           pv_textview TYPE REF TO cl_gui_textedit.

  IF pv_textdisplay IS INITIAL.
    CREATE OBJECT pv_textdisplay
      EXPORTING
        container_name = cont_name.
  ENDIF.

  IF pv_textview IS INITIAL.
    CREATE OBJECT pv_textview
      EXPORTING
        parent                     = pv_textdisplay
        style                      = 0
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_windowborder
        wordwrap_position          = con_text_line_length
        wordwrap_to_linebreak_mode = cl_gui_textedit=>false
      EXCEPTIONS
        OTHERS                     = 1.
    IF sy-subrc = 0.
      CALL METHOD pv_textview->set_statusbar_mode
        EXPORTING
          statusbar_mode         = 0
        EXCEPTIONS
          error_cntl_call_method = 1
          invalid_parameter      = 2
          OTHERS                 = 3.
      CALL METHOD pv_textview->set_toolbar_mode
        EXPORTING
          toolbar_mode           = 0
        EXCEPTIONS
          error_cntl_call_method = 1
          invalid_parameter      = 2
          OTHERS                 = 3.
    ENDIF.
  ENDIF.
ENDFORM.                    " CREATE_CONT
*&---------------------------------------------------------------------*
*&      Form  SELECT_EXISTENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_existent USING pv_dynnr TYPE sy-dynnr.

  IF gc_meld IS INITIAL.
    CREATE OBJECT gc_meld
      EXPORTING
        i_parent = gc_cont_meld.
    SET HANDLER lcl_dclick_meld=>on_double_click FOR gc_meld.
  ENDIF.
  CLEAR gv_exist.
  CASE pv_dynnr.
    WHEN '0210'.
      PERFORM select_exist_dig.
    WHEN '0240'.
      PERFORM select_exist_prod.
    WHEN '0220'.
      PERFORM select_exist_gp.
    WHEN '0230'.
      PERFORM select_exist_lief.
  ENDCASE.
ENDFORM.                    " SELECT_EXISTENT
*&---------------------------------------------------------------------*
*&      Form  PAI_0210
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM pai_0210 .

* Grund darf nicht leer sein
  IF /msh/stoer_s_top-fvgrund IS INITIAL.
    MESSAGE e007.
  ENDIF.

* DRERZ darf nicht leer sein
  IF /msh/stoer_s_dig-drerz_dig IS INITIAL.
    MESSAGE e013.
  ENDIF.

* PVA muß zum DRERZ passen
  IF NOT /msh/stoer_s_dig-drerz_dig IS INITIAL AND NOT /msh/stoer_s_dig-pva_dig IS INITIAL.
    SELECT SINGLE COUNT(*) FROM jdtpva WHERE drerz = /msh/stoer_s_dig-drerz_dig  AND pva = /msh/stoer_s_dig-pva_dig.
    IF sy-subrc NE 0.
      MESSAGE e008 WITH /msh/stoer_s_dig-pva_dig /msh/stoer_s_dig-drerz_dig.
    ENDIF.
  ENDIF.

ENDFORM.                    " PAI_0210
*&---------------------------------------------------------------------*
*&      Form  CHECK_AND_SET_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_DYNNR  text
*----------------------------------------------------------------------*
FORM check_and_set_text  USING    pv_dynnr TYPE sy-dynnr
                         CHANGING pt_text TYPE text_table_type.

  DATA: lv_textedit TYPE string.
  DATA : loc_updkz TYPE i.

  FIELD-SYMBOLS: <f_textedit> TYPE REF TO cl_gui_textedit.

  CASE pv_dynnr.
    WHEN '0210'.
      lv_textedit = 'GV_TEXTVIEW_0210'.
    WHEN '0240'.
      lv_textedit = 'GV_TEXTVIEW_0240'.
    WHEN '0220'.
      lv_textedit = 'GV_TEXTVIEW_0220'.
    WHEN '0230'.
      lv_textedit = 'GV_TEXTVIEW_0230'.
  ENDCASE.

* Assigned?
  UNASSIGN <f_textedit>.
  ASSIGN (lv_textedit) TO <f_textedit>.

* Text vorhanden?
  REFRESH pt_text[].
  CALL METHOD <f_textedit>->get_text_as_stream
    IMPORTING
      text                   = pt_text
      is_modified            = loc_updkz
    EXCEPTIONS
      error_dp               = 1
      error_cntl_call_method = 2
      OTHERS                 = 3.
ENDFORM.                    " CHECK_AND_SET_TEXT
*&---------------------------------------------------------------------*
*&      Form  SAVE_0210
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_0210 .
  DATA: ls_stoer TYPE /msh/stoer_t_dig.
  DATA: lt_text TYPE text_table_type.
  DATA: lv_error TYPE xfeld.

* Abfrage
  CLEAR lv_error.
  PERFORM ask_save CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    EXIT.
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



* Text prüfen
  PERFORM check_and_set_text USING '0210'
                             CHANGING lt_text.
  IF NOT lt_text[] IS INITIAL.
    /msh/stoer_s_dig-xcomment_dig = 'X'.
  ELSE.
    CLEAR /msh/stoer_s_dig-xcomment_dig.
  ENDIF.

* Daten moven
  ls_stoer-mandt = sy-mandt.
  MOVE-CORRESPONDING /msh/stoer_s_top TO ls_stoer.
  MOVE-CORRESPONDING /msh/stoer_s_dig TO ls_stoer.
  IF gv_changemode IS INITIAL.
    ls_stoer-erfuser = sy-uname.
    ls_stoer-erfdate = sy-datum.
    ls_stoer-erftime = sy-uzeit.
  ELSE.
    SELECT SINGLE erfuser erfdate erftime INTO
            (ls_stoer-erfuser, ls_stoer-erfdate, ls_stoer-erftime)
           FROM /msh/stoer_t_dig WHERE stoerid = gv_stoerid.
    ls_stoer-aenuser = sy-uname.
    ls_stoer-aendate = sy-datum.
    ls_stoer-aentime = sy-uzeit.
  ENDIF.

* Text sichern
  PERFORM save_text USING lt_text
                          ls_stoer-stoerid
                          'DIG'
                    CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    MESSAGE e009.
  ENDIF.

* DB-Update
  CLEAR ok_0100.
  MODIFY /msh/stoer_t_dig FROM ls_stoer.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE s010 WITH 'Digitale Störungsmeldung' ls_stoer-stoerid.
* Startscreen
    PERFORM back_to_start.
  ELSE.
    MESSAGE e009.
  ENDIF.


ENDFORM.                    " SAVE_0210
*&---------------------------------------------------------------------*
*&      Form  SAVE_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_TEXT  text
*      -->P_LS_STOER_STOERID  text
*      -->P_0744   text
*      <--P_LV_ERROR  text
*----------------------------------------------------------------------*
FORM save_text  USING    pt_text TYPE text_table_type
                         pv_stoerid TYPE /msh/stoerid
                         pv_area TYPE tdid
                CHANGING pv_error TYPE xfeld.

  DATA: wa_header TYPE  thead,
        itc_lines TYPE ism_tline_tab.

* Header aufbauen
  CLEAR wa_header.
  wa_header-tdobject = '/MSH/STOER'.
  wa_header-tdname = pv_stoerid.
  wa_header-tdid = pv_area.
  wa_header-tdspras = 'D'.
  wa_header-tdform = 'SYSTEM'.
  wa_header-tdfuser = sy-uname.
  wa_header-tdfdate = sy-datum.
  wa_header-tdftime = sy-uzeit.
  wa_header-tdlinesize = '072'.

* Text konvertieren
  CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
    TABLES
      text_stream = pt_text
      itf_text    = itc_lines.

* Und sichern
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

* DB-COMMIT
  IF sy-subrc = 0.
    CALL FUNCTION 'COMMIT_TEXT'
      EXPORTING
        object   = wa_header-tdobject
        name     = wa_header-tdname
        id       = wa_header-tdid
        language = wa_header-tdspras.
  ELSE.
    pv_error = 'X'.
  ENDIF.
ENDFORM.                    " SAVE_TEXT
*&---------------------------------------------------------------------*
*&      Form  ASK_SAVE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LV_ERROR  text
*----------------------------------------------------------------------*
FORM ask_save  CHANGING pv_error TYPE xfeld.

  DATA: lv_answ(1) TYPE c.

* Bestehende Meldungen?
  IF gv_exist EQ 'X' AND gv_changemode IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Es gibt bestehende Meldungen'
        text_question         = 'Trotz bestehender Meldungen sichern?'
        text_button_1         = 'Ja'
        text_button_2         = 'Nein'
        default_button        = '1'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answ
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0.
      pv_error = 'X'.
    ELSE.
      IF lv_answ NE '1'.
        pv_error = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.
*  ENDIF.

ENDFORM.                    " ASK_SAVE
*&---------------------------------------------------------------------*
*&      Form  BACK_TO_START
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM back_to_start .
  PERFORM initialize.
  IF gv_snew IS INITIAL.
    IF gv_changemode IS INITIAL.
      gv_dynnr = '0100'.
    ELSE.
      gv_dynnr = '0300'.
    ENDIF.
  ELSE.
    CLEAR gv_snew.
  ENDIF.
ENDFORM.                    " BACK_TO_START
*&---------------------------------------------------------------------*
*&      Form  SELECT_EXIST_DIG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_exist_dig .
  DATA: lt_stoer_dig TYPE TABLE OF /msh/stoer_t_dig,
        ls_stoer_dig TYPE /msh/stoer_t_dig,
        lt_exist     TYPE TABLE OF /msh/stoer_s_exist_dig,
        ls_exist     TYPE /msh/stoer_s_exist_dig,
        lt_text      TYPE TABLE OF tline,
        lv_name      TYPE thead-tdname.
  DATA: ls_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat.

  REFRESH lt_exist[].

  IF gv_changemode IS INITIAL.
    SELECT * FROM /msh/stoer_t_dig INTO TABLE lt_stoer_dig WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                           AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                           AND drerz_dig = /msh/stoer_s_dig-drerz_dig
                                                           AND pva_dig = /msh/stoer_s_dig-pva_dig.
  ELSE.
    SELECT * FROM /msh/stoer_t_dig INTO TABLE lt_stoer_dig WHERE gueltigbis GE sy-datum.
  ENDIF.

  IF sy-subrc = 0.
    gv_exist = 'X'.
    LOOP AT lt_stoer_dig INTO ls_stoer_dig.
      CLEAR ls_exist.
      MOVE-CORRESPONDING ls_stoer_dig TO ls_exist.
      SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_dig-fvgrund.
      IF ls_stoer_dig-xcomment_dig EQ 'X'.
        REFRESH lt_text[].
        lv_name = ls_stoer_dig-stoerid.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'DIG'
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
      APPEND ls_exist TO lt_exist.
    ENDLOOP.
* Feldkatalog bauen
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = '/MSH/STOER_S_EXIST_DIG'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = lt_fieldcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    LOOP AT lt_fieldcat INTO ls_fieldcat.
      CASE ls_fieldcat-fieldname.
        WHEN 'STOERID'.
          ls_fieldcat-no_out = 'X'.
        WHEN 'GRUND'.
          ls_fieldcat-coltext = 'Störungsgrund'.
        WHEN 'KOMMENTAR'.
          ls_fieldcat-coltext = 'Kommentar'.
      ENDCASE.
      MODIFY lt_fieldcat FROM ls_fieldcat.
    ENDLOOP.
* Tabelle zum ALV schicken
    ls_layout-no_keyfix = 'X'.
    ls_layout-cwidth_opt = 'X'.
    ls_layout-sgl_clk_hd = 'X'.
    ls_layout-no_toolbar = 'X'.
    ls_layout-smalltitle = 'X'.
    ls_layout-grid_title = 'Bereits vorhandene Digitalstörungen'.
    gt_exist_dig[] = lt_exist[].
    IF gv_changemode IS INITIAL.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.
      CALL METHOD gc_meld->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_dig
          it_fieldcatalog = lt_fieldcat.
    ELSE.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.
      CALL METHOD gc_meld_det->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_dig
          it_fieldcatalog = lt_fieldcat.
    ENDIF.
  ENDIF.


ENDFORM.                   " SELECT_EXIST_DIG
*&---------------------------------------------------------------------*
*&      Form  CLEAR_TEXTVIEWS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_textviews .
* TExtview 210
  IF NOT gv_textview_0210 IS INITIAL.
    CALL METHOD gv_textview_0210->delete_text.
  ENDIF.
* TExtview 240
  IF NOT gv_textview_0240 IS INITIAL.
    CALL METHOD gv_textview_0240->delete_text.
  ENDIF.
* TExtview 220
  IF NOT gv_textview_0220 IS INITIAL.
    CALL METHOD gv_textview_0220->delete_text.
  ENDIF.
* TExtview 230
  IF NOT gv_textview_0230 IS INITIAL.
    CALL METHOD gv_textview_0230->delete_text.
  ENDIF.
ENDFORM.                    " CLEAR_TEXTVIEWS
*&---------------------------------------------------------------------*
*&      Form  CLEAR_0210
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_0210 .
  CLEAR: /msh/stoer_s_dig,
         /msh/stoer_s_top-fvgrund,
         gv_rektext.
ENDFORM.                    " CLEAR_0210
*&---------------------------------------------------------------------*
*&      Form  PAI_0240
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM pai_0240 .
* Grund darf nicht leer sein
  IF /msh/stoer_s_top-fvgrund IS INITIAL.
    MESSAGE e007.
  ENDIF.

* DRERZ darf nicht leer sein
  IF /msh/stoer_s_prod-drerz_prod IS INITIAL.
    MESSAGE e013.
  ENDIF.

* PVA muß zum DRERZ passen
  IF NOT /msh/stoer_s_prod-drerz_prod IS INITIAL AND NOT /msh/stoer_s_prod-pva_prod IS INITIAL.
    SELECT SINGLE COUNT(*) FROM jdtpva WHERE drerz = /msh/stoer_s_prod-drerz_prod  AND pva = /msh/stoer_s_prod-pva_prod.
    IF sy-subrc NE 0.
      MESSAGE e008 WITH /msh/stoer_s_prod-pva_prod /msh/stoer_s_prod-drerz_prod.
    ENDIF.
  ENDIF.

* Route auf Tagesrelevanz prüfen
  PERFORM check_route USING /msh/stoer_s_prod-route
                      CHANGING /msh/stoer_s_top.

ENDFORM.                    " PAI_0240
*&---------------------------------------------------------------------*
*&      Form  CLEAR_0240
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_0240 .
  CLEAR: /msh/stoer_s_prod,
         /msh/stoer_s_top-fvgrund,
         gv_rektext.
ENDFORM.                    " CLEAR_0240
*&---------------------------------------------------------------------*
*&      Form  SAVE_0240
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_0240 .
  DATA: ls_stoer TYPE /msh/stoer_t_prd.
  DATA: lt_text TYPE text_table_type.
  DATA: lv_error TYPE xfeld.

* Abfrage
  CLEAR lv_error.
  PERFORM ask_save CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    EXIT.
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



* Text prüfen
  PERFORM check_and_set_text USING '0240'
                             CHANGING lt_text.
  IF NOT lt_text[] IS INITIAL.
    /msh/stoer_s_prod-xcomment_prod = 'X'.
  ELSE.
    CLEAR /msh/stoer_s_prod-xcomment_prod.
  ENDIF.

* Daten moven
  ls_stoer-mandt = sy-mandt.
  MOVE-CORRESPONDING /msh/stoer_s_top TO ls_stoer.
  MOVE-CORRESPONDING /msh/stoer_s_prod TO ls_stoer.
  IF gv_changemode IS INITIAL.
    ls_stoer-erfuser = sy-uname.
    ls_stoer-erfdate = sy-datum.
    ls_stoer-erftime = sy-uzeit.
  ELSE.
    SELECT SINGLE erfuser erfdate erftime INTO
            (ls_stoer-erfuser, ls_stoer-erfdate, ls_stoer-erftime)
           FROM /msh/stoer_t_prd WHERE stoerid = gv_stoerid.
    ls_stoer-aenuser = sy-uname.
    ls_stoer-aendate = sy-datum.
    ls_stoer-aentime = sy-uzeit.
  ENDIF.

* Text sichern
  PERFORM save_text USING lt_text
                          ls_stoer-stoerid
                          'PROD'
                    CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    MESSAGE e009.
  ENDIF.

* DB-Update
  CLEAR ok_0100.
  MODIFY /msh/stoer_t_prd FROM ls_stoer.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE s010 WITH 'Produktionsstörung' ls_stoer-stoerid.
* Startscreen
    PERFORM back_to_start.
  ELSE.
    MESSAGE e009.
  ENDIF.
ENDFORM.                    " SAVE_0240
*&---------------------------------------------------------------------*
*&      Form  SELECT_EXIST_PROD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_exist_prod .
  DATA: lt_stoer_prod TYPE TABLE OF /msh/stoer_t_prd,
        ls_stoer_prod TYPE /msh/stoer_t_prd,
        lt_exist      TYPE TABLE OF /msh/stoer_s_exist_prod,
        ls_exist      TYPE /msh/stoer_s_exist_prod,
        lt_text       TYPE TABLE OF tline,
        lv_name       TYPE thead-tdname.
  DATA: ls_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat.

  REFRESH lt_exist[].

  IF gv_changemode IS INITIAL.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_stoer_prod WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                           AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                           AND drerz_prod = /msh/stoer_s_prod-drerz_prod
                                                           AND pva_prod = /msh/stoer_s_prod-pva_prod
                                                           AND bezirk_prod = /msh/stoer_s_prod-bezirk_prod.
  ELSE.
    SELECT * FROM /msh/stoer_t_prd INTO TABLE lt_stoer_prod WHERE gueltigbis GE sy-datum.
  ENDIF.

  IF sy-subrc = 0.
    gv_exist = 'X'.
    LOOP AT lt_stoer_prod INTO ls_stoer_prod.
      CLEAR ls_exist.
      MOVE-CORRESPONDING ls_stoer_prod TO ls_exist.
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
      APPEND ls_exist TO lt_exist.
    ENDLOOP.
* Feldkatalog bauen
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = '/MSH/STOER_S_EXIST_PROD'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = lt_fieldcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    LOOP AT lt_fieldcat INTO ls_fieldcat.
      CASE ls_fieldcat-fieldname.
        WHEN 'STOERID' OR 'BEZIRK_PROD'.
          ls_fieldcat-no_out = 'X'.
        WHEN 'GRUND'.
          ls_fieldcat-coltext = 'Störungsgrund'.
        WHEN 'KOMMENTAR'.
          ls_fieldcat-coltext = 'Kommentar'.
      ENDCASE.
      MODIFY lt_fieldcat FROM ls_fieldcat.
    ENDLOOP.
* Tabelle zum ALV schicken
    ls_layout-no_keyfix = 'X'.
    ls_layout-cwidth_opt = 'X'.
    ls_layout-sgl_clk_hd = 'X'.
    ls_layout-no_toolbar = 'X'.
    ls_layout-smalltitle = 'X'.
    ls_layout-grid_title = 'Bereits vorhandene Produktionsstörungen'.
    gt_exist_prod[] = lt_exist[].
    IF gv_changemode IS INITIAL.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.
      CALL METHOD gc_meld->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_prod
          it_fieldcatalog = lt_fieldcat.
    ELSE.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.
      CALL METHOD gc_meld_det->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_prod
          it_fieldcatalog = lt_fieldcat.
    ENDIF.
  ENDIF.
ENDFORM.                    " SELECT_EXIST_PROD
*&---------------------------------------------------------------------*
*&      Form  PAI_0220
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM pai_0220 .

  DATA: ls_adr     TYPE jytadr,
        ls_adr_old TYPE jytadr.

* Grund darf nicht leer sein
  IF /msh/stoer_s_top-fvgrund IS INITIAL.
    MESSAGE e007.
  ENDIF.


* Ggf. Name1 setzen
  IF /msh/stoer_s_gp-name1 IS INITIAL.
    /msh/stoer_s_gp-name1 = '*'.
  ENDIF.

* Ggf. Adresse zu GPNR ermitteln
  CLEAR ls_adr.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_adr.
  "Land löschen
  CLEAR ls_adr-land1.
*  CLEAR ls_adr-land1.
  IF NOT /msh/stoer_s_gp-gpnr IS INITIAL AND /msh/stoer_s_gp-gpnr NE gs_0220_old-gpnr OR NOT /msh/stoer_s_gp-gpnr IS
         INITIAL AND ls_adr IS INITIAL .
    PERFORM get_addr_to_gp.
  ENDIF.

* CHECK NACHLIEFERUNG
  IF NOT /msh/stoer_s_gp-nledatum IS INITIAL.
    IF /msh/stoer_s_gp-nledatum < sy-datum.
      MESSAGE e407(jv) WITH /msh/stoer_s_gp-nledatum.
    ENDIF.
    IF ( /msh/stoer_s_gp-nledatum   = sy-datum ) AND
       ( /msh/stoer_s_gp-nleuhrzeit < sy-uzeit ).
      MESSAGE e407(jv) WITH /msh/stoer_s_gp-nledatum.
    ENDIF.
    IF /msh/stoer_s_gp-xbezspaet IS INITIAL.
      MESSAGE w419(jv).
    ENDIF.
  ENDIF.

* Ggf. GP zu Adresse ermitteln
  CLEAR ls_adr.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_adr.
*  CLEAR ls_adr-land1.
  IF /msh/stoer_s_gp-gpnr IS INITIAL AND NOT ls_adr IS INITIAL.
    PERFORM get_gp_from_addr.
  ENDIF.

* Bei geänderter Adresse den Bezirk neu ermitteln
  CLEAR ls_adr.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_adr.
*  CLEAR ls_adr-land1.
*  CLEAR ls_adr_old.
  MOVE-CORRESPONDING gs_0220_old TO ls_adr_old.
*  CLEAR ls_adr_old-land1.
  IF ls_adr NE ls_adr_old.
    PERFORM postal_check_addr USING 'X' .
  ENDIF.
* Zum Schluß die Daten in den Altstatus moven
  gs_0220_old = /msh/stoer_s_gp.
ENDFORM.                    " PAI_0220
*&---------------------------------------------------------------------*
*&      Form  CLEAR_0220
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_0220 .
  CLEAR: /msh/stoer_s_gp,
         /msh/stoer_s_top-fvgrund,
         gv_rektext,
         gs_0220_old.
ENDFORM.                    " CLEAR_0220
*&---------------------------------------------------------------------*
*&      Form  SAVE_0220
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_0220 .
  DATA: ls_stoer TYPE /msh/stoer_t_gp.
  DATA: lt_text TYPE text_table_type.
  DATA: lv_error TYPE xfeld.

* Abfrage
  CLEAR lv_error.
  PERFORM ask_save CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    EXIT.
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

* Text prüfen
  PERFORM check_and_set_text USING '0220'
                             CHANGING lt_text.
  IF NOT lt_text[] IS INITIAL.
    /msh/stoer_s_gp-xcomment_gp = 'X'.
  ELSE.
    CLEAR /msh/stoer_s_gp-xcomment_gp.
  ENDIF.

* Daten moven
  ls_stoer-mandt = sy-mandt.
  MOVE-CORRESPONDING /msh/stoer_s_top TO ls_stoer.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_stoer.

  ls_stoer-erfuser = sy-uname.
  ls_stoer-erfdate = sy-datum.
  ls_stoer-erftime = sy-uzeit.
  IF gv_changemode IS INITIAL.
    ls_stoer-erfuser = sy-uname.
    ls_stoer-erfdate = sy-datum.
    ls_stoer-erftime = sy-uzeit.
  ELSE.
    SELECT SINGLE erfuser erfdate erftime INTO
            (ls_stoer-erfuser, ls_stoer-erfdate, ls_stoer-erftime)
           FROM /msh/stoer_t_gp WHERE stoerid = gv_stoerid.
    ls_stoer-aenuser = sy-uname.
    ls_stoer-aendate = sy-datum.
    ls_stoer-aentime = sy-uzeit.
  ENDIF.

* Text sichern
  PERFORM save_text USING lt_text
                          ls_stoer-stoerid
                          'GPNR'
                    CHANGING lv_error.
  IF lv_error = 'X'.
    CLEAR ok_0100.
    MESSAGE e009.
  ENDIF.

* DB-Update
  CLEAR ok_0100.
  MODIFY /msh/stoer_t_gp FROM ls_stoer.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE s010 WITH 'Geschäftspartnerstörung' ls_stoer-stoerid.
* Startscreen
    PERFORM back_to_start.
  ELSE.
    MESSAGE e009.
  ENDIF.
ENDFORM.                    " SAVE_0220
*&---------------------------------------------------------------------*
*&      Form  SELECT_EXIST_GP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_exist_gp .
  DATA: lt_stoer_gp TYPE TABLE OF /msh/stoer_t_gp,
        ls_stoer_gp TYPE /msh/stoer_t_gp,
        lt_exist    TYPE TABLE OF /msh/stoer_s_exist_gp,
        ls_exist    TYPE /msh/stoer_s_exist_gp,
        lt_text     TYPE TABLE OF tline,
        lv_name     TYPE thead-tdname.
  DATA: ls_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat,
        ls_addr     TYPE jgtsadr,
        ls_check    TYPE rjkwww_address,
        ls_adr      TYPE jytadr.


  REFRESH lt_exist[].

  IF gv_changemode IS INITIAL.
    IF NOT /msh/stoer_s_gp-gpnr IS INITIAL.
      SELECT * FROM /msh/stoer_t_gp INTO TABLE lt_stoer_gp WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                             AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                             AND gpnr = /msh/stoer_s_gp-gpnr.
    ELSE.
      CLEAR ls_adr.
      MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_adr.
      IF NOT ls_adr IS INITIAL.
        SHIFT ls_adr-hausn LEFT DELETING LEADING space.
        SELECT * FROM /msh/stoer_t_gp INTO TABLE lt_stoer_gp WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                               AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                               AND stras = ls_adr-stras
                                                               AND hausn = ls_adr-hausn
                                                               AND pstlz = ls_adr-pstlz
                                                               AND bezirk_gp = /msh/stoer_s_gp-bezirk_gp
                                                               AND ort01 = ls_adr-ort01.
      ENDIF.
    ENDIF.
  ELSE.
    SELECT * FROM /msh/stoer_t_gp INTO TABLE lt_stoer_gp WHERE gueltigbis GE sy-datum.
  ENDIF.

  IF sy-subrc = 0.
    gv_exist = 'X'.
    LOOP AT lt_stoer_gp INTO ls_stoer_gp.
      CLEAR ls_exist.
      MOVE-CORRESPONDING ls_stoer_gp TO ls_exist.
      SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_gp-fvgrund.
      IF ls_stoer_gp-xcomment_gp EQ 'X'.
        REFRESH lt_text[].
        lv_name = ls_stoer_gp-stoerid.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'GPNR'
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
* Bezirk
      ls_exist-bezirk = ls_stoer_gp-bezirk_gp.
* Kurzadresse
      CLEAR ls_addr.
      CLEAR ls_check.
      MOVE-CORRESPONDING ls_stoer_gp TO ls_check.
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
          address_short_form_s = ls_exist-shortaddr.
      APPEND ls_exist TO lt_exist.
    ENDLOOP.
* Feldkatalog bauen
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZJKS_STOER_EXIST_GP'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = lt_fieldcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.
    LOOP AT lt_fieldcat INTO ls_fieldcat.
      CASE ls_fieldcat-fieldname.
        WHEN 'STOERID'.
          ls_fieldcat-no_out = 'X'.
        WHEN 'GRUND'.
          ls_fieldcat-coltext = 'Störungsgrund'.
        WHEN 'KOMMENTAR'.
          ls_fieldcat-coltext = 'Kommentar'.
      ENDCASE.
      MODIFY lt_fieldcat FROM ls_fieldcat.
    ENDLOOP.
* Tabelle zum ALV schicken
    ls_layout-no_keyfix = 'X'.
    ls_layout-cwidth_opt = 'X'.
    ls_layout-sgl_clk_hd = 'X'.
    ls_layout-no_toolbar = 'X'.
    ls_layout-smalltitle = 'X'.
    ls_layout-grid_title = 'Bereits vorhandene GP-Meldungen'.
    gt_exist_gp[] = lt_exist[].
    IF gv_changemode IS INITIAL.

      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.

      CALL METHOD gc_meld->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_gp
          it_fieldcatalog = lt_fieldcat.
    ELSE.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          i_style_table             = space
          it_fieldcatalog           = lt_fieldcat
        IMPORTING
          ep_table                  = gt_dyn_table
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      ASSIGN gt_dyn_table->* TO <fs_itab>.
      LOOP AT lt_exist ASSIGNING <fs_loop>.
        INSERT <fs_loop> INTO TABLE <fs_itab>.
      ENDLOOP.
      CALL METHOD gc_meld_det->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_exist_gp
          it_fieldcatalog = lt_fieldcat.
    ENDIF.
  ENDIF.
ENDFORM.                    " SELECT_EXIST_GP
*&---------------------------------------------------------------------*
*&      Form  GET_ADDR_TO_GP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_addr_to_gp .

  DATA: lt_addrsel TYPE TABLE OF rjhagpzhad,
        ls_addrsel TYPE rjhagpzhad,
        ls_bpaddr  TYPE jgvaddres2,
        lt_jkpa    TYPE TABLE OF jkpa,
        ls_jkpa    TYPE jkpa,
        lt_adr     TYPE jkd_address_delivtab,
        ls_adr     LIKE LINE OF lt_adr,
        lt_bez     TYPE TABLE OF rjs0802,
        ls_bez     TYPE rjs0802.

  DATA: lt_addr TYPE TABLE OF jgvaddres2.

  " Hat der Kunde mehrere Adressen?
  CALL FUNCTION 'ISP_ADDRESSES_READ'
    EXPORTING
      anf_dat   = /msh/stoer_s_top-gueltigvon
      end_dat   = /msh/stoer_s_top-gueltigvon
      sel_gpnr  = /msh/stoer_s_gp-gpnr
      sel_rolle = 'WE'
    TABLES
      iaddres2  = lt_addr
    EXCEPTIONS
      no_adr    = 1
      no_gpnr   = 2
      no_rolle  = 3
      OTHERS    = 4.
  CHECK sy-subrc = 0.
  CASE lines( lt_addr ).
    WHEN 1.
      REFRESH lt_addrsel[].
      READ TABLE lt_addr ASSIGNING FIELD-SYMBOL(<fs_base>) INDEX 1.
      APPEND INITIAL LINE TO lt_addrsel ASSIGNING FIELD-SYMBOL(<fs_add>).
      MOVE-CORRESPONDING <fs_base> TO <fs_add>.
    WHEN OTHERS.
      "Adresse wählen
      REFRESH lt_addrsel[].
      CALL FUNCTION 'ISP_ADDRESS_PAM_ORDER_SELECT'
        EXPORTING
          aktyp                  = 'V'
          gpnr                   = /msh/stoer_s_gp-gpnr
          gueltigbis             = /msh/stoer_s_top-gueltigbis
          gueltigvon             = /msh/stoer_s_top-gueltigvon
          rolle                  = 'WE'
          basisspr               = 'D'
        TABLES
          order_address          = lt_addrsel
        EXCEPTIONS
          no_address_for_mailing = 1
          no_data_found          = 2
          no_pickup_possible     = 3
          no_selection           = 4
          OTHERS                 = 5.
      IF sy-subrc <> 0.
        MESSAGE e011.
      ENDIF.
  ENDCASE.

* Weiter wenn Adresse gefüllt
  CHECK NOT lt_addrsel[] IS INITIAL.

* Fehler wenn mehr als eine Zeile (darf eigentlich nicht passieren)
  IF lines( lt_addrsel ) GT 1.
    MESSAGE e012.
  ENDIF.

* Einlesen und überstellen
  READ TABLE lt_addrsel INTO ls_addrsel INDEX 1.
  MOVE-CORRESPONDING ls_addrsel TO /msh/stoer_s_gp.
  CLEAR ls_adr.
  REFRESH lt_adr[].
  MOVE-CORRESPONDING ls_addrsel TO ls_adr.
  ls_adr-gueltigvon = /msh/stoer_s_top-gueltigvon.
  ls_adr-gueltigbis = /msh/stoer_s_top-gueltigbis.
  APPEND ls_adr TO lt_adr.
  SHIFT /msh/stoer_s_gp-hausn LEFT DELETING LEADING space.
  SHIFT /msh/stoer_s_gp-hsnmr2 LEFT DELETING LEADING space.

* Bezirk lesen
  CALL FUNCTION 'ISP_ADDRESS_STRUCTURE_GET'
    TABLES
      addresstab      = lt_adr
      out_splitt_tab  = lt_bez
    EXCEPTIONS
      address_empty   = 1
      lieferart_false = 2
      no_data_found   = 3
      address_no_date = 4
      address_no_var  = 5
      OTHERS          = 6.

  LOOP AT lt_bez INTO ls_bez WHERE struknoart = con_bezirk.
    /msh/stoer_s_gp-bezirk_gp = ls_bez-struknoten.
    EXIT.
  ENDLOOP.

ENDFORM.                    " GET_ADDR_TO_GP
*&---------------------------------------------------------------------*
*&      Form  GET_GP_FROM_ADDR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_gp_from_addr .

* Postalisch prüfen und Bezirk ermitteln
  PERFORM postal_check_addr USING space.

* GP Suchen
  PERFORM search_gp.

ENDFORM.                    " GET_GP_FROM_ADDR
*&---------------------------------------------------------------------*
*&      Form  POSTAL_CHECK_ADDR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM postal_check_addr USING xnomess TYPE xfeld.

  DATA: ls_addr  TYPE rjkwww_address,
        lt_error TYPE jymsg_t_msg_ext,
        lt_adr   TYPE jkd_address_delivtab,
        ls_adr   LIKE LINE OF lt_adr,
        lt_bez   TYPE TABLE OF rjs0802,
        ls_bez   TYPE rjs0802.

* Erst mal ein einfacher Move
  IF /msh/stoer_s_gp-land1 IS INITIAL.
    /msh/stoer_s_gp-land1 = 'DE'.
  ENDIF.
  CLEAR ls_addr.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_addr.

* Baustein
  CALL FUNCTION 'ISM_WWW_ADDRESS_CHECK_DIALOG'
    IMPORTING
      pt_error_tab      = lt_error
    CHANGING
      ps_rjkwww_address = ls_addr
    EXCEPTIONS
      error_occurred    = 1
      warning_occurred  = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
    IF xnomess IS INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      MESSAGE w014.
    ENDIF.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING ls_addr TO /msh/stoer_s_gp.


  CLEAR ls_adr.
  REFRESH lt_adr[].
  MOVE-CORRESPONDING ls_addr TO ls_adr.
  ls_adr-gueltigvon = /msh/stoer_s_top-gueltigvon.
  ls_adr-gueltigbis = /msh/stoer_s_top-gueltigbis.
  APPEND ls_adr TO lt_adr.
  SHIFT /msh/stoer_s_gp-hausn LEFT DELETING LEADING space.
  SHIFT /msh/stoer_s_gp-hsnmr2 LEFT DELETING LEADING space.

* Bezirk lesen
  CLEAR /msh/stoer_s_gp-bezirk_gp.
  CALL FUNCTION 'ISP_ADDRESS_STRUCTURE_GET'
    TABLES
      addresstab      = lt_adr
      out_splitt_tab  = lt_bez
    EXCEPTIONS
      address_empty   = 1
      lieferart_false = 2
      no_data_found   = 3
      address_no_date = 4
      address_no_var  = 5
      OTHERS          = 6.


  LOOP AT lt_bez INTO ls_bez WHERE struknoart = con_bezirk.
    /msh/stoer_s_gp-bezirk_gp = ls_bez-struknoten.
    "VSG
    PERFORM get_vsg_route USING 'K'.
    EXIT.
  ENDLOOP.

ENDFORM.                    " POSTAL_CHECK_ADDR
*&---------------------------------------------------------------------*
*&      Form  SEARCH_GP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM search_gp .

  DATA: ls_adr     TYPE jgtsadr,
        ls_adr_out TYPE jgtsadr,
        lv_fb_name TYPE tjgm5-such_fuba,
        ls_search  TYPE rjycic_search,
        lt_addr    TYPE jg002_adresstab_tab,
        ls_addrdat TYPE rjycic_adr.

* Daten überstellen
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_adr.
  MOVE-CORRESPONDING /msh/stoer_s_gp TO ls_search.
  SHIFT ls_search-hausn RIGHT DELETING TRAILING space.

  "Nur GP mir aktiven Abos (-> Badi ISM_CIC_BP_SEARCH FILTERSEARCH_RESULT)
  EXPORT ex_stoer FROM 'X' TO MEMORY ID 'SEARCHSTOER'.
  EXPORT ev_guevon FROM /msh/stoer_s_top-gueltigvon TO MEMORY ID 'GUEVONSTOER'.
  CALL FUNCTION 'ISM_CIC_BP_CHOICE'
    EXPORTING
      ps_data_for_search = ls_search
      pv_comp            = 'MSD'
      pv_group_salesarea = space
      pv_xnodialog       = space
      pv_xkpl_suche      = 'X'
    IMPORTING
      address_data       = ls_addrdat
    EXCEPTIONS
      no_addresses_found = 1
      new_selection      = 2
      not_unique         = 3
      component_missing  = 4
      OTHERS             = 5.
  IF sy-subrc = 0.
* Nur weiter wenn Dublette selektiert
    IF NOT ls_addrdat-gpnr IS INITIAL.
      /msh/stoer_s_gp-gpnr = ls_addrdat-gpnr.
      "Adresse holen
      PERFORM get_addr_to_gp.
    ENDIF.
  ENDIF.
  FREE MEMORY ID 'SEARCHSTOER'.
  FREE MEMORY ID 'GUEVONSTOER'.
ENDFORM.                    " SEARCH_GP
*&---------------------------------------------------------------------*
*&      Form  f4help_grund
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4help_grund .

ENDFORM.                    " f4_grund
*&---------------------------------------------------------------------*
*&      Form  SET_DYNPRO_CHANGEMODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_dynpro_changemode .
  LOOP AT SCREEN.
    IF gv_viewmode EQ 'X'.
      screen-input = 0.
    ENDIF.
    CASE screen-group1.
      WHEN 'CHG'.
        IF gv_changemode IS INITIAL AND gv_viewmode IS INITIAL.
          screen-active = 0.
          screen-invisible = 1.
        ELSE.
          screen-active = 1.
          screen-invisible = 0.
        ENDIF.
      WHEN 'CRE'.
        IF gv_changemode IS INITIAL AND gv_viewmode IS INITIAL.
          screen-active = 1.
          screen-invisible = 0.
        ELSE.
          screen-active = 0.
          screen-invisible = 1.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.                    " SET_DYNPRO_CHANGEMODE
*&---------------------------------------------------------------------*
*&      Form  SET_TEXT_CHANGEMODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GV_TEXTDISPLAY_0210  text
*      -->P_GV_TEXTVIEW_0210  text
*----------------------------------------------------------------------*
FORM set_text_changemode  USING    pv_textdisplay TYPE REF TO cl_gui_custom_container
                                   pv_textview TYPE REF TO cl_gui_textedit.

  DATA: lt_stream TYPE text_table_type.

* Nur im Änderungsmodus
  CHECK gv_changemode = 'X' OR gv_viewmode EQ 'X'.

* Störungs-ID muß bekannt sein
  CHECK NOT gv_stoerid IS INITIAL.

* Der TExt darf noch nicht gelesen sein
  CHECK gt_chgtext[] IS INITIAL.

* Text lesen
  PERFORM read_text USING gs_cust-area_textid
                          gv_stoerid
                    CHANGING gt_chgtext.

  IF NOT gt_chgtext[] IS INITIAL.

* Text konvertieren
    CALL FUNCTION 'CONVERT_ITF_TO_STREAM_TEXT'
      TABLES
        itf_text    = gt_chgtext
        text_stream = lt_stream.

* Und setzen
    CALL METHOD pv_textview->set_text_as_stream
      EXPORTING
        text            = lt_stream
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.

* Im Viewmode nicht editierbar
    IF gv_viewmode EQ 'X'.
      CALL METHOD pv_textview->set_readonly_mode
        EXPORTING
          readonly_mode          = 1
        EXCEPTIONS
          error_cntl_call_method = 1
          invalid_parameter      = 2
          OTHERS                 = 3.
    ENDIF.
  ELSE.
    IF gv_viewmode EQ 'X'.
      CALL METHOD pv_textview->set_readonly_mode
        EXPORTING
          readonly_mode          = 1
        EXCEPTIONS
          error_cntl_call_method = 1
          invalid_parameter      = 2
          OTHERS                 = 3.
    ENDIF.
  ENDIF.
ENDFORM.                    " SET_TEXT_CHANGEMODE
*&---------------------------------------------------------------------*
*&      Form  PAI_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM pai_0230 .

  DATA: ls_compare TYPE /msh/stoer_s_lief,
        ls_bezirk  TYPE ty_bezirk.

* Nur wenn sich eingaberelevante Daten geändert haben
  CLEAR ls_compare.
  MOVE-CORRESPONDING /msh/stoer_s_lief TO ls_compare.
  CLEAR ls_compare-fvart.
  IF NOT gs_0230_old IS INITIAL.
    CHECK ls_compare NE gs_0230_old.
  ENDIF.

* Grund darf nicht leer sein
  IF /msh/stoer_s_top-fvgrund IS INITIAL.
    MESSAGE e007.
  ENDIF.

* Einige Prüfungen nur bei logistisch relevanter Lieferart
  PERFORM get_const_lieferart.

* Versuch, die Änderungsart zu ermitteln, die restlichen Prüfungen laufen dann
* anhand der Fehlerart und den eingegebenen Daten
  PERFORM get_fvart.

* VSG und Route ggf. automatisch bestimmen (STOMSD-87)
  PERFORM get_vsg_route USING 'L'. "Modus "L" für lieferbezogene Störung

* Route auf Tagesrelevanz prüfen
  PERFORM check_route USING /msh/stoer_s_lief-route
                      CHANGING /msh/stoer_s_top.

* Bei Meldungen zu Zustellung und Bezirk Konstellationen prüfen
  CLEAR ls_bezirk.
  PERFORM check_const_0230 CHANGING ls_bezirk.

* Weitere Konstellationen prüfen
  PERFORM check_add_const_0230 USING ls_bezirk.

* Bei nicht zustellrelevanter Lieferart Postleitbezirk füllen
  IF gv_lfartlog IS INITIAL AND NOT /msh/stoer_s_lief-lfartlog IS INITIAL AND /msh/stoer_s_lief-postleit IS INITIAL.
    MESSAGE e041 WITH /msh/stoer_s_lief-lfartlog.
  ENDIF.

* Zum Schluß die Daten in den Altstatus moven
  gs_0230_old = /msh/stoer_s_lief.
  CLEAR gs_0230_old-fvart.
ENDFORM.                    " PAI_0230
*&---------------------------------------------------------------------*
*&      Form  CLEAR_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_0230 .
  CLEAR: /msh/stoer_s_lief,
         /msh/stoer_s_top-fvgrund,
         gv_rektext,
         gv_stoertext,
         gs_0230_old.

  REFRESH: gt_bezirk[],
           gt_bezirk_cre[].
ENDFORM.                    " CLEAR_0230
*&---------------------------------------------------------------------*
*&      Form  PREFILL_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM prefill_0230 .
* Sonstige Defaults ggf. per Enhancement setzen
  IF /msh/stoer_s_lief-vkorg IS INITIAL.
    /msh/stoer_s_lief-vkorg = 'XX'.
  ENDIF.
  IF /msh/stoer_s_lief-vtweg IS INITIAL.
    /msh/stoer_s_lief-vtweg = 'XX'.
  ENDIF.
  IF /msh/stoer_s_lief-druckerei IS INITIAL.
    /msh/stoer_s_lief-druckerei = 'XXX'.
  ENDIF.
  IF /msh/stoer_s_lief-fvverurs IS INITIAL.
    /msh/stoer_s_lief-fvverurs = 'XXX'.
  ENDIF.
  IF /msh/stoer_s_lief-lfartlog IS INITIAL.
    /msh/stoer_s_lief-lfartlog = 'XX'.
  ENDIF.
ENDFORM.                    " PREFILL_0230
*&---------------------------------------------------------------------*
*&      Form  CHECK_ADD_CONST_0230
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_add_const_0230 USING ps_bezirk TYPE ty_bezirk.

  DATA: ls_jvtfehler TYPE jvtfehler,
        ls_tjv41     TYPE tjv41,
        lv_domname   TYPE dd04l-domname,
        lv_feldname  TYPE string,
        lv_errfield  TYPE string,
        lv_error     TYPE xfeld,
        lv_lfartold  TYPE jvtfehler-lfartlog.

  DATA: BEGIN OF infotab OCCURS 30.
          INCLUDE STRUCTURE x031l.
        DATA: END OF infotab.

  FIELD-SYMBOLS: <fs_tjv41>     TYPE any,
                 <fs_jvtfehler> TYPE any.

* Simulation einiger Prüfungen aus der JV41

* Struktur vorfüllen
  MOVE-CORRESPONDING /msh/stoer_s_lief TO ls_jvtfehler.
  IF /msh/stoer_s_top-gueltigvon LT sy-datum.
    ls_jvtfehler-vrsnddatum = /msh/stoer_s_top-gueltigvon.   "Dummywert für Prüfung
  ELSE.
    ls_jvtfehler-vrsnddatum = sy-datum - 1.
  ENDIF.
  IF ls_jvtfehler-bezirk IS INITIAL.
    ls_jvtfehler-bezirk = ps_bezirk-bezirktat.
  ENDIF.

* MUSSFELDPRÜFUNG
* Hier geht es nur darum, ob Mußfelder initial sind, alles andere macht der Batchinput später
  SELECT SINGLE * FROM tjv41 INTO ls_tjv41 WHERE fvart = /msh/stoer_s_lief-fvart.
  CALL FUNCTION 'DDIF_NAMETAB_GET'
    EXPORTING
      tabname   = 'JVTFEHLER'
    TABLES
      x031l_tab = infotab.
  CLEAR lv_error.
  LOOP AT infotab.
    CHECK lv_error IS INITIAL.
    CONCATENATE 'TJV41-' infotab-fieldname INTO lv_feldname.
    CONDENSE lv_feldname NO-GAPS.
    CALL FUNCTION 'ISP_FIELD_INFO_GET'
      EXPORTING
        fieldname = lv_feldname
      IMPORTING
        domname   = lv_domname
      EXCEPTIONS
        not_found = 01.
    CHECK sy-subrc = 0 AND lv_domname EQ 'AUSPRGART'.
    CONCATENATE 'LS_TJV41-' infotab-fieldname INTO lv_feldname.
    CONDENSE lv_feldname NO-GAPS.
    UNASSIGN <fs_tjv41>.
    ASSIGN (lv_feldname) TO <fs_tjv41>.
    CHECK <fs_tjv41> IS ASSIGNED.
    CHECK <fs_tjv41> EQ '+'.
    CONCATENATE 'LS_JVTFEHLER-' infotab-fieldname INTO lv_feldname.
    CONDENSE lv_feldname NO-GAPS.
    UNASSIGN <fs_jvtfehler>.
    ASSIGN (lv_feldname) TO <fs_jvtfehler>.
    CHECK <fs_jvtfehler> IS ASSIGNED.
    CHECK <fs_jvtfehler> IS INITIAL.
    lv_error = 'X'.
    lv_errfield = infotab-fieldname.
  ENDLOOP.

  IF lv_error = 'X' AND gv_lfartlog = 'X'.
    MESSAGE e027 WITH lv_errfield.
  ENDIF.

* KONSISTENZCHECK
* Dummy-Umstellung der Lieferart
  IF gv_lfartlog IS INITIAL.
    lv_lfartold = ls_jvtfehler-lfartlog.
    ls_jvtfehler-lfartlog = '01'.
  ENDIF.
  CALL FUNCTION 'ISP_JVTFEHLER_KONSISTENZ_CHECK'
    EXPORTING
      vtfehler    = ls_jvtfehler
    EXCEPTIONS
      not_correct = 01.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno.
  ENDIF.

  IF gv_lfartlog IS INITIAL.
    ls_jvtfehler-lfartlog = lv_lfartold.
  ENDIF.

* CHECK NACHLIEFERUNG
  IF NOT ls_jvtfehler-nledatum IS INITIAL.
    IF ls_jvtfehler-nledatum < sy-datum.
      MESSAGE e407(jv) WITH ls_jvtfehler-nledatum.
    ENDIF.
    IF ( ls_jvtfehler-nledatum   = sy-datum ) AND
       ( ls_jvtfehler-nleuhrzeit < sy-uzeit ).
      MESSAGE e407(jv) WITH ls_jvtfehler-nledatum.
    ENDIF.
    IF ls_jvtfehler-xbezspaet IS INITIAL.
      MESSAGE w419(jv).
    ENDIF.
  ENDIF.

ENDFORM.                    " CHECK_ADD_CONST_0230
*&---------------------------------------------------------------------*
*&      Form  GET_CONST_LIEFERART
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_const_lieferart .
  CLEAR gv_lfartlog.
  CHECK NOT /msh/stoer_s_lief-lfartlog IS INITIAL.
  SELECT SINGLE COUNT(*) FROM tjv01 WHERE lieferart EQ /msh/stoer_s_lief-lfartlog AND xzustllung EQ 'X'.
  CHECK sy-subrc = 0.
  gv_lfartlog = 'X'.
ENDFORM.                    " GET_CONST_LIEFERART
*&---------------------------------------------------------------------*
*&      Form  SELECT_EXIST_LIEF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_exist_lief .
  DATA: lt_stoer_lief       TYPE TABLE OF /msh/stoer_t_lf,
        ls_stoer_lief       TYPE /msh/stoer_t_lf,
        ls_stoer_vor        TYPE /msh/stoer_t_lf,
        ls_stoer_lief_check TYPE /msh/stoer_t_lf,
        lt_exist            TYPE TABLE OF /msh/stoer_s_exist_lief,
        ls_exist            TYPE /msh/stoer_s_exist_lief,
        lt_text             TYPE TABLE OF tline,
        lv_name             TYPE thead-tdname.
  DATA: ls_layout    TYPE lvc_s_layo,
        lt_fieldcat  TYPE lvc_t_fcat,
        ls_fieldcat  TYPE lvc_s_fcat,
        ls_jvtfehler TYPE jvtfehler,
        lt_zuo       TYPE TABLE OF /msh/stoer_t_lz,
        ls_zuo       TYPE /msh/stoer_t_lz,
        lf_tabix     TYPE sy-tabix,
        lv_cponly    TYPE xfeld.

  REFRESH: lt_exist[], lt_stoer_lief[].

  CLEAR lv_cponly.
  GET PARAMETER ID 'Z_STOER_CPONLY' FIELD lv_cponly.

  IF gv_changemode IS INITIAL.
    SELECT * FROM /msh/stoer_t_lf INTO TABLE lt_stoer_lief WHERE gueltigvon LE /msh/stoer_s_top-gueltigbis
                                                           AND gueltigbis GE /msh/stoer_s_top-gueltigvon
                                                           AND fvart EQ /msh/stoer_s_lief-fvart
                                                           AND drerz = /msh/stoer_s_lief-drerz
                                                           AND bezirk = /msh/stoer_s_lief-bezirk
                                                           AND route = /msh/stoer_s_lief-route.
    IF sy-subrc = 0.
      SELECT * FROM /msh/stoer_t_lz INTO TABLE lt_zuo FOR ALL ENTRIES IN lt_stoer_lief
                              WHERE stoerid = lt_stoer_lief-stoerid.
    ENDIF.
  ELSE.
    SELECT * FROM /msh/stoer_t_lf INTO TABLE lt_stoer_lief WHERE gueltigbis GE sy-datum.
    IF sy-subrc = 0.
      SELECT * FROM /msh/stoer_t_lz INTO TABLE lt_zuo FOR ALL ENTRIES IN lt_stoer_lief
                              WHERE stoerid = lt_stoer_lief-stoerid.
    ENDIF.
  ENDIF.

  IF NOT lt_zuo[] IS INITIAL AND gt_jvtfehler_exist[] IS INITIAL.
    SELECT * FROM jvtfehler INTO TABLE gt_jvtfehler_exist FOR ALL ENTRIES IN lt_zuo
                                WHERE fvnr = lt_zuo-fvnr.
  ENDIF.

  IF NOT  ( lt_stoer_lief[] IS INITIAL AND gt_jvtfehler_exist[] IS INITIAL ).

    gv_exist = 'X'.

    LOOP AT lt_stoer_lief INTO ls_stoer_lief.
      CLEAR ls_exist.
      MOVE-CORRESPONDING ls_stoer_lief TO ls_exist.
      SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_lief-fvgrund.
      SELECT SINGLE kurztext FROM tjv42 INTO ls_exist-kurztext WHERE fvart = ls_stoer_lief-fvart AND spras EQ sy-langu.
      IF ls_stoer_lief-xcomment_lief EQ 'X'.
        REFRESH lt_text[].
        lv_name = ls_stoer_lief-stoerid.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'LIEF'
            language                = sy-langu
            name                    = lv_name
            object                  = 'ZJKT_STOER'
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
      APPEND ls_exist TO lt_exist.
      IF NOT lt_zuo[] IS INITIAL.
        LOOP AT lt_zuo INTO ls_zuo WHERE stoerid = ls_exist-stoerid.
          READ TABLE gt_jvtfehler_exist INTO ls_jvtfehler WITH KEY fvnr = ls_zuo-fvnr.
          CHECK sy-subrc = 0.
          lf_tabix = sy-tabix.
          CLEAR ls_stoer_lief.
          MOVE-CORRESPONDING ls_jvtfehler TO ls_stoer_lief.
          ls_stoer_lief-gueltigvon = ls_stoer_lief-gueltigbis = ls_jvtfehler-vrsnddatum.
          ls_stoer_lief-vrsnddatum = ls_jvtfehler-vrsnddatum.
          CLEAR ls_exist.
          MOVE-CORRESPONDING ls_stoer_lief TO ls_exist.
          ls_exist-fvnr = ls_jvtfehler-fvnr.
          SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_lief-fvgrund.
          SELECT SINGLE kurztext FROM tjv42 INTO ls_exist-kurztext WHERE fvart = ls_stoer_lief-fvart AND spras EQ sy-langu.
          IF ls_stoer_lief-xcomment_lief EQ 'X'.
            REFRESH lt_text[].
            lv_name = ls_stoer_lief-stoerid.
            CALL FUNCTION 'READ_TEXT'
              EXPORTING
                id                      = 'LIEF'
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
          ls_exist-linec = 'C610'.
          IF ls_exist-drerz IS INITIAL AND NOT ls_stoer_lief-drerz IS INITIAL.
            ls_exist-drerz = ls_stoer_lief-drerz.
          ENDIF.
          IF ls_exist-pva IS INITIAL AND NOT ls_stoer_lief-pva IS INITIAL.
            ls_exist-pva = ls_stoer_lief-pva.
          ENDIF.
          IF lv_cponly IS INITIAL.
            APPEND ls_exist TO lt_exist.
          ENDIF.
          DELETE gt_jvtfehler_exist INDEX lf_tabix.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
    LOOP AT gt_jvtfehler_exist INTO ls_jvtfehler.
      CLEAR ls_stoer_lief.
      MOVE-CORRESPONDING ls_jvtfehler TO ls_stoer_lief.
      ls_stoer_lief-gueltigvon = ls_stoer_lief-gueltigbis = ls_jvtfehler-vrsnddatum.
      ls_stoer_lief-vrsnddatum = ls_jvtfehler-vrsnddatum.
      CLEAR ls_exist.
      MOVE-CORRESPONDING ls_stoer_lief TO ls_exist.
      ls_exist-fvnr = ls_jvtfehler-fvnr.
      SELECT SINGLE kurztext FROM tjv44 INTO ls_exist-grund WHERE spras EQ sy-langu AND fvgrund = ls_stoer_lief-fvgrund.
      SELECT SINGLE kurztext FROM tjv42 INTO ls_exist-kurztext WHERE fvart = ls_stoer_lief-fvart AND spras EQ sy-langu.
      IF ls_stoer_lief-xcomment_lief EQ 'X'.
        REFRESH lt_text[].
        lv_name = ls_stoer_lief-stoerid.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
            id                      = 'LIEF'
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
      SELECT SINGLE * FROM /msh/stoer_t_lz INTO ls_zuo WHERE fvnr = ls_jvtfehler-fvnr.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM /msh/stoer_t_lf INTO ls_stoer_vor WHERE stoerid = ls_zuo-stoerid.
        IF ls_exist-drerz IS INITIAL AND NOT ls_stoer_vor-drerz IS INITIAL.
          ls_exist-drerz = ls_stoer_vor-drerz.
        ENDIF.
        IF ls_exist-pva IS INITIAL AND NOT ls_stoer_vor-pva IS INITIAL.
          ls_exist-pva = ls_stoer_vor-pva.
        ENDIF.
      ENDIF.
      ls_exist-linec = 'C610'.
*    IF lv_cponly IS INITIAL.
      APPEND ls_exist TO lt_exist.
*    ENDIF.
    ENDLOOP.

* Produktionsstörungen zuselektieren
    PERFORM select_prod_ext TABLES lt_zuo
                            CHANGING lt_exist.
  ELSE.
* Produktionsstörungen zuselektieren
    PERFORM select_prod_ext TABLES lt_zuo
                            CHANGING lt_exist.
    IF NOT lt_exist[] IS INITIAL.
      gv_exist = 'X'.
    ENDIF.
  ENDIF.
* Feldkatalog bauen
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/MSH/STOER_S_EXIST_LIEF'
      i_client_never_display = 'X'
    CHANGING
      ct_fieldcat            = lt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    CASE ls_fieldcat-fieldname.
      WHEN 'STOERID' OR 'FVNR'.
        ls_fieldcat-no_out = 'X'.
      WHEN 'GRUND'.
        ls_fieldcat-coltext = 'Störungsgrund'.
      WHEN 'KOMMENTAR'.
        ls_fieldcat-coltext = 'Kommentar'.
      WHEN 'KURZTEXT'.
*        ls_fieldcat-coltext = 'Fehlerart'.
        ls_fieldcat-no_out = 'X'.
    ENDCASE.
    MODIFY lt_fieldcat FROM ls_fieldcat.
  ENDLOOP.
* Tabelle zum ALV schicken
  ls_layout-no_keyfix = 'X'.
  ls_layout-cwidth_opt = 'X'.
  ls_layout-sgl_clk_hd = 'X'.
  ls_layout-no_toolbar = 'X'.
  ls_layout-smalltitle = 'X'.
  ls_layout-grid_title = 'Bereits vorhandene Lieferstörungen'.
  ls_layout-info_fname = 'LINEC'.

* Tabelle sortieren
  SORT lt_exist BY bezirk ASCENDING.

  gt_exist_lief[] = lt_exist[].

  IF gv_changemode IS INITIAL.
    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        i_style_table             = space
        it_fieldcatalog           = lt_fieldcat
      IMPORTING
        ep_table                  = gt_dyn_table
      EXCEPTIONS
        generate_subpool_dir_full = 1
        OTHERS                    = 2.
    ASSIGN gt_dyn_table->* TO <fs_itab>.
    LOOP AT lt_exist ASSIGNING <fs_loop>.
      INSERT <fs_loop> INTO TABLE <fs_itab>.
    ENDLOOP.
    CALL METHOD gc_meld->set_table_for_first_display
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_exist_lief
        it_fieldcatalog = lt_fieldcat.
  ELSE.
    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        i_style_table             = space
        it_fieldcatalog           = lt_fieldcat
      IMPORTING
        ep_table                  = gt_dyn_table
      EXCEPTIONS
        generate_subpool_dir_full = 1
        OTHERS                    = 2.
    ASSIGN gt_dyn_table->* TO <fs_itab>.
    LOOP AT lt_exist ASSIGNING <fs_loop>.
      INSERT <fs_loop> INTO TABLE <fs_itab>.
    ENDLOOP.
    CALL METHOD gc_meld_det->set_table_for_first_display
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_exist_lief
        it_fieldcatalog = lt_fieldcat.
  ENDIF.

ENDFORM.                    " SELECT_EXIST_LIEF
