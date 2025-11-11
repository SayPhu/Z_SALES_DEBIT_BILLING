CLASS zcl_billing_async DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
      CLASS-METHODS create_billing_for_dmr
          IMPORTING
           uuid type sysuuid_c32
           URL TYPE string
           cookie_name type string
           token type string
           iv_dmr TYPE i_debitmemorequesttp-debitmemorequest.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_billing_async IMPLEMENTATION.
    METHOD create_billing_for_dmr.


         try.
            DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( URL && |sap/opu/odata4/sap/api_billingdocument/srvd_a2x/sap/billingdocument/0001/BillingDocument?$top=1| ).
          catch cx_http_dest_provider_error.
            "handle exception
        endtry.
        "create HTTP client by destination
        TRY.
            data(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
          CATCH cx_web_http_client_error.
            "handle exception
        ENDTRY.
                DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
                lo_web_http_request->delete_header_field( 'Authorization' ).
                lo_web_http_request->delete_header_field( 'Accept' ).
                lo_web_http_request->delete_header_field( 'x-csrf-token' ).
                lo_web_http_request->set_header_fields( VALUE #(
                (  name = 'Content-Type' value = 'application/json' )
                (  name = 'Authorization' value = |Basic { token }| )
                (  name = 'Accept' value = 'application/json' )
                (  name = 'x-csrf-token' value = 'fetch' )
                 ) ).
        TRY.
            data(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>get ).
          CATCH cx_web_http_client_error.
            "handle exception
        ENDTRY.

        Data: sucess type if_web_http_response=>http_status,
              notAuth type if_web_http_response=>http_status,
              Update type if_web_http_response=>http_status,
              create type if_web_http_response=>http_status,
              businessPartnerID type string.
        "SET VALUE
        sucess-code = 200.
        create-code = 201.
        Update-code = 204.
        notAuth-code = 401.
        notAuth-reason = 'Unauthorized'.

        DATA(lv_response_status) = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
        IF lv_response_status = notAuth.
            TYPES ind_wa TYPE zdt_uid_async WITH INDICATORS col_ind
            TYPE abap_bool.
            DATA ind_tab TYPE TABLE OF ind_wa.
            ind_tab = VALUE #(
               (
                     client    = '100'
                     uuid_key  = uuid
                     billingid = ''
                     return_value = '401 Not Unauthorized. Check authToken'
                     col_ind-billingid = abap_true
                     col_ind-return_value = abap_true )
               ).

            UPDATE zdt_uid_async FROM TABLE @ind_tab
            INDICATORS SET STRUCTURE col_ind.

            RETURN.
        ELSEIF lv_response_status-code <> sucess-code.
            ind_tab = VALUE #(
               (
                     client    = '100'
                     uuid_key  = uuid
                     billingid = ''
                     return_value = |{ lv_response_status-code } - { lv_response_status-reason }|
                     col_ind-billingid = abap_true
                     col_ind-return_value = abap_true )
               ).

            UPDATE zdt_uid_async FROM TABLE @ind_tab
            INDICATORS SET STRUCTURE col_ind.

            RETURN.
        ENDIF.

        DATA(lv_response_x_csrf_token) = lo_web_http_response->get_header_field( 'x-csrf-token' ).
        DATA(lv_response_cookie_z91) = lo_web_http_response->get_cookie(
                                     i_name = cookie_name
*                                     i_path = ``
                                   ).
        DATA(lv_response_cookie_usercontext) = lo_web_http_response->get_cookie(
         i_name = 'sap-usercontext'
*         i_path = ``
        ).

        IF lv_response_x_csrf_token IS NOT INITIAL.
                "adding headers with API Key for API Sandbox
            TRY.
                lo_http_destination = cl_http_destination_provider=>create_by_url( url && |sap/opu/odata4/sap/api_billingdocument/srvd_a2x/sap/billingdocument/0001/BillingDocument/SAP__self.CreateFromSDDocument| ).
              CATCH cx_http_dest_provider_error.
                "handle exception
            ENDTRY.

            "create HTTP client by destination
            TRY.
                lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
              CATCH cx_web_http_client_error.
                "handle exception
            ENDTRY.
                    lo_web_http_request = lo_web_http_client->get_http_request( ).
                    lo_web_http_request->delete_header_field( 'Authorization' ).
                    lo_web_http_request->delete_header_field( 'Accept' ).
                    lo_web_http_request->delete_header_field( 'x-csrf-token' ).
                    lo_web_http_request->set_header_fields( VALUE #(
                    (  name = 'Content-Type' value = 'application/json' )
                    (  name = 'Authorization' value = |Basic { token }| )
                    (  name = 'Accept' value = 'application/json' )
                    (  name = 'x-csrf-token' value = |{ lv_response_x_csrf_token }| )
                     ) ).
                    lo_web_http_request->set_cookie(
                      EXPORTING
                        i_name    = cookie_name
                        i_value   = lv_response_cookie_z91-value
                    ).
                    lo_web_http_request->set_cookie(
                      EXPORTING
                        i_name    = 'sap-usercontext'
                        i_value   = lv_response_cookie_usercontext-value
                    ).

             Data bodyjson_update_2 type string.
             bodyjson_update_2 = '{'.
             bodyjson_update_2 = bodyjson_update_2 && |"_Control": |.
             bodyjson_update_2 = bodyjson_update_2 && '{'.
             bodyjson_update_2 = bodyjson_update_2 && |"AutomPostingToAcctgIsDisabled": false|.
             bodyjson_update_2 = bodyjson_update_2 && '},'.
             bodyjson_update_2 = bodyjson_update_2 && |"_Reference": [|.
             bodyjson_update_2 = bodyjson_update_2 && '{'.
             bodyjson_update_2 = bodyjson_update_2 && |"SDDocument": "{ |{ iv_dmr ALPHA = IN }| }",|.
             bodyjson_update_2 = bodyjson_update_2 && |"BillingDocumentType": "L2"|.
             bodyjson_update_2 = bodyjson_update_2 && '}]}'.

             lo_web_http_request->set_text( bodyjson_update_2 ).
            TRY.
                lo_web_http_response = lo_web_http_client->execute( if_web_http_client=>post ).
              CATCH cx_web_http_client_error.
                "handle exception
            ENDTRY.
            lv_response_status = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
            DATA(lv_response_2) = lo_web_http_response->get_text( ).

            IF lv_response_status-code <> create-code AND lv_response_status-code <> Update-code and lv_response_status-code <> sucess-code.
                TYPES:
                  BEGIN OF ts_detail,
                    code     TYPE string,
                    message  TYPE string,
                    severity TYPE string,
                  END OF ts_detail,

                  tt_detail TYPE STANDARD TABLE OF ts_detail WITH EMPTY KEY,

                  BEGIN OF ts_error,
                    code     TYPE string,
                    message  TYPE string,
                    details  TYPE tt_detail,
                  END OF ts_error,

                  BEGIN OF ts_response,
                    error TYPE ts_error,
                  END OF ts_response.

                  DATA ls_osm3 TYPE ts_response.
                try.
                    xco_cp_json=>data->from_string( lv_response_2 )->apply( VALUE #(
                            ( xco_cp_json=>transformation->pascal_case_to_underscore )
                            ( xco_cp_json=>transformation->boolean_to_abap_bool )
                          ) )->write_to( REF #( ls_osm3 ) ).
                CATCH cx_root INTO DATA(lx_root).

                ENDTRY.
                IF ls_osm3-error is INITIAL.
                    ind_tab = VALUE #(
                       (
                             client    = '100'
                             uuid_key  = uuid
                             billingid = ''
                             return_value = lv_response_2
                             col_ind-billingid = abap_true
                             col_ind-return_value = abap_true )
                       ).

                    UPDATE zdt_uid_async FROM TABLE @ind_tab
                    INDICATORS SET STRUCTURE col_ind.
                    RETURN.
                ELSE.
                    ind_tab = VALUE #(
                       (
                             client    = '100'
                             uuid_key  = uuid
                             billingid = ''
                             return_value = ls_osm3-error-message
                             col_ind-billingid = abap_true
                             col_ind-return_value = abap_true )
                       ).

                    UPDATE zdt_uid_async FROM TABLE @ind_tab
                    INDICATORS SET STRUCTURE col_ind.

                    RETURN.
                ENDIF.
            ELSEIF lv_response_status-code = sucess-code.
                TYPES: BEGIN OF ty_d1,
                     billingdocument TYPE vbeln,
                   END OF ty_d1,
                   ty_t_d1 TYPE STANDARD TABLE OF ty_d1 WITH EMPTY KEY,

                   BEGIN OF ty_root1,
                     value TYPE ty_t_d1,
                   END OF ty_root1.

                DATA: ls_osm4 TYPE ty_root1.
                xco_cp_json=>data->from_string( lv_response_2 )->apply( VALUE #(
                        ( xco_cp_json=>transformation->pascal_case_to_underscore )
                        ( xco_cp_json=>transformation->boolean_to_abap_bool )
                      ) )->write_to( REF #( ls_osm4 ) ).
                IF ls_osm4-value is not INITIAL.
                    ind_tab = VALUE #(
                       (
                             client    = '100'
                             uuid_key  = uuid
                             billingid = ls_osm4-value[ 1 ]-billingdocument
                             return_value = ''
                             col_ind-billingid = abap_true
                             col_ind-return_value = abap_true )
                       ).

                    UPDATE zdt_uid_async FROM TABLE @ind_tab
                    INDICATORS SET STRUCTURE col_ind.
                ENDIF.
            ENDIF.
         ENDIF.
    ENDMETHOD.
ENDCLASS.
