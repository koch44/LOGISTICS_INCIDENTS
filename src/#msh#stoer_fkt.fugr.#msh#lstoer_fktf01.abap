*----------------------------------------------------------------------*
***INCLUDE /MSH/LSTOER_FKTF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CREATE_CONTAINERS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_containers .
  IF container_170_akt IS INITIAL.
    CREATE OBJECT container_170_akt
      EXPORTING
        container_name = 'CONTAINER_AKT'.
  ENDIF.
  IF container_170_hist IS INITIAL.
    CREATE OBJECT container_170_hist
      EXPORTING
        container_name = 'CONTAINER_HIST'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SCREEN_170_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM screen_170_build .
* Noch keine unterschiedlichen Tabreiter, daher ICON-Steuerung noch nicht implementiert
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SHOW_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_data .
  DATA: ls_layout   TYPE lvc_s_layo,
        lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat.

* Layout
  ls_layout-zebra = 'X'.
  ls_layout-smalltitle = 'X'.
  ls_layout-no_headers = 'X'.
  ls_layout-cwidth_opt = 'X'.
  ls_layout-no_toolbar = 'X'.

* Feldkatalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/MSH/STOER_S_INTERR'
      i_client_never_display = 'X'
    CHANGING
      ct_fieldcat            = lt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    CASE ls_fieldcat-fieldname.
      WHEN 'KEY' OR 'SORTDAT'.
        ls_fieldcat-no_out = 'X'.
    ENDCASE.
    MODIFY lt_fieldcat FROM ls_fieldcat.
    CLEAR: ls_fieldcat.
  ENDLOOP.

* Aktuelle Vertriebsstörungen
  IF NOT gt_akt[] IS INITIAL.
    IF gc_alv_akt IS INITIAL.
      CREATE OBJECT gc_alv_akt
        EXPORTING
          i_parent = container_170_akt.
* Handlers
      SET HANDLER gcl_dclick_170_akt=>double_click FOR gc_alv_akt.
      CALL METHOD gc_alv_akt->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_akt
          it_fieldcatalog = lt_fieldcat.
    ENDIF.
  ENDIF.

* Historische Vertriebsstörungen
*  ls_layout-grid_title = 'Historische Vertriebsstörungen'.
  IF NOT gt_hist[] IS INITIAL.
    IF gc_alv_hist IS INITIAL.
      CREATE OBJECT gc_alv_hist
        EXPORTING
          i_parent = container_170_hist.
* Handlers
      SET HANDLER gcl_dclick_170_hist=>double_click FOR gc_alv_hist.
      CALL METHOD gc_alv_hist->set_table_for_first_display
        EXPORTING
          is_layout       = ls_layout
        CHANGING
          it_outtab       = gt_hist
          it_fieldcatalog = lt_fieldcat.
    ENDIF.
  ENDIF.
ENDFORM.
