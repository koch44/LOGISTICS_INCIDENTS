FUNCTION /MSH/STOER_GET_ROUTE.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_BEZIRK) TYPE  BEZIRK
*"     REFERENCE(IV_DATUM) TYPE  DATS DEFAULT SY-DATUM
*"  EXPORTING
*"     REFERENCE(ER_ROUTEN) TYPE  /MSH/STOER_TT_ROUTE
*"----------------------------------------------------------------------

  REFRESH: lese_knoten[],
  knoten_arten[],
  out_knoten[],
  int_zuo[],
  itab_liefbar[],
  itab_abldbar[],
  itab_abldrgl[].

  PERFORM struktur_initialisieren IN PROGRAM rjsanz33 TABLES lese_knoten
                                                             knoten_arten.
  ASSIGN ('(RJSANZ33)GV_ACT_KNOTEN') TO FIELD-SYMBOL(<fv_bez>).
  <fv_bez> = iv_bezirk.
  PERFORM datenbeschaffung IN PROGRAM rjsanz33 TABLES  lese_knoten
                                                       knoten_arten
                                                       out_knoten
                                                       int_zuo
                                                       itab_liefbar
                                                       itab_abldbar
                                                       itab_abldrgl
                                             USING     iv_datum
                                                       '33'.

  LOOP AT int_zuo ASSIGNING FIELD-SYMBOL(<fs_zuo>) WHERE knotenart2 = con_route.
    APPEND INITIAL LINE TO er_routen ASSIGNING FIELD-SYMBOL(<fs_route>).
    <fs_route>-sign = 'I'.
    <fs_route>-option = 'EQ'.
    <fs_route>-low = <fs_zuo>-knoten2.
  ENDLOOP.



ENDFUNCTION.
