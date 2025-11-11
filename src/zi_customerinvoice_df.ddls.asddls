@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data Defination Customer Invoice'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zi_customerinvoice_df as select from I_SalesOrderItem
join I_SalesOrder on I_SalesOrder.SalesOrder = I_SalesOrderItem.SalesOrder
join I_OutboundDeliveryItem on I_OutboundDeliveryItem.ReferenceSDDocument = I_SalesOrderItem.SalesOrder and I_OutboundDeliveryItem.ReferenceSDDocumentItem = I_SalesOrderItem.SalesOrderItem
left outer join zdt_dmrremainqty on I_OutboundDeliveryItem.OutboundDelivery = zdt_dmrremainqty.outbounddelivery 
and I_OutboundDeliveryItem.OutboundDeliveryItem = zdt_dmrremainqty.outbounddeliveryitem
and I_OutboundDeliveryItem.ReferenceSDDocument = zdt_dmrremainqty.salesorder
and I_OutboundDeliveryItem.ReferenceSDDocumentItem = zdt_dmrremainqty.salesorderitem
{
    
    key I_OutboundDeliveryItem.OutboundDelivery,
    key I_OutboundDeliveryItem.OutboundDeliveryItem,
    key I_SalesOrderItem.SalesOrder,
    key I_SalesOrderItem.SalesOrderItem,
    I_SalesOrderItem.Material,
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    I_SalesOrderItem.OrderQuantity,
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    case 
        when coalesce(zdt_dmrremainqty.quantity, 0) = 0 
            then I_SalesOrderItem.OrderQuantity
        else I_SalesOrderItem.OrderQuantity - zdt_dmrremainqty.quantity
    end as RemainQty,
    I_SalesOrderItem.OrderQuantityUnit,
    I_SalesOrderItem.SalesOrganization,
    I_SalesOrderItem.BillToParty,
    I_SalesOrderItem.SalesGroup,
    I_SalesOrderItem.SalesOffice,
    @ObjectModel.foreignKey.association: '_HdrGeneralIncompletionStatus'
    I_SalesOrder.HdrGeneralIncompletionStatus,
    @ObjectModel.foreignKey.association: '_SDProcessStatus'
    I_SalesOrderItem.SDProcessStatus,
    @ObjectModel.foreignKey.association: '_ItemGeneralIncompletionStatus'
    I_SalesOrderItem.ItemGeneralIncompletionStatus,
    I_SalesOrderItem._ItemGeneralIncompletionStatus,
    I_SalesOrderItem._SDProcessStatus,
    I_SalesOrder._HdrGeneralIncompletionStatus
}
where
    coalesce(zdt_dmrremainqty.quantity, 0) <> I_SalesOrderItem.OrderQuantity
