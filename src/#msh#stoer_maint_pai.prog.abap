*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_MAINT_PAI
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
* Abfragen
  PERFORM ask_loss.
  CASE ok_0100.
    WHEN 'Z_W110'.            "Wechsel auf Dynpro 0120
      PERFORM switch_to_0120.
    WHEN 'Z_W120'.            "Wechsel zum Erfassungsbild
      CALL METHOD cl_gui_cfw=>dispatch.
      PERFORM switch_to_next.
    WHEN 'Z_CHG_0120'.      "Ändern des Zeitraums auf Dynpro 0120
      PERFORM change_dates_0110.
    WHEN 'Z_CHG_AREA'.      "Ändern des Störungsbereiches
      PERFORM change_area.
    WHEN 'Z_CHK_0210'.      "Daten auf Dynpro 0210 prüfen
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert
      PERFORM select_existent USING '0210'.
    WHEN 'Z_SAV_0210'.          "Daten auf Dynpro 0210 sichern
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert und gesichert
      PERFORM save_0210.
    WHEN 'Z_CHK_0240'.      "Daten auf Dynpro 0240 prüfen
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert
      PERFORM select_existent USING '0240'.
    WHEN 'Z_SAV_0240'.          "Daten auf Dynpro 0240 sichern
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert und gesichert
      PERFORM save_0240.
    WHEN 'Z_CHK_0220'.      "Daten auf Dynpro 0220 prüfen
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert
      PERFORM select_existent USING '0220'.
    WHEN 'Z_CHK_0230'.      "Daten auf Dynpro 0230 prüfen
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert
      PERFORM select_existent USING '0230'.
    WHEN 'Z_SAV_0220'.          "Daten auf Dynpro 0220 sichern
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert und gesichert
      PERFORM save_0220.
    WHEN 'Z_SAV_0230'.          "Daten auf Dynpro 0230 sichern
* Die Prüfungen laufen bereits im PAI, hier wird der ALV vorselektiert und gesichert
      PERFORM save_0230.
    WHEN 'Z_DEL_0210'.  "Datensatz löschen
      PERFORM delete USING '0210'.
    WHEN 'Z_DEL_0220'.  "Datensatz löschen
      PERFORM delete USING '0220'.
    WHEN 'Z_DEL_0240'.  "Datensatz löschen
      PERFORM delete USING '0240'.
    WHEN 'Z_DEL_0230'.  "Datensatz löschen
      PERFORM delete USING '0230'.
    WHEN 'Z_HS_CLICK'.
      PERFORM dummy.
    WHEN 'Z_SNEW'.
      gv_snew = 'X'.
      CASE gv_dynnr.
        WHEN '0210'.
          PERFORM save_0210.
        WHEN '0220'.
          PERFORM save_0220.
        WHEN '0230'.
          PERFORM save_0230.
        WHEN '0240'.
          PERFORM save_0240.
      ENDCASE.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  EXIT_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0100 INPUT.
* Abfragen
  PERFORM ask_loss.
  CASE ok_0100.
    WHEN 'CANCEL'.
      PERFORM initialize.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.                 " EXIT_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_DATES  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_dates INPUT.
  PERFORM check_dates.
ENDMODULE.                 " CHECK_DATES  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_AREA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_area INPUT.
  PERFORM f4_area.
ENDMODULE.                 " F4_AREA  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_AREA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_area INPUT.
  IF OK_0100 <> 'Z_CHG_0120'.
    PERFORM check_area.
  ENDIF.
ENDMODULE.                 " CHECK_AREA  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_GRUND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_grund INPUT.
  PERFORM f4_grund.
ENDMODULE.                 " F4_GRUND  INPUT
*&---------------------------------------------------------------------*
*&      Module  PAI_0210  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_0210 INPUT.
*Nur wenn einer der FCODES ausgelöst wird
  CHECK ok_0100 EQ 'Z_CHK_0210' OR ok_0100 EQ 'Z_SAV_0210' OR ok_0100 CS 'SNEW'.
  PERFORM pai_0210.
ENDMODULE.                 " PAI_0210  INPUT
*&---------------------------------------------------------------------*
*&      Module  PAI_0240  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_0240 INPUT.
*Nur wenn einer der FCODES ausgelöst wird
  CHECK ok_0100 EQ 'Z_CHK_0240' OR ok_0100 EQ 'Z_SAV_0240' OR ok_0100 CS 'SNEW'.
  PERFORM pai_0240.
ENDMODULE.                 " PAI_0240  INPUT
*&---------------------------------------------------------------------*
*&      Module  PAI_0220  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_0220 INPUT.
*Nur wenn einer der FCODES ausgelöst wird
  CHECK ok_0100 EQ 'Z_CHK_0220' OR ok_0100 EQ 'Z_SAV_0220' OR ok_0100 CS 'SNEW'.
  PERFORM pai_0220.
ENDMODULE.                 " PAI_0220  INPUT
*&---------------------------------------------------------------------*
*&      Module  PAI_0230  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_0230 INPUT.
*Nur wenn einer der FCODES ausgelöst wird
  CHECK ok_0100 EQ 'Z_CHK_0230' OR ok_0100 EQ 'Z_SAV_0230' OR ok_0100 CS 'SNEW'..
  PERFORM pai_0230.
ENDMODULE.                 " PAI_0230  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_ROUTE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_route INPUT.

ENDMODULE.                 " F4_ROUTE  INPUT
