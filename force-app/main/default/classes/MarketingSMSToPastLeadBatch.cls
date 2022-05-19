/*
* This Batch class is used to send SMS to the past leads based on some criteria. 
* This Batch executes only in the Business day
* Test class : MarketingSMSToPastLeadSchedule_Test
* Author: Madhava Allam
* Created Date: 8/23/2021 
*/

public without sharing class MarketingSMSToPastLeadBatch implements Database.Batchable<sObject> {
    public String query;
    public set<string> eligibileStatesSet;
    public static final string ATT_SERVICES = 'AT&T Services';
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(query == null || query == '') {
            query = 'SELECT Id,FirstName,LastName,Marketing_SMS_Sent_Date__c,MobilePhone,Owner__c,Owner__r.FirstName,ProductsDiscussed__c'
                    +' FROM Lead WHERE Store__r.State__c IN : eligibileStatesSet AND Status = \'Captured\''
                    +' AND LeadExpirationDate__c > TODAY AND SmsConsent__c = \'Yes\''
                    +' AND RecordType.developerName != \'DigitalCheckIn\' AND Marketing_SMS_Sent_Date__c = null'
                    +' AND LeadSource IN (\'Customer Interaction\',\'Customer Interaction - Business\')'
                    +' AND Store__r.Turn_Off_Marketing_SMS__c = false'
                    +' AND ProductsDiscussed__c != null';
        
            if(!test.isRunningTest()) {
                query += ' AND (NextFollowUpDate__c < TODAY OR NextFollowUpDate__c = null) AND ExpiryDate__c < TODAY';
            }
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Lead> scope){
        set<Id> leadIdsSet = new set<Id>();
        map<string,string> productMap = new map<string,string>();
        map<double,string> productSequenceMap = new map<double,string>();
        for(Lead_Products_Mapping__mdt lpm : [SELECT Id,Product__c, Sub_Product__c,Sequence__c 
                                                FROM Lead_Products_Mapping__mdt ORDER BY Sequence__c ASC NULLS LAST]) {
            productMap.put(lpm.Sub_Product__c.toLowerCase(),lpm.Product__c);
            productSequenceMap.put(lpm.Sequence__c,lpm.Product__c);
        }
        list<MessagingChannel> msgChannel = [SELECT Id,developername FROM MessagingChannel 
                                                WHERE developername = 'RetailTFNConsumer' AND MessageType = 'Text' AND IsActive = true];
                                                
        if(msgChannel != null) {
            set<Id> ownerIds = new set<Id>();
            map<Id,string> ownerStoreIdMap = new map<Id,string>();
            for(Lead leadSO : scope) {
                ownerIds.add(leadSO.Owner__c);
            }
            for(Employee__c empSO : [Select Id,User__c, MyStoreId__c from Employee__c where User__c IN : ownerIds
                                    And IsActive__c= true ]) {
                
                ownerStoreIdMap.put(empSO.User__c,empSO.MyStoreId__c);
            }
            
            list<MessageCollection> msgList = new list<MessageCollection>();
            map<id,lead> leadMap = new map<id,lead>();
            map<String, String> shortCodeResponseMap = new map<String, String>();
            String storeURL = RetailConstants.RETAIL_MYSTORE;
            for(RetailDCIAutoResponseSMS__mdt autoResponse : [SELECT ShortCode__c, AutoResponse__c FROM RetailDCIAutoResponseSMS__mdt]){
                shortCodeResponseMap.put(autoResponse.ShortCode__c, autoResponse.AutoResponse__c);
            }
            for(Lead leadSO : scope) {
                
                MessageCollection msgVar = new MessageCollection();
                msgVar.MessageId = '';
                if(ownerStoreIdMap.containsKey(leadSO.Owner__c)) {
                    if(ownerStoreIdMap.get(leadSO.Owner__c) != null) {
                        storeURL = String.format(storeURL , new list<Object>{ownerStoreIdMap.get(leadSO.Owner__c)});
                    }
                    else if(!test.isRunningTest()){
                        storeURL = String.format(storeURL , new list<Object>{''});
                    }
                }
                else if(storeURL != null){
                    storeURL = String.format(storeURL , new list<Object>{''});
                }
                set<string> productInterested = new set<string>();
                for(string product : leadSO.ProductsDiscussed__c.split(';')) {
                    if(productMap.containsKey(product.toLowerCase())) {
                        productInterested.add(productMap.get(product.toLowerCase()));
                    }
                }
                string products = '';
                list<string> productsList = new list<string>();
                list<Double> sequenceList = new list<Double>(productSequenceMap.keySet());
                sequenceList.sort();
                for(Double IntVal : sequenceList) {
                    if(productInterested.contains(productSequenceMap.get(IntVal))) {
                        productsList.add(productSequenceMap.get(IntVal));
                    }
                }
                
                if(!productInterested.isEmpty()) {
                    if(productsList.size() == 1) {
                        products = productsList[0];
                    }
                    else if(productsList.size() == 2){
                        products = productsList[0]+' and '+productsList[1];
                    }
                    else {
                        products = productsList[0]+', '+productsList[1]+', and '+productsList[2];
                    }
                }
                else {
                    products = ATT_SERVICES;
                }
                string msgContent = shortCodeResponseMap.get('MarketingSMS');
                string leadFirstName = leadSO.FirstName == null ? leadSO.LastName.toLowerCase():leadSO.FirstName.toLowerCase();
                string ownerFirstName = leadSO.Owner__r.FirstName.toLowerCase();
                //Exception case
                if(leadFirstName.startsWith('o\'')) {
                    list<string> strList = leadFirstName.split('\'');
                    leadFirstName = strList[0].capitalize()+'\''+strList[1].capitalize();
                }
                else if(leadFirstName.startsWith('mc')) {
                    string str = leadFirstName.removeStart('mc');
                    leadFirstName = 'Mc'+str.capitalize();
                }
                else {
                    leadFirstName = leadFirstName.capitalize();
                }
                if(ownerFirstName.startsWith('o\'')) {
                    list<string> strList = ownerFirstName.split('\'');
                    ownerFirstName = strList[0].capitalize()+'\''+strList[1].capitalize();
                }
                else if(ownerFirstName.startsWith('mc')) {
                    string str = ownerFirstName.removeStart('mc');
                    ownerFirstName = 'Mc'+str.capitalize();
                }
                else {
                    ownerFirstName = ownerFirstName.capitalize();
                }
                
                list<string> paramList = new list<string>{leadFirstName, ownerFirstName,products, storeURL};
                msgVar.MessageToSend = string.format(msgContent,paramList);
                msgVar.MessagingChannelDeveloperName = msgChannel[0].developername;
                msgVar.PhoneNumberToMessage = leadSO.MobilePhone;
                msgVar.RecordIdToAssociateTo = leadSO.Id;
                msgList.add(msgVar); 
                leadIdsSet.add(leadSO.Id);
            }
            if(!msgList.isEmpty()) {
                Map<String, Object> retailSMS = new Map<String, Object>();
                retailSMS.put('MessageCollection', (Object)msgList);
                NotificationsHandler.callFlow(RetailConstants.RETAIL_LEAD_SMS, retailSMS);  
            }
            string userName = userInfo.getFirstName()+ ' ' +userInfo.getLastName();
            for(Messaging_Message__c mmSO : [SELECT Id,name,Lead__c,Message_Content__c FROM Messaging_Message__c
                                                WHERE Lead__c IN : leadIdsSet AND Was_Sent__c = true AND Sent_By__c =: userName]) {
                
                Lead leadSO = new Lead();
                leadSO.id = mmSO.Lead__c;
                leadSO.Marketing_SMS_Sent_Date__c = System.today();
                leadMap.put(leadSO.Id, leadSO);
            }
            if(!leadMap.isEmpty()) {
                Database.update(leadMap.values(),false);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}