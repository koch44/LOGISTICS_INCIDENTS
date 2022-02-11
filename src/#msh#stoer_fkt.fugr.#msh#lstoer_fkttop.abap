FUNCTION-POOL /msh/stoer_fkt MESSAGE-ID /msh/stoer.

INCLUDE rjsi1top.

TYPE-POOLS: abap.

* Störungs-Subscreen
DATA splitter_170 TYPE REF TO cl_gui_splitter_container.
DATA container_170 TYPE REF TO cl_gui_custom_container.
DATA container_170_akt TYPE REF TO cl_gui_custom_container.     "cl_gui_container
DATA container_170_hist TYPE REF TO cl_gui_custom_container.     "cl_gui_container
DATA: gt_hist TYPE TABLE OF /msh/stoer_s_interr,
      gt_akt  TYPE TABLE OF /msh/stoer_s_interr,
      gs_hist TYPE /msh/stoer_s_interr,
      gs_akt  TYPE /msh/stoer_s_interr.
DATA: gc_alv_akt  TYPE REF TO cl_gui_alv_grid,
      gc_alv_hist TYPE REF TO cl_gui_alv_grid.

* Klassendefinitionen

*&---------------------------------------------------------------------*
*&       Class gcl_dclick_170_akt
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS gcl_dclick_170_akt DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: double_click
                  FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row
                  e_column
                  es_row_no.
ENDCLASS.               "gcl_dclick_170_akt
*&---------------------------------------------------------------------*
*&       Class gcl_dclick_170_hist
*&---------------------------------------------------------------------*
*        Text
*----------------------------------------------------------------------*
CLASS gcl_dclick_170_hist DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS: double_click
                  FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row
                  e_column
                  es_row_no.
ENDCLASS.               "gcl_dclick_170_hist
