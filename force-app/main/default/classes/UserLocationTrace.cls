/*
* This class is called from flow-RetailStoreLogin where the store selected by the user at the time of login is recorded 
*and sent to this method
* Author: Rashmi Thippeswamy
* Modifications Log 
* Ver   Date         Author                                    Modification
* 2.0   02-04-2021   Erashad Kurawle ekurawle@salesforce.com   Fixing Sonarqube Vulnerabilities US1000
* 2.1   05-17-2021   Srinivas Vallepu sv744h@att.com           Added Name field to lstStore query SPTSLSATT-40
*/
global without sharing class UserLocationTrace {
    /* 
*This method is called on on login flow to put the current logged in store into custom setting -UserCurrentLocation__c
*/
    @InvocableMethod
    public static void putUserLocationInCustomSetting(List<String> lstStoreIdFromFlow){
        String strStoreId='';
        strStoreId = StoreController.getStoreFromCache();
        if(String.isBlank(strStoreId)){
            if(!lstStoreIdFromFlow.isEmpty()){
                strStoreId = lstStoreIdFromFlow[0];
            }
        }
        System.debug('**** strStoreId '+strStoreId);
        System.debug('**** strStoreId from controller '+strStoreId);
        if(String.isNotBlank(strStoreId)){
            List<Store__c>  lstStore = new List<Store__c>();
            lstStore = [SELECT Name, GeoLocation__c FROM Store__c 
                        WHERE id=:strStoreId];
            if(!lstStore.isEmpty() && lstStore.size() > 0){
                List<EmployeeStoreRetail__c> esrUpdate = new List<EmployeeStoreRetail__c>();
                List<EmployeeStoreRetail__c> statusUpdate = new List<EmployeeStoreRetail__c>();
                List<EmployeeStoreRetail__c> esList = [select Id,
                                                       Employee__r.User__c,
                                                       IsLoginStore__c,Store__c,DCIPresenceStatus__c,
                                                       IsCurrentlyAvailable__c,Employee__c,Employee__r.SFProfileId__c 
                                                       from EmployeeStoreRetail__c 
                                                       where Employee__r.User__c =:UserInfo.getUserId()];
              
                Boolean recordFound = false;
                for(EmployeeStoreRetail__c esr : esList ){
                    if(esr.Store__c == lstStore[0].id && esr.Employee__r.User__c == UserInfo.getUserId()){
                        esr.IsLoginStore__c = true;
                        if(esr.Employee__r.SFProfileId__c.contains(RetailConstants.RSC_REP)){
                            esr.DCIPresenceStatus__c = RetailConstants.ONLINE;
                            esr.IsCurrentlyAvailable__c= true;
                            statusUpdate.add(esr);
                        }
                        esrUpdate.add(esr);
                    }else if (esr.Employee__r.User__c == UserInfo.getUserId() && esr.Store__c != lstStore[0].id &&  esr.IsLoginStore__c){
                        esr.IsLoginStore__c = false;
                        esrUpdate.add(esr);
                    }                    
                }

                if(!esrUpdate.isempty()){
                    upsert esrUpdate;
                    system.debug(esrUpdate +'esrUpdate');
                }
                if(!statusUpdate.isempty()){
                    DCIRepUtil.updateRepStatusBulkify(statusUpdate, 'Rep went online');
                }
                UserCurrentLocation__c userCurrLoc = UserCurrentLocation__c.getInstance(UserInfo.getUserId());
                userCurrLoc.Store__c  = lstStore[0].id;
                userCurrLoc.StoreName__c = lstStore[0].Name; // added by sv744h@att.com. SPTSLSATT-40 
                Location gLoc = lstStore[0].GeoLocation__c;
                if(userCurrLoc.id != NULL) {
                    update userCurrLoc;
                } else {
                    insert userCurrLoc;
                }
                
            }
        }
    }
}