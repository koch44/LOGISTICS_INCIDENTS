FUNCTION /msh/call_stoer_view.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_KEY) TYPE  SWO_TYPEID
*"----------------------------------------------------------------------

* Routine im Framework rufen
  PERFORM call_view_ext IN PROGRAM /msh/stoer_maint USING iv_key.



ENDFUNCTION.
