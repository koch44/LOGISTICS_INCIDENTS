*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_PBO
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  CASE sy-dynnr.
    WHEN '0100'.
      SET TITLEBAR 'TITLE_0100'.
    WHEN '0300'.
      gv_changemode = 'X'.
      SET TITLEBAR 'TITLE_0300'.
    WHEN '0400'.
      gv_viewmode = 'X'.
      SET TITLEBAR 'TITLE_0400'.
  ENDCASE.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_INITSCREEN  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_initscreen OUTPUT.
* Bei initialem Aufruf generell mit Dynpro 0110 starten
  CHECK gv_called IS INITIAL.
  gv_called = 'X'.
  CASE sy-dynnr.
    WHEN '0100'.
      gv_dynnr = '0110'.
    WHEN '0300'.
      gv_dynnr = '0310'.
  ENDCASE.
  gv_repid = sy-repid.
  IF gv_viewmode IS INITIAL.
    PERFORM preload_global.
    PERFORM prefill_0230.
* Container für ALV anlegen
    IF gc_cont_meld IS INITIAL.
      CREATE OBJECT gc_cont_meld
        EXPORTING
          container_name = 'CONT_MELD'.
    ENDIF.
    IF gc_meld IS INITIAL.
      CREATE OBJECT gc_meld
        EXPORTING
          i_parent = gc_cont_meld.
      SET HANDLER lcl_dclick_meld=>on_double_click FOR gc_meld.
    ENDIF.
* Container für Änderungsmodus
    IF sy-dynnr = '0300'.
      IF gc_cont_meld_det IS INITIAL.
        CREATE OBJECT gc_cont_meld_det
          EXPORTING
            container_name = 'CONT_MELD_DET'.
      ENDIF.
      IF gc_meld_det IS INITIAL.
        CREATE OBJECT gc_meld_det
          EXPORTING
            i_parent      = gc_cont_meld_det
            i_appl_events = 'X'.
*          SET HANDLER lcl_dclick_meld=>on_double_click FOR gc_meld_det.
      ENDIF.
    ENDIF.
  ENDIF.
ENDMODULE.                 " SET_INITSCREEN  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_TEXT_0120  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_text_0120 OUTPUT.
* Text zum Zeitraum erstellen
  PERFORM set_text_0120.
ENDMODULE.                 " SET_TEXT_0120  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CLEAR_OK_CODE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.
  CLEAR ok_0100.
  IF /MSH/STOER_S_TOP-gueltigvon IS INITIAL.
    /MSH/STOER_S_TOP-gueltigvon = sy-datum.
  ENDIF.

* Changemodus
  PERFORM set_dynpro_changemode.
ENDMODULE.                 " CLEAR_OK_CODE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_REKTEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_rektext OUTPUT.
  IF NOT /MSH/STOER_S_TOP-fvgrund IS INITIAL.
    SELECT SINGLE langtext FROM tjv44 INTO gv_rektext WHERE spras = sy-langu AND fvgrund = /MSH/STOER_S_TOP-fvgrund.
    TRANSLATE gv_rektext TO UPPER CASE.
  ENDIF.
ENDMODULE.                 " SET_REKTEXT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CREATE_CONT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE create_cont OUTPUT.
  CASE sy-dynnr.
    WHEN '0210'.  "Digitalstörung
      PERFORM create_cont USING 'CONT_TEXT_210'
                          CHANGING gv_textdisplay_0210
                                   gv_textview_0210.
      PERFORM set_text_changemode USING gv_textdisplay_0210
                                        gv_textview_0210.
    WHEN '0240'.  "Produktionsstörung
      PERFORM create_cont USING 'CONT_TEXT_240'
                          CHANGING gv_textdisplay_0240
                                   gv_textview_0240.
      PERFORM set_text_changemode USING gv_textdisplay_0240
                                  gv_textview_0240.
    WHEN '0220'.  "Kundenstörung
      PERFORM create_cont USING 'CONT_TEXT_220'
                          CHANGING gv_textdisplay_0220
                                   gv_textview_0220.
      PERFORM set_text_changemode USING gv_textdisplay_0220
                            gv_textview_0220.
    WHEN '0230'.  "Liefersdtörung
      PERFORM create_cont USING 'CONT_TEXT_230'
                          CHANGING gv_textdisplay_0230
                                   gv_textview_0230.
      PERFORM set_text_changemode USING gv_textdisplay_0230
                            gv_textview_0230.
  ENDCASE.
ENDMODULE.                 " CREATE_CONT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  LOAD_ACTFORCHANGE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE load_actforchange OUTPUT.
  PERFORM load_actforchange.
ENDMODULE.                 " LOAD_ACTFORCHANGE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SHOW_ACTFORCHANGE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE show_actforchange OUTPUT.
  PERFORM show_actforchange.
ENDMODULE.                 " SHOW_ACTFORCHANGE  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_STOERTEXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_stoertext OUTPUT.
  IF /msh/stoer_s_lief-fvart IS INITIAL.
    gv_stoertext = 'Wird bei Prüfung oder Sicherung ermittelt'.
  ELSEIF gv_changemode EQ 'X'.
    SELECT SINGLE langtext FROM tjv42 INTO gv_stoertext WHERE fvart EQ /msh/stoer_s_lief-fvart AND spras EQ sy-langu.
  ENDIF.


ENDMODULE.                 " SET_STOERTEXT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  IMPORT_FROM_EXT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE import_from_ext OUTPUT.
  PERFORM import_from_ext.
ENDMODULE.                 " IMPORT_FROM_EXT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PREFILL_0230  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE prefill_0230 OUTPUT.
  PERFORM prefill_0230.
ENDMODULE.                 " PREFILL_0230  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SCREEN_CHANGE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE screen_change OUTPUT.
  LOOP AT SCREEN.
    CHECK screen-group2 EQ 'CHG'.
    CHECK gv_changemode = 'X'.
    screen-active = 0.
    screen-invisible = 1.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " SCREEN_CHANGE  OUTPUT
