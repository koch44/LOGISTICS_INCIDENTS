*&---------------------------------------------------------------------*
*& Include /MSH/STOER_MAINT_TOP                              Modulpool        /MSH/STOER_MAINT
*&
*&---------------------------------------------------------------------*
PROGRAM /msh/stoer_maint MESSAGE-ID /msh/stoer.

* Typgruppen
TYPE-POOLS: vrm, jkd.

* Konstanten
CONSTANTS : con_text_line_length TYPE i VALUE 72 .

* Typen
TYPES : text_table_type(con_text_line_length) TYPE c OCCURS 0 .
* interne Tabelle der Bezirke
TYPES: BEGIN OF ty_bezirk,
         route      TYPE route,
         numbeablst TYPE numbeablst,
         bezirktat  TYPE bezirk,
         beablst    TYPE beablst,
         lfartlog   TYPE lfartlog,
         bezrundtat TYPE bezrundtat,
         versanddat TYPE vrsnddatum,
       END   OF ty_bezirk.

* DDIC-Strukturen
TABLES: /msh/stoer_s_top,
        /msh/stoer_s_dig,
        /msh/stoer_s_prod,
        /msh/stoer_s_gp,
        /msh/stoer_s_lief.


* Dynpro 0100 (Trägerdynpro)
DATA: ok_0100 TYPE sy-ucomm,
      gv_snew TYPE xfeld.

* Dynpro 0120 (Störungsbereich)
DATA: gv_time TYPE string,
      gv_area TYPE /msh/stoer_t_cst-area.

* Dynpro 0210 (Digitalstörung)
DATA: gv_rektext TYPE string.
DATA: gv_textview_0210    TYPE REF TO cl_gui_textedit,
      gv_textdisplay_0210 TYPE REF TO cl_gui_custom_container.

* Dynpro 0220 (Produktionsstörung)
DATA: gv_textview_0220    TYPE REF TO cl_gui_textedit,
      gv_textdisplay_0220 TYPE REF TO cl_gui_custom_container,
      gs_0220_old         TYPE /msh/stoer_s_gp.

* Dynpro 0230 (Produktionsstörung)
DATA: gv_textview_0230    TYPE REF TO cl_gui_textedit,
      gv_textdisplay_0230 TYPE REF TO cl_gui_custom_container,
      gv_stoertext        TYPE string,
      gs_0230_old         TYPE /msh/stoer_s_lief.
DATA: gt_bezirk     TYPE TABLE OF ty_bezirk,
      gs_bezirk     TYPE ty_bezirk,
      gv_lfartlog   TYPE xfeld,
      gt_bezirk_cre TYPE TABLE OF ty_bezirk,
      gt_jdtvausgb  TYPE TABLE OF jdtvausgb.

* Dynpro 0240 (Produktionsstörung)
DATA: gv_textview_0240    TYPE REF TO cl_gui_textedit,
      gv_textdisplay_0240 TYPE REF TO cl_gui_custom_container.

* Dynpro 0300 (bestehende Meldungen für Änderung)
DATA: gv_count           TYPE i,
      gt_overview        TYPE TABLE OF /msh/stoer_s_over,
      gs_overview        TYPE /msh/stoer_s_over,
      gv_changemode      TYPE xfeld,
      gc_meld_det        TYPE REF TO cl_gui_alv_grid,
      gc_cont_meld_det   TYPE REF TO cl_gui_custom_container,
      gv_stoerid         TYPE /msh/stoerid,
      gv_stoerid_old     TYPE /msh/stoerid,
      gt_chgtext         TYPE ism_tline_tab,
      gt_jvtfehler_exist LIKE STANDARD TABLE OF jvtfehler WITH DEFAULT KEY.

* Ablaufvariablen
DATA: gv_called       TYPE xfeld,
      gv_dynnr        TYPE sy-dynnr,
      gv_dynnr_change TYPE sy-dynnr,
      gv_repid        TYPE sy-repid,
      gs_cust         TYPE /msh/stoer_t_cst,
      gt_cust         TYPE TABLE OF /msh/stoer_t_cst,
      gv_openforedit  TYPE xfeld.

* Bestehende Meldungen
DATA: gc_meld      TYPE REF TO cl_gui_alv_grid,
      gc_cont_meld TYPE REF TO cl_gui_custom_container,
      gv_exist     TYPE xfeld.

* Globale Tabellen
DATA: gt_exist_lief TYPE TABLE OF /msh/stoer_s_exist_lief,
      gt_exist_prod TYPE TABLE OF /msh/stoer_s_exist_prod,
      gt_exist_gp   TYPE TABLE OF /msh/stoer_s_exist_gp,
      gt_exist_dig  TYPE TABLE OF /msh/stoer_s_exist_dig.

* Dynamische Daten
DATA : gt_dyn_table  TYPE REF TO data.
FIELD-SYMBOLS: <fs_itab> TYPE ANY TABLE,
               <fs_loop> TYPE any.

* Meldungsanzeige
DATA: gv_viewmode TYPE xfeld.
*&---------------------------------------------------------------------*
*&       Class LCL_HOTSPOT_CHANGE_OVER
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_hotspot_change_over DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS :
      on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id es_row_no.
ENDCLASS.               "LCL_HOTSPOT_CHANGE_OVER
*&---------------------------------------------------------------------*
*&       Class LCL_DCLICK_DET
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_dclick_det DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: on_double_click
                FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
ENDCLASS.               "LCL_DCLICK_DET
*&---------------------------------------------------------------------*
*&       Class LCL_DCLICK_DET
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS lcl_dclick_meld DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: on_double_click
                FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
ENDCLASS.               "LCL_DCLICK_MELD
