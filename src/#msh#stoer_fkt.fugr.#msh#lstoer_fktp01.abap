*&---------------------------------------------------------------------*
*&  Include           /MSH/LSTOER_FKTP01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&       Class (Implementation)  gcl_dclick_170_akt
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS gcl_dclick_170_akt IMPLEMENTATION.
  METHOD double_click.
    CLEAR gs_akt.
    READ TABLE gt_akt INTO gs_akt INDEX es_row_no-row_id.
    IF gs_akt-key NE space AND gs_akt-key(1) CA '0123456789'.
      SET PARAMETER ID 'JVN' FIELD gs_akt-key.
      CALL TRANSACTION 'JV43' AND SKIP FIRST SCREEN.
    ELSE.
      CALL FUNCTION '/MSH/CALL_STOER_VIEW'
        EXPORTING
          iv_key = gs_akt-key.

    ENDIF.
  ENDMETHOD.                    "double_click
ENDCLASS.               "gcl_dclick_170_akt
*&---------------------------------------------------------------------*
*&       Class (Implementation)  gcl_dclick_170_hist
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS gcl_dclick_170_hist IMPLEMENTATION.
  METHOD double_click.
    CLEAR gs_akt.
    READ TABLE gt_hist INTO gs_akt INDEX es_row_no-row_id.
    IF gs_akt-key NE space AND gs_akt-key(1) CA '0123456789'.
      SET PARAMETER ID 'JVN' FIELD gs_akt-key.
      CALL TRANSACTION 'JV43' AND SKIP FIRST SCREEN.
    ELSE.
      CALL FUNCTION '/MSH/CALL_STOER_VIEW'
        EXPORTING
          iv_key = gs_akt-key.
    ENDIF.
  ENDMETHOD.                    "double_click
ENDCLASS.               "gcl_dclick_170_hist
