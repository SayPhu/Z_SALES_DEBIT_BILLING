CLASS lhc_zi_customerinvoice_df DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_customerinvoice_df RESULT result.
    METHODS createinvoice FOR MODIFY
      IMPORTING keys FOR ACTION zi_customerinvoice_df~createinvoice.
    METHODS createbilling FOR MODIFY
      IMPORTING keys FOR ACTION zi_customerinvoice_df~createbilling.

ENDCLASS.

CLASS lhc_zi_customerinvoice_df IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD createInvoice.
    try.
        DATA(lv_url) = 'FRK_CUSTOMIZING'.
        DATA(lv_sys_id) = sy-sysid.
        DATA(lv_client) = sy-mandt.
        DATA: temp100 TYPE c LENGTH 3 , temp80 TYPE c LENGTH 3 , tempZIF TYPE c LENGTH 3, tempCB8 TYPE c LENGTH 3, tempJ31 TYPE c LENGTH 3.
        DATA cookie_name TYPE string.
        DATA bodyjson_update_2 type string.
              temp100 = '100'. temp80 = '80'. tempZIF = 'Z91'. tempCB8 = 'CB8'. tempJ31 = 'J31'.
        CASE lv_sys_id.
            WHEN tempZIF.
                IF lv_client = temp100.
                    lv_url  = 'FRK_CUSTOMIZING'.
                    cookie_name = 'sap-XSRF_Z91_100'.
                ELSEIF lv_client = temp80.
                    lv_url = 'FRK_DEV'.
                    cookie_name = 'sap-XSRF_Z91_80'.
                ENDIF.
            WHEN tempCB8.
                lv_url = 'FRK_TEST'.
            WHEN tempJ31.
                lv_url = 'FRK_LIVE'.
        ENDCASE.
        DATA: URL type string, token type string.

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
        try.
            IF lv_url = 'FRK_DEV'.
                URL = |https://my406848-api.s4hana.cloud.sap/|.
                token = |U0FNTF9CRUFSRVJfQVNTRVJUSU9OOmpjdGlvQHVxYzdRd1JaMyZGY1pcdytsZndmS1ldazhCVDRjWigkdjw=|.
            ELSEIF lv_url = 'FRK_CUSTOMIZING'.
                URL = |https://my406846-api.s4hana.cloud.sap/|.
                token = |QVBJX1ZUQTpocF1yTGd+U11ual1EI2g3TkQ5dytvS1RnSzlxd3VaaDhjXWp2ZUsv|.
            ENDIF.
             try.
                data(lo_http_destination) =
                     cl_http_destination_provider=>create_by_url( URL && |sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV/A_DebitMemoRequest?$top=1| ).
              catch cx_http_dest_provider_error.
                "handle exception
            endtry.
            DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
        catch cx_http_dest_provider_error.
        "handle exception
        endtry.

        "adding headers with API Key for API Sandbox
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_header_fields( VALUE #(
        (  name = 'Content-Type' value = 'application/json' )
        (  name = 'Authorization' value = |Basic { token }| )
        (  name = 'Connection' value = 'keep-alive' )
        (  name = 'x-csrf-token' value = 'fetch' )
         ) ).


        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>GET ).

        DATA(lv_response_status) = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
        IF lv_response_status = notAuth.
            APPEND VALUE #( %tky            = keys[ 1 ]-%tky
                            %msg            = new_message_with_text( text     = '401 Not Unauthorized. Check authToken'
                                                           severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.

            APPEND VALUE #(
                %tky = keys[ 1 ]-%tky
            ) TO failed-zi_customerinvoice_df.
            RETURN.
        ELSEIF lv_response_status-code <> sucess-code.
            APPEND VALUE #( %tky            = keys[ 1 ]-%tky
                            %msg            = new_message_with_text( text     = |{ lv_response_status-code } - { lv_response_status-reason }|
                                                           severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.
            APPEND VALUE #(
                %tky = keys[ 1 ]-%tky
            ) TO failed-zi_customerinvoice_df.
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
            lo_http_destination = cl_http_destination_provider=>create_by_url( URL && |sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV/A_DebitMemoRequest| ).

        "create HTTP client by destination
        lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
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

            bodyjson_update_2 = '{'.
            bodyjson_update_2 = bodyjson_update_2 && |"DebitMemoRequestType": "L2",|.
            DATA: key_f type string, body_item type string, body type string.
            TYPES: BEGIN OF zty_salesorder_items,
                 SalesOrder      TYPE string,
                 SalesOrderItem  TYPE string,
                 OutboundDelivery  TYPE string,
                 OutboundDeliveryItem  TYPE string,
                 Price  TYPE string,
                 ToBe_Invoice_Quantity  TYPE string,
                 ToBe_Invoice_Quantity_unit  TYPE string,
                 randomUUID type string,
               END OF zty_salesorder_items.
            LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
                  DATA lv_json TYPE string.
                  lv_json = <key>-%param-JsonSelectedItems.
                  IF lv_json IS INITIAL.
                    APPEND VALUE #( %tky            = <key>-%tky
                        %msg            = new_message_with_text( text     = 'Not receive any record ! Please try again'
                        severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.
                    APPEND VALUE #(
                        %tky = <key>-%tky
                    ) TO failed-zi_customerinvoice_df.
                    RETURN.
                  ENDIF.

                  DATA lt_items TYPE TABLE OF zty_salesorder_items.
                      /ui2/cl_json=>deserialize(
                        EXPORTING
                          json = lv_json
                        CHANGING
                          data = lt_items
                          ).


            bodyjson_update_2 = bodyjson_update_2 && |"ReferenceSDDocument": "{ lt_items[ 1 ]-salesorder }",|.
            bodyjson_update_2 = bodyjson_update_2 && |"HeaderBillingBlockReason": "",|.
            bodyjson_update_2 = bodyjson_update_2 && |"to_Item": [|.
            LOOP AT lt_items INTO DATA(line_item).
                bodyjson_update_2 = bodyjson_update_2 && '{'.
                bodyjson_update_2 = bodyjson_update_2 && |"ReferenceSDDocument": "{ line_item-salesorder }",|.
                bodyjson_update_2 = bodyjson_update_2 && |"ReferenceSDDocumentItem": "{ line_item-salesorderitem }",|.
                bodyjson_update_2 = bodyjson_update_2 && |"RequestedQuantity": "{ line_item-tobe_invoice_quantity }",|.
                bodyjson_update_2 = bodyjson_update_2 &&    |"to_PricingElement": [|.
                bodyjson_update_2 = bodyjson_update_2 &&    '{'.
                bodyjson_update_2 = bodyjson_update_2 &&    |"ConditionType": "PMP0",|.
                bodyjson_update_2 = bodyjson_update_2 &&    |"ConditionRateValue": "{ line_item-price }"|.
                bodyjson_update_2 = bodyjson_update_2 &&    '}]'.
                bodyjson_update_2 = bodyjson_update_2 && '},'.
            ENDLOOP.
            DATA lenght_body type int2.

            "remove last char
            lenght_body = strlen( bodyjson_update_2 ) - 1.
            bodyjson_update_2 = |{ bodyjson_update_2+0(lenght_body) }|.

            bodyjson_update_2 = bodyjson_update_2 && ']'.
            bodyjson_update_2 = bodyjson_update_2 && '}'.
            lo_web_http_request->set_text( bodyjson_update_2 ).
            lo_web_http_response = lo_web_http_client->execute( if_web_http_client=>POST ).
            lv_response_status = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
            DATA(lv_response_2) = lo_web_http_response->get_text( ).

            IF lv_response_status-code <> create-code AND lv_response_status-code <> Update-code.
                TYPES:
                BEGIN OF message1,
                  lang TYPE string,
                  value TYPE string,
                END OF message1,

                BEGIN OF ts_error1,
                  code TYPE string,
                  message TYPE message1,
                END OF ts_error1,
                BEGIN OF error1,
                  error TYPE ts_error1,
                END OF error1.
                DATA ls_osm1 TYPE error1.
                xco_cp_json=>data->from_string( lv_response_2 )->apply( VALUE #(
                        ( xco_cp_json=>transformation->pascal_case_to_underscore )
                        ( xco_cp_json=>transformation->boolean_to_abap_bool )
                      ) )->write_to( REF #( ls_osm1 ) ).
                IF ls_osm1-error is INITIAL.
                    APPEND VALUE #( %tky            = <key>-%tky
                    %msg            = new_message_with_text( text = |{ lv_response_2 }|
                    severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.

                    APPEND VALUE #(
                        %tky = <key>-%tky
                    ) TO failed-zi_customerinvoice_df.
                ELSE.

                    APPEND VALUE #( %tky            = <key>-%tky
                    %msg            = new_message_with_text( text = |{ ls_osm1-error-message-value }|
                    severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.

                    APPEND VALUE #(
                        %tky = <key>-%tky
                    ) TO failed-zi_customerinvoice_df.
                    RETURN.
                ENDIF.
            ELSEIF lv_response_status-code = create-code.

                TYPES: BEGIN OF ty_d,
                         debit_memo_request TYPE vbeln,
                       END OF ty_d,
                       BEGIN OF ty_root,
                         d TYPE ty_d,
                       END OF ty_root.

                DATA: ls_osm2 TYPE ty_root.
                xco_cp_json=>data->from_string( lv_response_2 )->apply( VALUE #(
                        ( xco_cp_json=>transformation->pascal_case_to_underscore )
                        ( xco_cp_json=>transformation->boolean_to_abap_bool )
                      ) )->write_to( REF #( ls_osm2 ) ).
                IF ls_osm2-d is not INITIAL.
                    APPEND VALUE #( %tky            = <key>-%tky
                    %msg            = new_message_with_text( text = |Debit Memo Request { ls_osm2-d-debit_memo_request } created.|
                    severity    = if_abap_behv_message=>severity-success ) ) TO reported-zi_customerinvoice_df.

*                    MODIFY ENTITIES OF I_DebitMemoRequestTP
*                      ENTITY debitmemorequest
*                      UPDATE FIELDS ( HeaderBillingBlockReason )
*                      WITH VALUE #( ( %key-DebitMemoRequest = |{ ls_osm2-d-debit_memo_request ALPHA = IN }|
*                      HeaderBillingBlockReason = '' ) )
*                      FAILED DATA(failed_update)
*                      REPORTED DATA(reported_update).

                    lo_http_destination = cl_http_destination_provider=>create_by_url( URL && |sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV/A_DebitMemoRequest('{ ls_osm2-d-debit_memo_request }')| ).

                    "create HTTP client by destination
                    lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
                            lo_web_http_request = lo_web_http_client->get_http_request( ).
                            lo_web_http_request->delete_header_field( 'Authorization' ).
                            lo_web_http_request->delete_header_field( 'Accept' ).
                            lo_web_http_request->delete_header_field( 'x-csrf-token' ).
                            lo_web_http_request->set_header_fields( VALUE #(
                            (  name = 'Content-Type' value = 'application/json' )
                            (  name = 'Authorization' value = |Basic { token }| )
                            (  name = 'Accept' value = 'application/json' )
                            (  name = 'x-csrf-token' value = 'fetch' )
                             ) ).
                        lo_web_http_response = lo_web_http_client->execute( if_web_http_client=>GET ).
                        lv_response_status = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
                        DATA(lv_response_3) = lo_web_http_response->get_text( ).

                        IF lv_response_status = notAuth.
                            APPEND VALUE #( %tky            = keys[ 1 ]-%tky
                                            %msg            = new_message_with_text( text     = '401 Not Unauthorized. Check authToken'
                                                                           severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.

                            APPEND VALUE #(
                                %tky = keys[ 1 ]-%tky
                            ) TO failed-zi_customerinvoice_df.
                            RETURN.
                        ELSEIF lv_response_status-code <> sucess-code.
                            APPEND VALUE #( %tky            = keys[ 1 ]-%tky
                                            %msg            = new_message_with_text( text     = |{ lv_response_status-code } - { lv_response_status-reason }|
                                                                           severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.
                            APPEND VALUE #(
                                %tky = keys[ 1 ]-%tky
                            ) TO failed-zi_customerinvoice_df.
                            RETURN.
                        ENDIF.

                        lv_response_x_csrf_token = lo_web_http_response->get_header_field( 'x-csrf-token' ).
                        lv_response_cookie_z91 = lo_web_http_response->get_cookie(
                                                     i_name = cookie_name
*                                                     i_path = ``
                                                   ).
                        lv_response_cookie_usercontext = lo_web_http_response->get_cookie(
                         i_name = 'sap-usercontext'
*                         i_path = ``
                        ).

                        IF lv_response_x_csrf_token IS NOT INITIAL.

                            lo_http_destination = cl_http_destination_provider=>create_by_url( URL && |sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV/A_DebitMemoRequest('{ ls_osm2-d-debit_memo_request }')| ).

                            "create HTTP client by destination
                            lo_web_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
                                    lo_web_http_request = lo_web_http_client->get_http_request( ).
                                    lo_web_http_request->delete_header_field( 'Authorization' ).
                                    lo_web_http_request->delete_header_field( 'Accept' ).
                                    lo_web_http_request->delete_header_field( 'x-csrf-token' ).
                                    lo_web_http_request->set_header_fields( VALUE #(
                                    (  name = 'Content-Type' value = 'application/json' )
                                    (  name = 'Authorization' value = |Basic { token }| )
                                    (  name = 'Accept' value = 'application/json' )
                                    (  name = 'If-Match' value = '*' )
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

                             bodyjson_update_2 = '{'.
                                    bodyjson_update_2 = bodyjson_update_2 && |"HeaderBillingBlockReason": ""|.
                                    bodyjson_update_2 = bodyjson_update_2 && '}'.


                             lo_web_http_request->set_text( bodyjson_update_2 ).
                                lo_web_http_response = lo_web_http_client->execute( if_web_http_client=>PATCH ).
                                lv_response_status = lo_web_http_response->get_status( )."GET RESPONSE STATUS\
                                DATA(lv_response_4) = lo_web_http_response->get_text( ).

                            IF lv_response_status-code = update-code.
                                APPEND VALUE #( %tky            = <key>-%tky
                                %msg            = new_message_with_text( text = |Debit Memo Request { ls_osm2-d-debit_memo_request } Status Updated.|
                                severity    = if_abap_behv_message=>severity-success ) ) TO reported-zi_customerinvoice_df.
                            ENDIF.
                        ENDIF.
                        INSERT zdt_uid_async  FROM TABLE @( VALUE #(
                            (
                                client = '100'
                                uuid_key     = lt_items[ 1 ]-randomuuid
                                billingid    = |{ ls_osm2-d-debit_memo_request ALPHA = IN }|
                                return_value = ''
                           )
                        ) ).
                    ENDIF.


                    DATA: lt_table TYPE TABLE OF zdt_dmrremainqty,
                    ls_line TYPE zdt_dmrremainqty.

                    LOOP AT lt_items INTO DATA(line_log).
                        DATA: so_type type vbeln,
                          so_item_type type posnr_va,
                          outbound type vbeln_vl,
                          outbound_item type posnr_vl.

                        outbound            = |{ line_log-outbounddelivery ALPHA = IN }|.
                        so_type        = |{ line_log-salesorder ALPHA = IN }|.
                        so_item_type      = line_log-salesorderitem.
                        outbound_item       = line_log-outbounddeliveryitem.
                        SELECT SINGLE * FROM zdt_dmrremainqty WHERE
                            outbounddelivery     = @outbound AND
                            salesorder           = @so_type AND
                            salesorderitem       = @so_item_type AND
                            outbounddeliveryitem = @outbound_item INTO @ls_line.
                        IF ls_line IS NOT INITIAL.
                            "Found the record -> ls_row contains data
                        TYPES ind_wa TYPE zdt_dmrremainqty WITH INDICATORS col_ind
                                 TYPE abap_bool.
                        DATA ind_tab TYPE TABLE OF ind_wa.
                        ind_tab = VALUE #(
                           (
                                outbounddelivery     = outbound
                                outbounddeliveryitem = outbound_item
                                salesorder           = so_type
                                salesorderitem       = so_item_type
                                quantity             = ls_line-quantity + line_log-tobe_invoice_quantity
                                quantity_unit        = line_log-tobe_invoice_quantity_unit
                                 col_ind-quantity = abap_true
                                 col_ind-quantity_unit = abap_true )
                           ).

                        UPDATE zdt_dmrremainqty FROM TABLE @ind_tab
                            INDICATORS SET STRUCTURE col_ind.
                        ELSE.
                            " Not found
                            INSERT zdt_dmrremainqty  FROM TABLE @( VALUE #(
                            (
                                client = '100'
                                outbounddelivery     = outbound
                                outbounddeliveryitem = outbound_item
                                salesorder           = so_type
                                salesorderitem       = so_item_type
                                quantity             = line_log-tobe_invoice_quantity
                                quantity_unit        = line_log-tobe_invoice_quantity_unit
                           )
                        ) ).
                        ENDIF.
                    ENDLOOP.
            ENDIF.
          ENDLOOP.
       ENDIF.
   " catch any error
    CATCH cx_root INTO DATA(lx_root).


    ENDTRY.
  ENDMETHOD.

  METHOD createBilling.
    DATA(lv_url) = 'FRK_CUSTOMIZING'.
        DATA(lv_sys_id) = sy-sysid.
        DATA(lv_client) = sy-mandt.
        DATA: temp100 TYPE c LENGTH 3 , temp80 TYPE c LENGTH 3 , tempZIF TYPE c LENGTH 3, tempCB8 TYPE c LENGTH 3, tempJ31 TYPE c LENGTH 3.
        DATA cookie_name TYPE string.
        DATA bodyjson_update_2 type string.
              temp100 = '100'. temp80 = '80'. tempZIF = 'Z91'. tempCB8 = 'CB8'. tempJ31 = 'J31'.
        CASE lv_sys_id.
            WHEN tempZIF.
                IF lv_client = temp100.
                    lv_url  = 'FRK_CUSTOMIZING'.
                    cookie_name = 'sap-XSRF_Z91_100'.
                ELSEIF lv_client = temp80.
                    lv_url = 'FRK_DEV'.
                    cookie_name = 'sap-XSRF_Z91_80'.
                ENDIF.
            WHEN tempCB8.
                lv_url = 'FRK_TEST'.
            WHEN tempJ31.
                lv_url = 'FRK_LIVE'.
        ENDCASE.
        DATA: URL type string, token type string.

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
        try.
            IF lv_url = 'FRK_DEV'.
                URL = |https://my406848-api.s4hana.cloud.sap/|.
                token = |U0FNTF9CRUFSRVJfQVNTRVJUSU9OOmpjdGlvQHVxYzdRd1JaMyZGY1pcdytsZndmS1ldazhCVDRjWigkdjw=|.
            ELSEIF lv_url = 'FRK_CUSTOMIZING'.
                URL = |https://my406846-api.s4hana.cloud.sap/|.
                token = |QVBJX1ZUQTpocF1yTGd+U11ual1EI2g3TkQ5dytvS1RnSzlxd3VaaDhjXWp2ZUsv|.
            ENDIF.

            FIELD-SYMBOLS <fs_item> TYPE zdt_uid_async.
          LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
           TYPES: BEGIN OF zty_salesorder_items,
                 SalesOrder      TYPE string,
                 SalesOrderItem  TYPE string,
                 OutboundDelivery  TYPE string,
                 OutboundDeliveryItem  TYPE string,
                 Price  TYPE string,
                 ToBe_Invoice_Quantity  TYPE string,
                 ToBe_Invoice_Quantity_unit  TYPE string,
                 randomUUID type string,
               END OF zty_salesorder_items.
           DATA lv_json TYPE string.
                  lv_json = <key>-%param-JsonSelectedItems.
                  IF lv_json IS INITIAL.
                    APPEND VALUE #( %tky            = <key>-%tky
                        %msg            = new_message_with_text( text     = 'Not receive any record ! Please try again'
                        severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.
                    APPEND VALUE #(
                        %tky = <key>-%tky
                    ) TO failed-zi_customerinvoice_df.
                    RETURN.
                  ENDIF.

                  DATA lt_items TYPE TABLE OF zty_salesorder_items.
                      /ui2/cl_json=>deserialize(
                        EXPORTING
                          json = lv_json
                        CHANGING
                          data = lt_items
                          ).
          LOOP AT lt_items into DATA(ls_item).
            SELECT SINGLE * FROM zdt_uid_async WHERE uuid_key = @ls_item-randomuuid INTO @data(lt_uid_async).
          ENDLOOP.
              IF sy-subrc = 0.
                  CALL METHOD zcl_billing_async=>create_billing_for_dmr
                  EXPORTING
                  uuid   = lt_uid_async-uuid_key
                  url    = url
                  token  = token
                  cookie_name = cookie_name
                  iv_dmr = |{ lt_uid_async-billingid ALPHA = IN }|.

                  SELECT SINGLE * FROM zdt_uid_async
                  WHERE uuid_key =  @ls_item-randomuuid
                  INTO @DATA(ls_result).

                  IF sy-subrc = 0.
                     IF ls_result-billingid IS INITIAL.
                          APPEND VALUE #( %tky            = <key>-%tky
                                %msg            = new_message_with_text( text = |{ ls_result-return_value }|
                                severity    = if_abap_behv_message=>severity-error ) ) TO reported-zi_customerinvoice_df.
                         APPEND VALUE #(
                        %tky = <key>-%tky
                    ) TO failed-zi_customerinvoice_df.

                     ELSE.
                        APPEND VALUE #( %tky            = <key>-%tky
                            %msg            = new_message_with_text( text = |Billing Document { ls_result-billingid } created.|
                            severity    = if_abap_behv_message=>severity-success ) ) TO reported-zi_customerinvoice_df.
                     ENDIF.
                ELSE.
                  APPEND VALUE #( %tky = <key>-%tky
                                  %msg = new_message_with_text(
                                             text = 'Billing creation in progress...'
                                             severity = if_abap_behv_message=>severity-information ) )
                         TO reported-zi_customerinvoice_df.
                ENDIF.
             ENDIF.
          ENDLOOP.
          CATCH cx_root INTO DATA(lx_root).

          ENDTRY.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_customerinvoice_df DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zi_customerinvoice_df IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
