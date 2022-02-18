*&---------------------------------------------------------------------*
*& Include /MSH/STOER_SELECT_TOP                             Modulpool        /MSH/STOER_SELECT
*&
*&---------------------------------------------------------------------*
REPORT /msh/stoer_select LINE-SIZE 80 LINE-COUNT 65 MESSAGE-ID /MSH/STOER
NO STANDARD PAGE HEADING.

* Tabellen für Selektionsbild
TABLES: /msh/stoer_t_cst,
        tjv43,
        jvtfehler,
        jgtgpnr.

TYPE-POOLS: slis.

* Konstanten, für Druckformular
CONSTANTS: con_title_stmsd   TYPE string VALUE 'Report Störungsmeldungen',
           con_versanddatum  TYPE string VALUE 'Gültig am: ',
           con_listerzeugung TYPE string VALUE 'Listerzeugung: ',
           con_seite         TYPE string VALUE 'Seite ',
           con_route         TYPE string VALUE 'Route',
           con_bezirk        TYPE string VALUE 'Bezirk',
           con_nachliefern   TYPE string VALUE 'NLK',
           con_drerz         TYPE string VALUE 'DRERZ',
           con_xbezliegt     TYPE string VALUE 'Bez.liegt',
           con_gpnr          TYPE string VALUE 'GP-Nr.',
           con_pva           TYPE string VALUE 'PVA',
           con_verspaetung   TYPE string VALUE 'Zsp',
           con_kurzadresse   TYPE string VALUE 'Kurzadresse',
           con_zustellende   TYPE string VALUE 'Zustellende',
           con_gemeldet_von  TYPE string VALUE 'gemeldet von',
           con_rekla_grd     TYPE string VALUE 'Reklamationsgrund',
           con_angelegt_am   TYPE string VALUE 'angel. am',
           con_angelegt_um   TYPE string VALUE 'angel. um',
           con_geaendert_am  TYPE string VALUE 'geänd. am',
           con_geaendert_um  TYPE string VALUE 'geänd. um',
           con_bis_zeichen   TYPE c      VALUE '-' LENGTH 1
           .

* Selektionstabellen
DATA: gt_jvtfehler  TYPE TABLE OF jvtfehler,
      gt_stoer_prod TYPE TABLE OF /msh/stoer_t_prd,
      gt_stoer_lief TYPE TABLE OF /msh/stoer_t_lf,
      gt_stoer_gp   TYPE TABLE OF /msh/stoer_t_gp,
      gt_stoer_dig  TYPE TABLE OF /msh/stoer_t_dig.

* Ausgabetabelle
DATA: gt_out TYPE TABLE OF /MSH/STOER_S_REK_OUT.

* Variante
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv.
DATA: ls_layout   TYPE slis_layout_alv.
DATA: ls_print    TYPE slis_print_alv.
DATA: ls_sortinfo TYPE slis_sortinfo_alv.
DATA: lt_sortinfo TYPE slis_t_sortinfo_alv.
DATA: lv_repid    LIKE sy-repid.
DATA: ls_variant  TYPE disvariant.
DATA: ls_fieldcat TYPE slis_fieldcat_alv.
DATA: lv_structure_name TYPE dd02l-tabname.
DATA: lv_lines TYPE i.
DATA: w_fieldcat LIKE LINE OF lt_fieldcat.
DATA: w_tabix LIKE sy-tabix.
DATA: ls_save(1) TYPE c VALUE 'A'.
DATA: lv_exit(1) TYPE c.
DATA: gx_only_ras TYPE abap_bool.
