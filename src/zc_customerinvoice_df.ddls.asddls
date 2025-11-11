@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: 'Data Defination Customer Invoice'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_CUSTOMERINVOICE_DF
  provider contract transactional_query
  as projection on zi_customerinvoice_df
  association [1..1] to zi_customerinvoice_df as _BaseEntity on $projection.SalesOrder = _BaseEntity.SalesOrder and $projection.SalesOrderItem = _BaseEntity.SalesOrderItem
{
  
  @EndUserText: {
    label: 'Outbound Delivery', 
    quickInfo: 'Outbound Delivery'
  }
  key OutboundDelivery,
  @EndUserText: {
    label: 'Outbound Delivery Item', 
    quickInfo: 'Outbound Delivery Item'
  }
  key OutboundDeliveryItem,
  @EndUserText: {
    label: 'Sales Order', 
    quickInfo: 'Sales Order'
  }
  key SalesOrder,
  @EndUserText: {
    label: 'Item', 
    quickInfo: 'Sales Order Item'
  }
  key SalesOrderItem,
  @EndUserText: {
    label: 'Material', 
    quickInfo: 'Material'
  }
  Material,
  @EndUserText: {
    label: 'Order Quantity', 
    quickInfo: 'Order Quantity'
  }
  @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
  OrderQuantity,
  @EndUserText: {
    label: 'Order Quantity Unit', 
    quickInfo: 'Order Quantity Unit'
  }
  OrderQuantityUnit,
  
  @EndUserText: {
    label: 'Sales Group', 
    quickInfo: 'Sales Group'
  }
  SalesGroup,
  @EndUserText: {
    label: 'Sales Office', 
    quickInfo: 'Sales Office'
  }
  SalesOffice,
  @EndUserText: {
    label: 'Sales Organization', 
    quickInfo: 'Sales Organization'
  }
  SalesOrganization,
  @EndUserText: {
    label: 'Bill To Party', 
    quickInfo: 'Bill To Party'
  }
  BillToParty,
  @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
  @EndUserText: {
    label: 'Remain Quantity', 
    quickInfo: 'Remain Quantity'
  }
  RemainQty,
  @EndUserText: {
    label: 'Header Incompletion Status', 
    quickInfo: 'Header Incompletion Status'
  }
  HdrGeneralIncompletionStatus,
  @EndUserText: {
    label: 'Item Incompletion Status', 
    quickInfo: 'Item Incompletion Status'
  }
  ItemGeneralIncompletionStatus,
  _BaseEntity
}
