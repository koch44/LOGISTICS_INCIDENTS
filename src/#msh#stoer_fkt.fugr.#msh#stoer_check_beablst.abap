FUNCTION /MSH/STOER_CHECK_BEABLST.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_ABLAD) TYPE  BEABLST
*"     VALUE(IV_ROUTE) TYPE  ISPROUTE
*"     VALUE(IV_GUEVON) TYPE  DATS DEFAULT SY-DATUM
*"     VALUE(IV_GUEBIS) TYPE  DATS DEFAULT '99991231'
*"  EXPORTING
*"     VALUE(EV_FOUND) TYPE  ABAP_BOOL
*"----------------------------------------------------------------------

  DATA: lt_rout TYPE jstru_rjs0805tab.

  CHECK NOT iv_ablad IS INITIAL OR iv_route IS INITIAL.

*Daten lesen
  CALL FUNCTION 'ISM_ROUTE_UNLDNG_POINT_FIND'
    EXPORTING
      in_unloadingpoint = iv_ablad
      in_validfrom      = iv_guevon
      in_validto        = iv_guebis
    IMPORTING
      out_routetab      = lt_rout.
  CHECK NOT lt_rout IS INITIAL.

  TRY.
      DATA(ls_check) = lt_rout[ struknoten = iv_route ].
      CHECK sy-subrc = 0.
      ev_found = abap_true.
    CATCH cx_root.
      RETURN.
  ENDTRY.



ENDFUNCTION.
