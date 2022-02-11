class /MSH/CL_IM_STOER_SRCH definition
  public
  final
  create public .

public section.

  interfaces IF_EX_ISM_CIC_BP_SEARCH .
protected section.
private section.
ENDCLASS.



CLASS /MSH/CL_IM_STOER_SRCH IMPLEMENTATION.


  method IF_EX_ISM_CIC_BP_SEARCH~BP_SEARCH_WITH_DOCNR.
  endmethod.


  method IF_EX_ISM_CIC_BP_SEARCH~BUSINESS_PARTNER_SEARCH.
  endmethod.


  method IF_EX_ISM_CIC_BP_SEARCH~CONVERT_DOCNR_TO_ORDERNR.
  endmethod.


  method IF_EX_ISM_CIC_BP_SEARCH~DOCUMENT_TYPES_MODIFY.
  endmethod.


  METHOD if_ex_ism_cic_bp_search~filter_search_result.
    DATA: lv_stoer  TYPE xfeld,
          lv_guevon TYPE gueltigvon.
    CLEAR: lv_stoer, lv_guevon.
    IMPORT ex_stoer TO lv_stoer FROM MEMORY ID 'SEARCHSTOER'.
    IF lv_stoer = 'X'.
      IMPORT ev_guevon TO lv_guevon FROM MEMORY ID 'GUEVONSTOER'.
      IF sy-subrc NE 0 OR lv_guevon IS INITIAL OR lv_guevon EQ '00000000'.
        lv_guevon = sy-datum.
      ENDIF.
      /msh/cl_stoer_helper=>filter_gp_aktiv_abo( EXPORTING iv_guevon = lv_guevon CHANGING ct_addresses = p_addresstab ).
    ENDIF.
  ENDMETHOD.


  method IF_EX_ISM_CIC_BP_SEARCH~HITLIST_PREPARE_FOR_WORKSPACE.
  endmethod.


  method IF_EX_ISM_CIC_BP_SEARCH~PRELIMINARY_BUSINESS_PRTN_SRCH.
  endmethod.
ENDCLASS.
