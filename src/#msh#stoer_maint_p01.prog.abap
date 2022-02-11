*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_P01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&       Class (Implementation)  lcl_hotspot_change_over
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_hotspot_change_over IMPLEMENTATION.
  METHOD on_hotspot_click.

    DATA: lt_roid TYPE lvc_t_roid,
          ls_roid TYPE lvc_s_roid.


    IF gv_openforedit = 'X' AND ok_0100 IS INITIAL.
      ok_0100 = 'Z_DUM'.
      PERFORM ask_loss.
      CHECK NOT ok_0100 IS INITIAL.
      CLEAR ok_0100.
    ENDIF.
* Handler setzen
    SET HANDLER lcl_dclick_det=>on_double_click FOR gc_meld_det.

* Zeilen-ID einlesen
    CLEAR gs_overview.
    READ TABLE gt_overview INTO gs_overview INDEX e_row_id.
    CHECK NOT gs_overview IS INITIAL.

* Detaildaten aufbauen je nach ID
    CASE gs_overview-id.
      WHEN 'DG'. PERFORM select_exist_dig.
      WHEN 'GP'. PERFORM select_exist_gp.
      WHEN 'LF'. PERFORM select_exist_lief.
      WHEN 'PR'. PERFORM select_exist_prod.
    ENDCASE.

* PAI auslösen
    gv_dynnr = '0310'.
    CLEAR gv_openforedit.
    CALL METHOD cl_gui_cfw=>set_new_ok_code
      EXPORTING
        new_code = 'Z_HS_CLICK'.
    CALL METHOD cl_gui_cfw=>flush.
  ENDMETHOD.                    "on_hotspot_click
ENDCLASS.               "lcl_hotspot_change_over
*&---------------------------------------------------------------------*
*&       Class (Implementation)  lcl_dclick_det
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_dclick_det IMPLEMENTATION.
  METHOD on_double_click.

    DATA: xdo TYPE xfeld.

    FIELD-SYMBOLS: <fs_itab> TYPE STANDARD TABLE,
                   <fs_sel>  TYPE any,
                   <fs_base> TYPE any,
                   <fv_id>   TYPE /msh/stoerid,
                   <fs_dyn>  TYPE any,
                   <fv_col>  TYPE any.

    DATA: ls_jvtfehler TYPE jvtfehler.

    REFRESH gt_chgtext[].
** Zeile einlesen
*    ASSIGN gt_dyn_table->* TO <fs_itab>.
*    READ TABLE <fs_itab> ASSIGNING <fs_sel> INDEX e_row-index.

* Detaildaten aufbauen je nach ID
    CASE gs_overview-id.
      WHEN 'DG'.
        READ TABLE gt_exist_dig ASSIGNING <fs_sel> INDEX e_row-index.
      WHEN 'GP'.
        READ TABLE gt_exist_gp ASSIGNING <fs_sel> INDEX e_row-index.
      WHEN 'LF'.
        READ TABLE gt_exist_lief ASSIGNING <fs_sel> INDEX e_row-index.
      WHEN 'PR'.
        READ TABLE gt_exist_prod ASSIGNING <fs_sel> INDEX e_row-index.
    ENDCASE.

    ASSIGN ('<FS_SEL>-LINEC') TO <fv_col>.
    IF NOT <fv_col> IS ASSIGNED OR <fv_col> IS INITIAL.
      ASSIGN ('<FS_SEL>-STOERID') TO <fv_id>.
      CHECK <fv_id> IS ASSIGNED.
      gv_stoerid = <fv_id>.
      READ TABLE gt_cust INTO gs_cust WITH KEY area_id = gs_overview-id.
      CHECK sy-subrc = 0.
* Die DB-Tab und Dynprostruktur muß gepflegt sein
      CHECK NOT gs_cust-area_dbtab IS INITIAL.
      CHECK NOT gs_cust-area_dynstruc IS INITIAL.
* Die Tabelle muß die Spalte GUELTIGBIS haben
      SELECT SINGLE COUNT(*) FROM dd03l WHERE tabname = gs_cust-area_dbtab
                                        AND fieldname EQ 'STOERID'.
      CHECK sy-subrc = 0.
      ASSIGN (gs_cust-area_dynstruc) TO <fs_dyn>.
* Dynprovalues updaten
      PERFORM update_dyn USING gv_stoerid
                         CHANGING xdo.
      CHECK xdo = 'X'.
      SELECT SINGLE * FROM (gs_cust-area_dbtab) INTO CORRESPONDING FIELDS OF <fs_dyn>
                                                 WHERE stoerid = <fv_id>.
      SELECT SINGLE * FROM (gs_cust-area_dbtab) INTO CORRESPONDING FIELDS OF /msh/stoer_s_top
                                                 WHERE stoerid = <fv_id>.
* Screenaufruf je nach ID
      gv_repid = gs_cust-area_repid.
      gv_dynnr = gv_dynnr_change = gs_cust-area_dynnr.


* PAI auslösen
      CALL METHOD cl_gui_cfw=>set_new_ok_code
        EXPORTING
          new_code = 'Z_W120'.
      CALL METHOD cl_gui_cfw=>flush.
    ELSE.
      UNASSIGN <fv_col>.
      ASSIGN ('<FS_SEL>-FVNR') TO <fv_col>.
      CHECK <fv_col> IS ASSIGNED AND NOT <fv_col> IS INITIAL.
      SET PARAMETER ID 'JVN' FIELD <fv_col>.
      SELECT SINGLE * FROM jvtfehler INTO ls_jvtfehler WHERE fvnr = <fv_col>.
      IF sy-subrc = 0 AND ls_jvtfehler-vrsnddatum LT sy-datum.
        CALL TRANSACTION 'JV43' AND SKIP FIRST SCREEN.
      ELSE.
        CALL TRANSACTION 'JV42' AND SKIP FIRST SCREEN.
      ENDIF.
      WAIT UP TO 2 SECONDS.
      PERFORM select_exist_lief.
    ENDIF.
  ENDMETHOD.                    "on_double_click
ENDCLASS.               "lcl_dclick_det
*&---------------------------------------------------------------------*
*&       Class (Implementation)  lcl_dclick_meld
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_dclick_meld IMPLEMENTATION.
  METHOD on_double_click.

    DATA: lv_key TYPE swo_typeid.

    CONSTANTS: lc_fieldname TYPE string VALUE '<FS_SEL>-STOERID',
               lc_fvnr      TYPE string VALUE '<FS_SEL>-FVNR',
               lc_ktext     TYPE string VALUE '<FS_SEL>-KURZTEXT'.

    FIELD-SYMBOLS: <fs_itab>  TYPE STANDARD TABLE,
                   <fs_sel>   TYPE any,
                   <fv_id>    TYPE /msh/stoerid,
                   <fv_ktext> TYPE any,
                   <fv_fvnr>  TYPE jvtfehler-fvnr,
                   <fs_dyn>   TYPE any,
                   <fv_col>   TYPE any.

* Zeile einlesen
    ASSIGN gt_dyn_table->* TO <fs_itab>.
    READ TABLE <fs_itab> ASSIGNING <fs_sel> INDEX e_row-index.

* Assign
    ASSIGN (lc_fieldname) TO <fv_id>.
    ASSIGN (lc_ktext) TO <fv_ktext>.
    IF <fv_id> IS ASSIGNED AND NOT <fv_id> IS INITIAL.
      CHECK NOT gv_area IS INITIAL.

* Aufruf
      IF <fv_ktext> IS ASSIGNED AND <fv_ktext> EQ 'Produktion'.
        CONCATENATE 'PR' <fv_id> INTO lv_key.
      ELSE.
        CONCATENATE gv_area <fv_id> INTO lv_key.
      ENDIF.
      CONDENSE lv_key.
      CALL FUNCTION '/MSH/CALL_STOER_VIEW'
        EXPORTING
          iv_key = lv_key.
    ELSE.
* Assign
      ASSIGN (lc_fvnr) TO <fv_fvnr>.
      IF <fv_fvnr> IS ASSIGNED AND NOT <fv_fvnr> IS INITIAL.
* Aufruf
        SET PARAMETER ID 'JVN' FIELD <fv_fvnr>.
        CALL TRANSACTION 'JV43' AND SKIP FIRST SCREEN.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "on_double_click
ENDCLASS.               "lcl_dclick_meld
