/*
    Service API for getting Billing Details.
*/
public with sharing class BWC_BillingDetailsService {

    public static final String CALLING_SYSTEM_ID = 'SFDC';
    public static final String ORIGINATOR_SYSTEM_ID = 'SFDC';

    /*
        Service API to get details for one billing statement.
    */
    public static BWC_BillingDetails.BillingDetailsResponse getBillingDetails(String product, String statementId) {

        if (product == null) {
            throw new BWC_Exception('Argument required: product');
        }

        if (statementId == null) {
            throw new BWC_Exception('Argument required: statementId');
        }

         // Request
         BWC_BillingDetails.BillingDetailsResponse response = BWC_BillingDetailsCallout.getBillingDetails(product, statementId);

         return response;
    
    }

    /*
        Service API to get PDF for one billing statement.
    */
    public static BWC_BillingDetails.BillPdfResponse getBillPdf(String product, String statementId) {

        if (product == null) {
            throw new BWC_Exception('Argument required: product');
        }

        if (statementId == null) {
            throw new BWC_Exception('Argument required: statementId');
        }

         // Request
         BWC_BillingDetails.BillPdfResponse response = BWC_BillingDetailsCallout.getBillPdf(product, statementId);

         return response;
    
    }

    /*
        Service API to get details for one billing statement.
    */
    public static BWC_BillingDetails.AdjustableLineItemsResponse getChargeCodes(String billingAccountNumber, BWC_BillingDetails.AdjustableLineItemsResponse lineItemsData) {

        Billing_Account__c ban = BWC_AccountService.getBillingAccountForBan(billingAccountNumber);

        // Build request 
        BWC_BillingDetails.ChargeCodesRequest request = new BWC_BillingDetails.ChargeCodesRequest();
        request.accountNumber = ban.Billing_Account_Number__c;
        request.accountType = ban.Account_Type__c;
        request.customerType = ban.Customer_Type__c;
        request.agentId = BWC_Utils.getCurrentUserAttId();
        request.callingSystemId = CALLING_SYSTEM_ID;
        request.originatorSystemId = ORIGINATOR_SYSTEM_ID;
        request.marketCode = ban.Billing_Market__c;
        List<BWC_BillingDetails.BillData> billData = new List<BWC_BillingDetails.BillData>();
        for (BWC_BillingDetails.AdjustableLineItem lineItem : lineItemsData.adjustableLineItems) {
            BWC_BillingDetails.BillData bill = new BWC_BillingDetails.BillData();
            bill.billSequenceNumber = lineItem.billSequenceNumber;
            bill.isBANLevel = lineItem.isBANLevel;
            bill.chargeSequenceNumber = lineItem.chargeSequenceNumber;
            if (lineItem.ctn != null) {
                bill.ctn = lineItem.ctn.replaceAll('-', '');
            }
            billData.add(bill);
        }
        request.billData = billData;

        // Request
        BWC_BillingDetails.ChargeCodesResponse chargeCodesResponse = BWC_BillingDetailsCallout.getChargeCodes(request);

        // Build response
        BWC_BillingDetails.AdjustableLineItemsResponse response = new BWC_BillingDetails.AdjustableLineItemsResponse();
        List<BWC_BillingDetails.AdjustableLineItem> lineItems = new List<BWC_BillingDetails.AdjustableLineItem>();

        Map<String, BWC_BillingDetails.AdjustableLineItem> lineItemMap = new Map<String, BWC_BillingDetails.AdjustableLineItem>();
        for (BWC_BillingDetails.AdjustableLineItem lineItem : lineItemsData.adjustableLineItems) {
            lineItemMap.put(lineItem.chargeSequenceNumber, lineItem);
        }

        for (BWC_BillingDetails.BillData bill : chargeCodesResponse.billData) {
            BWC_BillingDetails.AdjustableLineItem lineItem = lineItemMap.get(bill.chargeSequenceNumber);
            if (lineItem != null) {
                lineItem.chargeCode = bill.chargeCode;
                lineItems.add(lineItem);
            }
        }

        response.adjustableLineItems = lineItems;
        return response;
    
    }

    /**
     * 
    */
    public static BWC_BillingDetails.AdjustableLineItemsResponse getAdjustableLineItems(BWC_BillingDetails.BillingDetailsContent billingDetails) {

        // Create response with eligible line items
        BWC_BillingDetails.AdjustableLineItemsResponse response = new BWC_BillingDetails.AdjustableLineItemsResponse();

        List<BWC_BillingDetails.AdjustableLineItem> lineItems = new List<BWC_BillingDetails.AdjustableLineItem>();

        // Check for every type of charges
        if (billingDetails.acctChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('acctChrgs', billingDetails.acctChrgs, null, null));
        }
        if (billingDetails.uverseTvChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('uverseTvChrgs', billingDetails.uverseTvChrgs, null, null));
        }
        if (billingDetails.direcTvChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('direcTvChrgs', billingDetails.direcTvChrgs, null, null));
        }
        if (billingDetails.combinedDtvChrgsList != null) {
            lineItems.addAll(addServiceTypeLineItems('combinedDtvChrgsList', null, billingDetails.combinedDtvChrgsList, null));
        }
        if (billingDetails.hsiaChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('hsiaChrgs', billingDetails.hsiaChrgs, null, null));
        }
        if (billingDetails.voipChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('voipChrgs', billingDetails.voipChrgs, null, null));
        }
        if (billingDetails.wllVoiceChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('wllVoiceChrgs', billingDetails.wllVoiceChrgs, null, null));
        }
        if (billingDetails.wllIntrntChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('wllIntrntChrgs', billingDetails.wllIntrntChrgs, null, null));
        }
        if (billingDetails.wirelessChrgs != null) {
            lineItems.addAll(addServiceTypeLineItems('wirelessChrgs', null, null, billingDetails.wirelessChrgs));
        }

        for (BWC_BillingDetails.AdjustableLineItem lineItem : lineItems) {
            lineItem.billSequenceNumber = billingDetails.billInfo.billSeqNbr;
        }
        System.debug(lineItems);

        response.adjustableLineItems = lineItems;
        return response;
    
    }

    public static List<BWC_BillingDetails.AdjustableLineItem> addServiceTypeLineItems(String serviceType, BWC_BillingDetails.Service charges, List<BWC_BillingDetails.Service> combinedDtvCharges, BWC_BillingDetails.WirelessService wirelessCharges) {

        List<BWC_BillingDetails.AdjustableLineItem> eligibleLineItems = new List<BWC_BillingDetails.AdjustableLineItem>();

        if (serviceType == 'wirelessChrgs') {
            for (BWC_BillingDetails.SubscriberService serviceData : wirelessCharges.wirelessServiceList) {
                String lineItemGroup = '';
                if (serviceData.ctn != null) {
                    lineItemGroup = serviceData.ctn + ' ' + serviceData.ctnUser;
                } else {
                    lineItemGroup = serviceData.serviceDesc;
                }
                if (serviceData.sectionBeanList != null) {
                    List<BWC_BillingDetails.AdjustableLineItem> adjustableLineItems = addSectionBeanRows(serviceData.sectionBeanList, wirelessCharges.wirelessServiceDesc, lineItemGroup, serviceData.ctn);
                    eligibleLineItems.addAll(adjustableLineItems);
                }
            }
        }
        else if (serviceType == 'combinedDtvChrgsList') {
            for (BWC_BillingDetails.Service serviceData : combinedDtvCharges) {
                if (serviceData.sectionBeanList != null) {
                    List<BWC_BillingDetails.AdjustableLineItem> adjustableLineItems = addSectionBeanRows(serviceData.sectionBeanList, serviceData.serviceDesc, serviceData.serviceDesc, null);
                    eligibleLineItems.addAll(adjustableLineItems);
                }
            }
        }
        else {
            if (charges.sectionBeanList != null) {
                List<BWC_BillingDetails.AdjustableLineItem> adjustableLineItems = addSectionBeanRows(charges.sectionBeanList, charges.serviceDesc, charges.serviceDesc, null);
                eligibleLineItems.addAll(adjustableLineItems);
            }
        }

        return eligibleLineItems;
    }

    public static List<BWC_BillingDetails.AdjustableLineItem> addSectionBeanRows(List<BWC_BillingDetails.SectionBean> sectionBeanList, String service, String lineItemGroup, String ctn) {
        if (sectionBeanList == null || sectionBeanList.size() == 0) {
            return null;
        }

        List<BWC_BillingDetails.AdjustableLineItem> eligibleLineItems = new List<BWC_BillingDetails.AdjustableLineItem>();
        for (BWC_BillingDetails.SectionBean sectionBean : sectionBeanList) {

            if (sectionBean.chargeList != null) {
                for (BWC_BillingDetails.Amount charge : sectionBean.chargeList) {
                    Boolean isNotAdjustable = (charge.type == BWC_Constants.BILLING_CHARGE_TYPE_TAXES || charge.type == BWC_Constants.BILLING_CHARGE_TYPE_SURCHARGES || charge.type == BWC_Constants.BILLING_CHARGE_TYPE_PLAN_CHANGES) || (charge.type == BWC_Constants.BILLING_CHARGE_TYPE_MONTHLY_CHARGES && charge.amtInd == BWC_Constants.BILLING_CHARGE_AMTIND_CR);
                    if (!isNotAdjustable) {
                        BWC_BillingDetails.AdjustableLineItem lineItem = new BWC_BillingDetails.AdjustableLineItem();
                        lineItem.service = service;
                        lineItem.lineItemGroup = lineItemGroup;
                        lineItem.description = charge.descList[0];
                        lineItem.selectedBillAmount = charge.amt;
                        lineItem.billSequenceNumber = charge.chrgSeqNbr;
                        if (ctn != null) {
                            lineItem.isBANLevel = false;
                            lineItem.ctn = ctn;
                        } else {
                            lineItem.isBANLevel = true;
                            lineItem.ctn = null;
                        }
                        lineItem.chargeSequenceNumber = charge.chrgSeqNbr;

                        if (charge.chrgSeqNbr != null) {
                            eligibleLineItems.add(lineItem);
                        }
                    }

                }
            }

        }

        return eligibleLineItems;
    }

}