public with sharing class BWC_CreateCase {

    @AuraEnabled
    public static List<String> createCaseAuxDetail(Case obj) {
        return new List<String>();
    }

    private static Map<String, Object>  getDataMap( Map<String, Object> uiDataMap,String objName) {
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize((Map<String, Object>) uiDataMap.get(objName)));
    }

    @AuraEnabled
    public static Id createEscalationCase(Id interactionId, String ecType, String ecFeature, String detailRecord) {

        system.debug(ecType);
        system.debug(ecFeature);
        if (String.isEmpty(interactionId)) {
            return null;
        }

        //try {
        Case eCase = new Case();

        // row data
        String paymentDate;
        String paymentAmount;
        String ban;
        String paymentMethod;
        String last4;
        String paymentType;
        String methodTypeLabel;
        String paymentStatus;
        String confirmationNum;
        String ctnInContext;
        String caseType;
        String caseAction;
        String nameOnPayment;
        String paymentCategoryType;
        String orderNumber;
        String oldCaseId;
        String orderStatus;
        String orderSubStatus;
        
        Map<String, Object> detailRecordMap = (Map<String, Object>) JSON.deserializeUntyped(detailRecord);
        
        if (String.isNotBlank(detailRecord)) {
            paymentDate = (String) detailRecordMap.get('paymentDate');
            paymentAmount = (String) detailRecordMap.get('paymentAmount');
            ban = (String) detailRecordMap.get('ban');
            paymentMethod = (String) detailRecordMap.get('paymentMethod');
            last4 = (String) detailRecordMap.get('paymentMethodLastFour');
            paymentType = (String) detailRecordMap.get('paymentType');
            methodTypeLabel = (String) detailRecordMap.get('methodTypeLabel');
            paymentStatus = (String) detailRecordMap.get('paymentStatus');
            confirmationNum = (String) detailRecordMap.get('confirmationNumber');
            ctnInContext = (String) detailRecordMap.get('ctn');
            nameOnPayment = (String) detailRecordMap.get('nameOnPayment');
            paymentCategoryType = (String) detailRecordMap.get('paymentCategoryType');
            oldCaseId = (String) detailRecordMap.get('oldCaseId');
            System.debug('### paymentDate: ' + paymentDate);
            System.debug('### paymentAmount: ' + paymentAmount);
            System.debug('### ban: ' + ban);
            System.debug('### paymentMethod: ' + paymentMethod);
            System.debug('### last4: ' + last4);
            System.debug('### paymentType: ' + paymentType);
            System.debug('### methodTypeLabel: ' + methodTypeLabel);
            System.debug('### paymentStatus: ' + paymentStatus);
            System.debug('### confirmationNum: ' + confirmationNum);
            System.debug('### type: ' + paymentCategoryType);
            System.debug('### status : ' +(String) detailRecordMap.get('status'));
            orderNumber = (String)detailRecordMap.get('orderNumber');
            orderStatus = (String) detailRecordMap.get('status');
            orderSubStatus = (String) detailRecordMap.get('subStatus');
            
        }

        if (String.isNotBlank(ban)) {   
            // fetch info from Interaction
            String customerId;
            Interaction__c[] interactions = [SELECT Id, Customer__c FROM Interaction__c WHERE Id = :interactionId LIMIT 1];
            if (!interactions.isEmpty()) {
                customerId = interactions[0].Customer__c;
            }
            // get escalation record type id
            String escalationRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Escalation').getRecordTypeId();
            // common escalation case fields
            eCase.Origin = 'Phone';
            eCase.Status = 'New';
            eCase.PaymentDateProcessedByProviderBank__c = String.isNotEmpty(paymentDate) ? Date.valueOf(paymentDate) : null;
            eCase.NameTiedToPayment__c = String.isNotEmpty(nameOnPayment) ? nameOnPayment : null;
            eCase.DatePaymentPosted__c = String.isNotEmpty(paymentDate) ? Date.valueOf(paymentDate) : null;
            eCase.Amount_Charged__c = String.isNotEmpty(paymentAmount) ? Decimal.valueOf(paymentAmount) : null;
            if(String.isNotEmpty(paymentMethod) && paymentMethod.containsIgnoreCase('CREDITCARD'))
            {
                eCase.PaymentType__c = BWC_Constants.CASE_PAYMENT_TYPE_CREDIT_CARD;
                eCase.PaymentMethod__c = BWC_Constants.CASE_PAYMENT_METHOD_CARD_NUMBER;
            }else
            if(String.isNotEmpty(paymentMethod) && paymentMethod.containsIgnoreCase('ACH'))
            {
                eCase.PaymentType__c = BWC_Constants.CASE_PAYMENT_TYPE_BANK_TRANSFER_EFT;
                eCase.PaymentMethod__c = BWC_Constants.CASE_PAYMENT_METHOD_ACCOUNT_NUMBER;
            }
            //eCase.Type = ecType;
            // eCase.FeatureType__c = ecFeature;
            //  eCase.InteractionID__c = interactionId;
            eCase.Last_Interaction__c = interactionId;
            eCase.First_Interaction__c = interactionId;
            eCase.RoutingAction__c = 'Tier 1';
            eCase.AccountIdentifier__c = ban;
            String hlCaseType = ecType + ' | ' + ecFeature;
            If(hlCaseType.equalsIgnoreCase(CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT)){
                eCase.Description = CaseConstants.CASE_DESCRIPTION_ADJUSTMENT_CASES;
                eCase.RoutingAction__c ='';
            }
            eCase.Type = hlCaseType;
            caseAction = getCaseAction(hlCaseType, detailRecordMap);
            eCase.CaseAction__c = caseAction;

            eCase.CaseCategory__c = 'Escalation';
            eCase.RecordTypeId = escalationRecordTypeID;
            eCase.AccountId = customerId;
            
            //escalation case order details
            if(String.isNotEmpty(orderNumber)){
                eCase.Order_ID__c = orderNumber;
            }
            
            if(String.isNotEmpty(orderStatus)&&String.isNotEmpty(orderSubStatus)){
                eCase.Subject =   orderStatus+ ' | '+orderSubStatus;
            }
            else{
            // subject: Case Type + Case Category
            eCase.Subject = eCase.Type + ' ' + eCase.CaseCategory__c;
            }

            // Populate Call Center ID on Case with logged in user's Employee record
            Employee__c employee = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
            eCase.Call_Center_ID__c = employee?.Call_Center_ID_with_Channel__c;

            // fetch account info
            List<Billing_Account__c> baList = [SELECT
                                               Account_Type__c, Name, Product_Name_360__c, Account_Status__c, Fan_Name__c,Fan_Id__c,
                                               First_Name__c, Last_Name__c, Email__c, Contact_Number__c, Billing_Account_Number__c,
                                               Billing_Address_Line_1__c, Billing_Address_Line_2__c, Billing_City__c, Billing_Country__c, Billing_State__c, Billing_Zipcode__c,
                                               Service_Address_Line_1__c, Service_Address_Line_2__c, Service_City__c, Service_Country__c, Service_State__c, Service_Zipcode__c,
                                               Is_Unified__c, Wireless_BAN__c
                                               FROM Billing_Account__c
                                               WHERE Billing_Account_Number__c = :ban LIMIT 1];
            if (!baList.isEmpty()) {
                Billing_Account__c ba = baList[0];
                System.debug('### ACCOUNT: ' + ba);
                if (ba.Account_Type__c == BWC_Constants.ACCOUNT_TYPE_UVERSE && ba.Is_Unified__c && !String.isBlank(ba.Wireless_BAN__c)) {
                    //ecase.Billing_Account__c = ba.Wireless_BAN__c; TODO: Wireless_BAN__c IS A TEXT FIELD
                } else {
                    ecase.Billing_Account__c = ba.Id;
                }
                eCase.BillingAccountName__c = ba.Name;
                eCase.BillingAccountStatus__c = ba.Account_Status__c;

                //Billing Contact Info Population
                ecase.BillingCustFirstName__c = ba.First_Name__c;
                ecase.BillingCustLastName__c = ba.Last_Name__c;
                ecase.BillingEmail__c = ba.Email__c;
                ecase.BillingPhone__c = ba.Contact_Number__c;

                // addresses
                eCase.BillingStreet__c = ba.Billing_Address_Line_1__c;
                eCase.BillingCity__c = ba.Billing_City__c;
                if (String.isNotBlank(ba.Billing_State__c)) {
                    eCase.BillingState__c = stateNameFromStateCode(ba.Billing_State__c);
                }
                eCase.BillingZip__c = ba.Billing_Zipcode__c;
                eCase.BillingCountry__c = 'United States';

                //Service Contact fields
                eCase.ServiceCustFirstName__c = ba.First_Name__c;
                eCase.ServiceCustLastName__c = ba.Last_Name__c;
                eCase.ServicePhone__c = ba.Contact_Number__c;
                eCase.ServiceEmail__c = ba.Email__c;

                eCase.StreetName__c = (String.isNotBlank(ba.Service_Address_Line_1__c)) ? ba.Service_Address_Line_1__c : ba.Billing_Address_Line_1__c;
                eCase.City__c = (String.isNotBlank(ba.Service_City__c)) ? ba.Service_City__c : ba.Billing_City__c;
                if (String.isNotBlank(ba.Service_State__c)) {
                    eCase.State__c = stateNameFromStateCode(ba.Service_State__c);
                }
                else {
                    eCase.State__c = eCase.BillingState__c;
                }
                eCase.ZipPostalCode__c = (String.isNotBlank(ba.Service_Zipcode__c)) ? ba.Service_Zipcode__c : ba.Billing_Zipcode__c;

                eCase.Country__c = 'United States';

                // returns the primary asset. If there's no primary asset, it'll return an active asset
                Asset assetRetrieved = getAssets(ba.Id);

                //Assign Equipment info to Case
                if (assetRetrieved != null) {
                    eCase.Anchor_CTN__c = assetRetrieved.Phone_Number__c;
                    eCase.Mobile_Number_MDN__c = assetRetrieved.Phone_Number__c;
                    eCase.Mobile_Status__c = assetRetrieved.Status;
                    eCase.User_Subscriber_Name__c = assetRetrieved.User__c;

                    if (assetRetrieved.Plan__c != null) {
                        eCase.Price_Plan_Code__c = assetRetrieved ?.Plan__r ?.Plan_Price_Code__c;
                        eCase.Price_Plan_Effective_Date__c = assetRetrieved ?.Plan__r ?.Plan_Effective_Date__c;
                        eCase.Price_Plan_Description__c = assetRetrieved ?.Plan__r ?.Plan_Name__c;
                    }
                }
                Map<Id, Plan__c> planMapRetrieved = getPlans(ba.Id);

                if (planMapRetrieved.size() > 0) {
                    eCase.Product__c = getProductInfo(ba, planMapRetrieved); //ba.Product_Name_360__c;
                }

                if (String.isNotBlank(ctnInContext)) {
                    eCase.CTN__c = ctnInContext;
                }else{
                    eCase.CTN__c = eCase.Anchor_CTN__c;
                }
                
                if (eCase.Type == CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT) {

                    List<Object> lineItemDataList = (List<Object>) JSON.deserializeUntyped(JSON.serialize(detailRecordMap.get('lineItemDataList')));
                    Set<Date> billdateSet = New Set<Date>();
                    Set<Integer> billSeqNoSet = New Set<Integer>();
                    Decimal amountInDispute = 00.00;
                    for(Object obj : lineItemDataList) {
                        Map<String, Object> lineItemMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
                        billdateSet.add((String.isNotBlank((String)lineItemMap.get('billDate')))?Date.valueOf((String)lineItemMap.get('billDate')):null);
                        billSeqNoSet.add((String.isNotBlank((String)lineItemMap.get('billSequenceNumber')))?Integer.valueOf((String)lineItemMap.get('billSequenceNumber')):0);
                        amountInDispute = amountInDispute + ((String.isNotBlank((String)lineItemMap.get('requestAmount')))?Decimal.valueOf((String)lineItemMap.get('requestAmount')):00.00);
                    }
                    billdateSet.remove(null);
                    billSeqNoSet.remove(null);
                    eCase.Bill_Date__c = billdateSet.size()>0 ? New List<Date>(billdateSet).get(0) : null;
                    eCase.Bill_Seq_Number__c = billSeqNoSet.size()>0 ? New List<Integer>(billSeqNoSet).get(0) : 0;
                    eCase.Amount_in_Dispute__c = amountInDispute;

                    // SPTSFDCSPT-7592
                    Asset assetByCtn = getAssetByCTN(eCase.CTN__c, ba.Id);
                    if (assetByCtn != null) {
                        //SUBSCRIBER_STATUS = assetByCtn.status;
                        eCase.User_Subscriber_Name__c = assetByCtn.User__c;
                        eCase.Sub_Market_Site__c = assetByCtn.Submarket__c;
                        eCase.Device_Type__c = assetByCtn.Device_Type__c;
                        eCase.Device_Make_Model__c  = assetByCtn.Make_And_Model__c;
                        eCase.New_Device_Product_Code__c  = assetByCtn.Plan__r?.Plan_Code__c;
                        eCase.Device_Manufacturer__c  = assetByCtn.Manufacturer__c;
                        eCase.Device_IMEI__c  = assetByCtn.IMEI__c;
                        eCase.SIM_Smart_Chip__c  = assetByCtn.SIM__c;
                        eCase.Rate_Plan__c  = (assetByCtn.Plan__r.Billing_Account__c == eCase.Billing_Account__c) ? assetByCtn.Plan__r.Product__c : '';
                        eCase.Rate_Plan_Code__c   = (assetByCtn.Plan__r.Billing_Account__c == eCase.Billing_Account__c) ? assetByCtn.Plan__r.Plan_Code__c : '';
                    }
                }
                eCase.FAN__c = ba.Fan_Name__c;
                eCase.FAN_Number__c = ba.Fan_Id__c;
            }
            eCase.EntitlementId = BWC_SLA_Entitlement.handleSLA(eCase.Type);

            insert eCase;

            if (String.isNotEmpty(oldCaseId)) {
                BWC_Adjustment_ChatterPost.postForConvertedAdjustment(oldCaseId, eCase.Id);
            }

            System.debug('### new Case: ' + eCase);
            System.debug('### new Case ID: ' + eCase.Id);
            if(String.isNotEmpty(eCase.Id) && String.isNotEmpty(paymentDate) && String.isNotEmpty(paymentAmount))
            {
                List<List<AuxDetail__c>> listOfItems = new List<List<AuxDetail__c>>();
                List<AuxDetail__c> items = new List<AuxDetail__c>();
                if(String.isNotEmpty(paymentDate)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'Date', 
                        Value__c = convertDateString(paymentDate)));
                }
                if(String.isNotEmpty(paymentAmount)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'Amount', 
                        Value__c = '$'+paymentAmount));
                }
                if(String.isNotEmpty(ban)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'BAN', 
                        Value__c = ban));
                }
                if(String.isNotEmpty(methodTypeLabel)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'Method', 
                        Value__c = methodTypeLabel));
                }
                if(String.isNotEmpty(paymentMethod)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'PaymentMethod', 
                        Value__c = paymentMethod));
                }
                if(String.isNotEmpty(last4)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'LastFour', 
                        Value__c = last4));
                }
                if(String.isNotEmpty(paymentType)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'Type', 
                        Value__c = paymentCategoryType));
                }
                if(String.isNotEmpty(paymentStatus)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'Status', 
                        Value__c = paymentStatus));
                }
                if(String.isNotEmpty(confirmationNum)){
                    items.add(new AuxDetail__c(Case__c = eCase.Id, 
                        Name__c = 'ConfirmationNum', 
                        Value__c = confirmationNum));
                }
                System.debug('### ITEMS: ' + items);
                listOfItems.add(items);
                System.debug('### LIST OF ITEMS: ' + listOfItems);
                List<String> saveAuxDetailsResponse = BWC_AuxDetailController.saveAuxDetailsObj(eCase.Id, listOfItems);
                System.debug('### SAVE AUX DETAILS RESPONSE: ' + saveAuxDetailsResponse);
            }
        }
        if(eCase.Type == CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT){
            list<string> s = handleBillingAdjustmentCase(detailRecord,eCase);
        }
        return eCase.Id;

    }

    private static string getCaseAction(String cType, Map<String, Object> detailMap) {
        if (cType != CaseConstants.CASE_TYPE_BILLING_ADJUSTMENT) {
            return (String) detailMap.get('caseAction');
        }
        
        String cAction = (String) detailMap.get('caseAction');
        String caseAction = null;
        
        if (String.isNotEmpty(cAction)) {
            Employee__c employee = BWC_Employee_Selector.getEmployee(UserInfo.getUserId());
            if (employee.Channel1__c == 'Collections' && cAction == 'Goodwill') {
                caseAction = 'Adjustment Wireless | Goodwill Adjustment - COLL';
            } else if (employee.Channel1__c == 'Collections' && cAction == 'LineItem') {
                caseAction = 'Adjustment Wireless | Billing Adjustment - COLL';
            } else if (employee.Channel1__c != 'Collections' && cAction == 'Goodwill') {
                caseAction = 'Adjustment Wireless | Goodwill Adjustment - HLA';
            } else if (employee.Channel1__c != 'Collections' && cAction == 'LineItem') {
                caseAction = 'Adjustment Wireless | Billing Adjustment - HLA';
            }
        }
        return caseAction;
    }

    // logic for Billing adjustment Cases
    //adjusment and line items are also created here
    private static list<String> handleBillingAdjustmentCase(String uiDataMap, Case eCase)
    {
        list<String> returnIdList;

        returnIdList = BWC_AdjustmentAndLineItemWithOutShareing.handleBillingAdjustmentCase(uiDataMap, eCase);


        return returnIdList;
    }
    // Product Info assignment based on Billing Account Type
    public static String getProductInfo(Billing_Account__c ba, Map<Id, Plan__c> planMap) {
        String caseProducts;
        //Get CG Product mappings
        Map<String, String> productToCgProduct_Map = new Map<String, String> ();
        productToCgProduct_Map = MetadataSelector.productToCgProduct_Map;
        caseProducts = productToCgProduct_Map.get(ba.Account_Type__c);

        /* if(ba.Account_Type__c == 'Uverse'){
          //Get CG Product mappings
          Map<String, String> productToCgProduct_Map  = new Map<String, String>();
          productToCgProduct_Map = MetadataSelector.productToCgProduct_Map;
         
          //retrieve plans
          Map<Id,Plan__c> planMapRetrieved = getPlans(ba.Id);
         
          if(planMap.size()>0){
          Set<String> prodNames = new Set<String>();
          for(Plan__c p :planMap.values()){
          if(String.isNotBlank(p.Product__c)){
          prodNames.add(p.Product__c);
          }
          }
         
          if(prodNames.size()>0 && productToCgProduct_Map.size()>0){
         
          for(String prod:prodNames){
          if(productToCgProduct_Map.containsKey(prod)){
          //assign products
          caseProducts = (String.isNotBlank(caseProducts)?caseProducts+';'+productToCgProduct_Map.get(prod):productToCgProduct_Map.get(prod));
          }
          }
          }
          }
         
          }
          else{
          //product for non uverse type
          caseProducts = ba.Product_Name_360__c;
          } */
        return caseProducts;

    }


    //Get Plans for related Billing Account
    private static Map<Id, Plan__c> getPlans(Id billAcctId) {
        Set<Id> billingAccountIds = new Set<Id> { billAcctId };
        Map<Id, Plan__c> planMap = new Map<Id, Plan__c> (BWC_Plan_Selector.getPlansForBillingAccounts(billingAccountIds));

        return planMap;
    }

    //get Equipments related to billing account
    public static Asset getAssets(Id billAcctId) {
        Set<Id> billingAccountIds = new Set<Id> { billAcctId };
        List<Asset> assets = BWC_Asset_Selector.getAssetsForBillingAccounts(billingAccountIds);
        Asset activeAsset;

        if(assets.isEmpty()){
            return null;
        }

        for (Asset asst : assets) {

            if(asst.Status!='Canceled' && activeAsset==null){
                activeAsset=asst;
            }

            if (asst.Is_Primary__c) {
                return asst;
            }
        }

        return activeAsset;
    }

    public static Asset getAssetByCTN(String ctn, Id billAcctId){
        Set<Id> billingAccountIds = new Set<Id> { billAcctId };
        List<Asset> assets = BWC_Asset_Selector.getAssetsForBillingAccounts(billingAccountIds);

        for (Asset asst : assets) {
            if (asst.Phone_Number__c == ctn) {
                return asst;
            }
        }

        return null;
    }


    // state name from state code
    // can eventually be replaced with Metadata Selector
    private static String stateNameFromStateCode(String stateCode) {
        String stateName;

        State__mdt[] md = [SELECT State_Name__c FROM State__mdt WHERE StateCodes__c = :stateCode LIMIT 1];
        if (!md.IsEmpty()) {
            stateName = md[0].State_Name__c;
        }

        return stateName;
    }


    // convert YYYY-MM-DD to MM/DD/YYY
    private static String convertDateString(String dateStr) 
    {
        Date newDate = Date.valueOf(dateStr);
        String strDate = '';
        if (newDate != null)
        {
            Datetime dtTodayDateTime = datetime.newInstance(newDate.year(), newDate.month(),newDate.day());
            strDate = dtTodayDateTime.format('MM/dd/yyyy');
            System.debug('Date in MM/DD/YYYY format:'+strDate);
        }

        return strDate;
    }

}