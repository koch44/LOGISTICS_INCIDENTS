*&---------------------------------------------------------------------*
*&  Include           /MSH/STOER_SELECT_SEL
*&---------------------------------------------------------------------*
* Selektionsbereiche
SELECTION-SCREEN BEGIN OF BLOCK area WITH FRAME TITLE text-001.
PARAMETERS: p_ord   AS CHECKBOX DEFAULT 'X',
            p_slief AS CHECKBOX DEFAULT 'X',
            p_elief AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT (40) text-002.
*PARAMETERS: p_mfr AS CHECKBOX DEFAULT space. "nicht implementiert im Standard
*SELECTION-SCREEN COMMENT (40) text-003.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_mano AS CHECKBOX DEFAULT space.
SELECTION-SCREEN END OF BLOCK area.

* Selektionsoptionen
SELECTION-SCREEN BEGIN OF BLOCK selo WITH FRAME TITLE text-004.
SELECTION-SCREEN BEGIN OF BLOCK allg WITH FRAME TITLE text-005.
SELECT-OPTIONS: s_erfus FOR jvtfehler-erfuser,
                s_erfd FOR jvtfehler-erfdate,
                s_erft FOR jvtfehler-erftime,
                s_aenus FOR jvtfehler-aenuser,
                s_aend FOR jvtfehler-aendate,
                s_aent FOR jvtfehler-aentime,
                s_grund FOR jvtfehler-fvgrund.
SELECTION-SCREEN END OF BLOCK allg.
SELECTION-SCREEN BEGIN OF BLOCK std WITH FRAME TITLE text-007.
SELECT-OPTIONS: s_fvart FOR jvtfehler-fvart.
SELECTION-SCREEN END OF BLOCK std.
SELECTION-SCREEN BEGIN OF BLOCK id WITH FRAME TITLE text-006.
SELECT-OPTIONS: s_areaid FOR /msh/stoer_t_cst-area_id MATCHCODE OBJECT /MSH/STOER_SH_AREA.
SELECTION-SCREEN END OF BLOCK id.
SELECTION-SCREEN BEGIN OF BLOCK gen WITH FRAME TITLE text-008.
SELECT-OPTIONS: s_fdat FOR jvtfehler-fehlerseit NO-EXTENSION.
SELECT-OPTIONS: s_vsg FOR jgtgpnr-gpnr MATCHCODE OBJECT mjg0.
SELECT-OPTIONS: s_bezirk FOR jvtfehler-bezirk MATCHCODE OBJECT mjvc.
SELECT-OPTIONS: s_bezrd  FOR jvtfehler-bezrunde.
SELECT-OPTIONS: s_route  FOR jvtfehler-route.
SELECT-OPTIONS: s_drerz  FOR jvtfehler-drerz.
SELECT-OPTIONS: s_pva    FOR jvtfehler-pva.
SELECT-OPTIONS: s_lfart  FOR jvtfehler-lfartlog.
SELECT-OPTIONS: s_verurs FOR jvtfehler-fvverurs.
SELECT-OPTIONS: s_gpnr  FOR jgtgpnr-gpnr MATCHCODE OBJECT mjg0.
SELECT-OPTIONS: s_vbeln FOR jvtfehler-vbeln_bas.
*SELECT-OPTIONS: s_mfr FOR tjv43-zzrelmfr NO-EXTENSION NO INTERVALS. "nicht implementiert im Standard
SELECT-OPTIONS: s_nlr FOR jvtfehler-xnachlief NO-EXTENSION NO INTERVALS.
SELECTION-SCREEN END OF BLOCK gen.
SELECTION-SCREEN END OF BLOCK selo.
SELECTION-SCREEN BEGIN OF BLOCK out WITH FRAME TITLE text-009.
PARAMETERS: p_alv  RADIOBUTTON GROUP r1 DEFAULT 'X',
            p_spo  RADIOBUTTON GROUP r1,
            p_mail RADIOBUTTON GROUP r1.
PARAMETERS: p_madr TYPE ispemail.
SELECTION-SCREEN COMMENT /1(40) text-016.
PARAMETERS: p_vari   LIKE disvariant-variant.
SELECTION-SCREEN END OF BLOCK out.
