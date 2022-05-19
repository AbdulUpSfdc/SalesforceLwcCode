public without sharing class OPUSLaunchHelper
{   
    @AuraEnabled    
    public static Boolean isRecordEngaged(String recordId){ 
        RetailCheckinQueue__c retailCheckInRecord = new RetailCheckinQueue__c();
        Boolean isValidated = false;
        try{
            retailCheckInRecord = [Select Id, Status__c From RetailCheckinQueue__c Where Id=: recordId WITH SECURITY_ENFORCED];
            if(retailCheckInRecord.Status__c == DCIConstants.ACTIVE )
                isValidated = true;
            else
            isValidated = false;	
        }
        catch(Exception e){system.debug(e);}

         return isValidated ;
    }

     /*
     * This method returns all the specifc value for the RetailCustomSetting and can be re-used in LWC
    */
    @AuraEnabled
    public static String getRetailCustomSettings(String key){
        RetailCustomSetting__c retailSetting = RetailCustomSetting__c.getValues(key);
        if(retailSetting != null)
            return retailSetting.KeyValue__c;
        return null;
    }

    @AuraEnabled    
    public static string postToOPUS(String recordId, String launchIntent){

        BWC_LIC_OpusMsgRequest.OPUSInitRequest req = new BWC_LIC_OpusMsgRequest.OPUSInitRequest();     
        BWC_LIC_OpusMsgRequest.SfCustomerInfo custInfo = new BWC_LIC_OpusMsgRequest.SfCustomerInfo();  
        BWC_OpusLIC__mdt opusConfig; 
        String param = '';  
        Boolean isEngaged;
        isEngaged = DCIController.DCIcheckIfBusywithCustomer();

        if((launchIntent=='Bill Pay-Unverified' || launchIntent=='Sell Item')  && recordId==null ){
            // As part of Bug fix CDEX-68483
            String strStoreId = StoreController.getStoreFromCache();
            List<EmployeeStoreRetail__c> empStoreList ;
            if(String.isBlank(strStoreId)){
                Store__c repsStore = LeadForm.getHomeStore('true');
                if(repsStore!=null){
                    strStoreId = repsStore.Id;
                }
            }
            Store__c repsStore1 = DCIUtil.fetchStore(strStoreId);
            system.debug('*****'+repsStore1);
            RetailCheckinQueue__c rtchk = new RetailCheckinQueue__c();
            rtchk.Store__c= repsStore1.Id;
            rtchk.CheckInTime__c= System.Now();
            if(repsStore1.TimeZone__c !=null && repsStore1.TimeZone__c !=''){
                rtchk.CreatedDateLocalTz__c = String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', repsStore1.TimeZone__c));
                rtchk.CheckInTimeLocalTz__c = String.valueof(system.now().format('yyyy-MM-dd HH:mm:ss', repsStore1.TimeZone__c));
            }

            Lead ld = new Lead();
            ld.FirstName='Guest';
            ld.Lastname='Guest';
            ld.Store__c = repsStore1.Id;
            //Bug Fix Krishna- CDEX 69577
            ld.DCICheckinType__c = 'Same Day';
            ld.LeadSource = 'In-Store Check-in';
            //ld.recordtypeid='0126g000000GN96AAG';
            ld.recordtypeid = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Digital Check In').getRecordTypeId();

            if(launchIntent=='Bill Pay-Unverified'){
            ld.ReasonforLeaving__c = 'Get help with my bill';
            }else if (launchIntent=='Sell Item'){            
                ld.ReasonforLeaving__c = 'Shop for accessories';

                       }

            if(!isEngaged){
                RetailDTO.DCIResponseDTO  newcheckinrecord =  DCILeadUtil.createDCILeadOnHelp(ld,rtchk,repsStore1);
                recordId = newcheckinrecord.checkinid;
            }
        }

        if(recordId!=null){
            try 
            {           
                List<BWC_OpusLIC__mdt> opusConfigList = [SELECT CLIENT_REQUEST__c,TOKEN_FORMAT__c,OPUS_URL__c, OPUS_URL_EXT__c ,IDEN_FORMAT__c,SYSTEM_ID__c,
                                                            HardCode_CustomerType__c FROM BWC_OpusLIC__mdt WHERE  DeveloperName = :DCIConstants.DCI_OPUS_ROW];

                RetailCheckinQueue__c retailCheckInRecord = [Select Id, Store__r.OpusId__c, Lead__r.LastName, Lead__r.FirstName, Lead__r.Email, Lead__r.MobilePhone, DCIBOPISOrder__c, Lead__c
                                                                        From RetailCheckinQueue__c Where Id=: recordId WITH SECURITY_ENFORCED];
                User currentUser = [Select Id, ATTUID__c from User where Id=: UserInfo.getUserId()];
                if(opusConfigList.size() > 0) 
                {
                    opusConfig = opusConfigList[0];
                
                    Datetime dt = Datetime.now();
                    String tokenDate = dt.formatGMT(opusConfig.TOKEN_FORMAT__c); 
                    String identDate = dt.formatGMT(opusConfig.IDEN_FORMAT__c);  
                    
                    // create a random number string that is 6 characters long (with leading digits)
                    Integer randNum = Integer.valueof((Math.random() * 1000000));
                    String randNumStr = (('00000') + randNum).right(6); 
                    String attId = currentUser.ATTUID__c;
        
                    // start populating the OPUS LIC object
                    req.sysId = opusConfig.SYSTEM_ID__c;
                    req.repDetails = attId + '|' + tokenDate;
                    req.storeLocationId = retailCheckInRecord.Store__r.OpusId__c;
                    req.relaunch = 'N';
                    req.trackingIdent = opusConfig.SYSTEM_ID__c + '-' + attId.toUpperCase() + '-' + randNumStr + '-' + identDate;
                    req.sfLeadRecordId = retailCheckInRecord.Lead__c; //US-5046
                    req.orderID = retailCheckInRecord.DCIBOPISOrder__c;
                    //req.launchIntent = String.isNotEmpty(launchIntent) && launchIntent == 'BOPIS'?'BOPIS' : 'Customer Search';
                    if(String.isNotEmpty(launchIntent))
                        req.launchIntent = launchIntent;
                    else
                        req.launchIntent = 'Customer Search';
                        
                    req.sfRecordId = retailCheckInRecord.Id;
                    req.sfCustomerInfo = new List<BWC_LIC_OpusMsgRequest.SfCustomerInfo>();
                
                    custInfo.customerLastName = retailCheckInRecord.Lead__r.LastName;
                    custInfo.customerFirstName = retailCheckInRecord.Lead__r.FirstName;
                    custInfo.email = retailCheckInRecord.Lead__r.Email;
                    custInfo.cbr = retailCheckInRecord.Lead__r.MobilePhone;
                    
                    // As part of Bug fix CDEX-68507
                    custInfo.CTN = retailCheckInRecord.Lead__r.MobilePhone;
                    /*if(launchIntent == 'Customer Search'){
                        custInfo.CTN = retailCheckInRecord.Lead__r.MobilePhone;
                    }*/
                    req.sfCustomerInfo.add(custInfo);
                    param = JSON.serialize(req,true);
                    system.debug('PARAMETER REQUEST---->' + param);

                    String url = opusConfig.OPUS_URL__c +''+opusConfig.OPUS_URL_EXT__c + opusConfig.CLIENT_REQUEST__c;
                    Map<String, String> clientreq = new Map<String,String>();
                    clientreq.put(opusConfig.CLIENT_REQUEST__c, param);
                    url = url + param;
                    
                    system.debug('URL TO LAUNCH ---->' + url);

                        return url;
                }
                else {
                    return null;
                }

            } catch (System.Exception e){
                system.debug('Exception :'+e.getStackTraceString());           
                return null;
            }
        }
        else
            return 'isEngaged';
     
    }


}