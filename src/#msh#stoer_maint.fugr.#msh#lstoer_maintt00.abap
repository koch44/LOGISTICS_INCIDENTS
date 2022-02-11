*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 01.07.2021 at 13:35:54
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: /MSH/STOER_T_CST................................*
DATA:  BEGIN OF STATUS_/MSH/STOER_T_CST              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/MSH/STOER_T_CST              .
CONTROLS: TCTRL_/MSH/STOER_T_CST
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */MSH/STOER_T_CST              .
TABLES: /MSH/STOER_T_CST               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
