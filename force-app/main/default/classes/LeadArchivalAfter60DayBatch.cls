/*
* Author : Rajesh Meda
* Purpose: This batch class will be executed from Scheduler class every day
* and Will move all closed leads which are 60 days old into the archival object.
* 
*
* Modifications Log 
* Ver   Date         Author                                    Modification
* 2.0   02-04-2021   Erashad Kurawle ekurawle@salesforce.com   Fixing Sonarqube Vulnerabilities US994
*/
public without sharing class LeadArchivalAfter60DayBatch implements Database.Batchable<sObject>, Database.Stateful {
    public String query;
    public Lead_Archival_Configuration__mdt leadArchivalConfig;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        leadArchivalConfig = [SELECT Id, Create_Archival_Record__c, Delete_Actual_Record__c, Record_Limit__c, Lead_Archive_Age__c FROM Lead_Archival_Configuration__mdt WHERE DeveloperName = 'Lead_Archival' LIMIT 1];
        query = getQuery('Lead');
        query = query + ' WHERE RecordTypeId !=\''+RetailConstants.DIGITALCHECKIN_RECORDTYPEID+'\' and Status LIKE \'%Closed%\' AND ';
		
        if(leadArchivalConfig.Lead_Archive_Age__c != Null){
            integer leadArchiveAgeAllowed = integer.valueOf(leadArchivalConfig.Lead_Archive_Age__c);
            query = query + ' CloseDate__c < LAST_N_DAYS:' + leadArchiveAgeAllowed +' order by lastmodifieddate desc';
        }else{
            query = query + ' CloseDate__c < LAST_N_DAYS:60 order by lastmodifieddate desc';
        }
        if(leadArchivalConfig.Record_Limit__c != null){
            query = query + ' LIMIT ' + integer.valueOf(leadArchivalConfig.Record_Limit__c);
        }
        System.debug('query is:'+query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Map <Id, Lead> leadsToDeleteMap = new Map<Id, Lead>();
        for(sObject s : scope){
            Lead leadRec = (Lead)s;
            leadsToDeleteMap.put(leadRec.Id, leadRec);
        }
        
        if(leadsToDeleteMap.size() > 0){
            Set<Id> leadIdsToDeleteSet = new Set<Id>(leadsToDeleteMap.keySet());
            if(leadArchivalConfig.Create_Archival_Record__c != null && leadArchivalConfig.Create_Archival_Record__c){
                buildArchivalData('LeadArchival__c', 'Lead', leadsToDeleteMap.values());
            }
            
            List<Messaging_Message__c> messagesToDelete = new List<Messaging_Message__c>();
            String messageQuery = getQuery('Messaging_Message__c');
            messageQuery = messageQuery + ' WHERE Lead__c IN: leadIdsToDeleteSet';
            messagesToDelete = Database.query(messageQuery);
            if(leadArchivalConfig.Create_Archival_Record__c != null && leadArchivalConfig.Create_Archival_Record__c){
                buildArchivalData('Messaging_MessageArchival__c', 'Messaging_Message__c', messagesToDelete);
            }           
            
            List<Task> tasksToDelete = new List<Task>();
            String taskQuery = getQuery('Task');
            taskQuery = taskQuery + ' WHERE WhoId IN: leadIdsToDeleteSet';
            tasksToDelete = Database.query(taskQuery);
            if(leadArchivalConfig.Create_Archival_Record__c != null && leadArchivalConfig.Create_Archival_Record__c){
                buildArchivalData('TaskArchival__c', 'Task', tasksToDelete);
            }
            
            
            if(leadArchivalConfig.Delete_Actual_Record__c != null && leadArchivalConfig.Delete_Actual_Record__c){
                database.delete(tasksToDelete, false);
                database.delete(messagesToDelete, false);
                database.delete(leadsToDeleteMap.values(), false);
            }
            
        }
    }
    
    public void finish(Database.BatchableContext BC){
        BatchStatus__c batchDetails = BatchStatus__c.getValues(RetailConstants.LEAD_ARCHIVAL_BATCH_NAME);
        if(batchDetails != null && batchDetails.Email__c != null) {
            // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                              FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            if(a != null) {
                // Send an email to the Apex job's submitter notifying of job completion.
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                list<String> toAddresses = batchDetails.Email__c.split(';');
                mail.setToAddresses(toAddresses);
                mail.setSubject(RetailConstants.LEAD_ARCHIVAL_BATCH_NAME+' Batch ' + a.Status);
                mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
    public String getQuery(String objectName){
        String query = 'Select ';
        
        Map<String, fieldDetails> fieldsMap = getFieldsDataMap(objectName);
        for(String field: fieldsMap.keyset()){
            fieldDetails fieldInfo = fieldsMap.get(field);
            if(fieldInfo.isAccessible){
                query = query + fieldInfo.name + ',';
                if(String.isNotBlank(fieldInfo.type) && String.isNotBlank(fieldInfo.relationshipName) && fieldInfo.type == 'Relationship'){
                    if(objectName.equalsIgnoreCase('Task')) {
                        if(!fieldInfo.Name.equalsIgnoreCase('Knowledge__c'))
                            query = query + fieldInfo.relationshipName + '.Name,';
                        } else {
                            query = query + fieldInfo.relationshipName + '.Name,';
                        }
                }
            }
        }
        query = query.contains(',') ? query.removeEnd(',') : query;
        query = query + ' FROM ' + objectName;
        return query;
    }
    
    public void buildArchivalData(String archivalObjectName, String actualObjectName, List<Sobject> actualRecords){
        Map<String, fieldDetails> actualObjectFieldsMap = getFieldsDataMap(actualObjectName);
        Map<String, fieldDetails> archivalObjectFieldsMap = getFieldsDataMap(archivalObjectName);
        List<SObject> archivalObjectList = new List<SObject>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        
        for(Sobject actualRecord :actualRecords){
            SObject archivalObject = gd.get(archivalObjectName).newSObject();
            for(String actualObjectField:actualObjectFieldsMap.keyset()){
                fieldDetails actualObjectFieldInfo = actualObjectFieldsMap.get(actualObjectField);
                
                if(actualObjectFieldInfo.isAccessible){
                    if(!actualObjectFieldInfo.isCustom){    
                    	actualObjectFieldInfo.name = actualObjectFieldInfo.name + '__c';
                    }
                    if(archivalObjectFieldsMap.containsKey(actualObjectFieldInfo.name) && archivalObjectFieldsMap.get(actualObjectFieldInfo.name).name == actualObjectFieldInfo.name){
                        fieldDetails archivalObjectFieldInfo = archivalObjectFieldsMap.get(actualObjectFieldInfo.name);
                        if(String.isNotBlank(actualObjectFieldInfo.type) && String.isNotBlank(actualObjectFieldInfo.relationshipName) && actualObjectFieldInfo.type == 'Relationship'){
                            SObject relObjChild = actualRecord.getSObject(actualObjectFieldInfo.relationshipName); 
                            if(relObjChild != Null){
                                String relationShipFieldNameValue = String.valueOf(relObjChild.get('Name'));
                                if(String.isNotBlank(relationShipFieldNameValue)){
                                    if(archivalObjectFieldInfo.isUpdateable){
                                        try{
                                        	archivalObject.put(archivalObjectFieldInfo.name, relationShipFieldNameValue);
                                        }catch (exception e){
                                            System.debug('Error: '+ e.getMessage() + ' Stack trace:'+ e.getStackTraceString() +'Exception field name:'+archivalObjectFieldInfo.name+' Field Value:'+actualObjectFieldInfo.name);
                                        }
                                    }
                                }
                            }  
                        }
                        else{
                            if(!actualObjectFieldInfo.isCustom){
                                if(actualObjectFieldInfo.name.containsIgnoreCase('__c')){
                                    actualObjectFieldInfo.name = actualObjectFieldInfo.name.removeEnd('__c');
                                }
                            }
                            if(actualRecord.get(actualObjectFieldInfo.name) != Null){
                                if(archivalObjectFieldInfo.isUpdateable){
                                    try{
                                        archivalObject.put(archivalObjectFieldInfo.name, actualRecord.get(actualObjectFieldInfo.name));
                                    }catch (exception e){
                                        System.debug('Error: '+ e.getMessage() + ' Stack trace:'+ e.getStackTraceString() +'Exception field name:'+archivalObjectFieldInfo.name+' Field Value:'+actualObjectFieldInfo.name);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            archivalObjectList.add(archivalObject);
        }        
        
        list<database.saveresult> dsr = Database.insert(archivalObjectList, false);
        for(database.saveresult sr: dsr){
            System.debug('insert success?:'+sr.isSuccess()+ ' id:'+sr.getId());
        }
    }
    
    public class fieldDetails{
        String type;
        String relationshipName;
        Boolean isAccessible;
        Boolean isUpdateable;
        Boolean isCustom;
        String name;
        SObject objectName;
    }
    public Map<String, fieldDetails> getFieldsDataMap(String objectNameStr){
        Map<String, fieldDetails> fieldDetailsMap = new Map<String, fieldDetails>();
        SObject objectName = Schema.getGlobalDescribe().get(objectNameStr).newSObject() ;
        Map<String, Schema.SObjectField> fieldsMap = objectName.getSobjectType().getDescribe().fields.getMap();
        
        for(String field:fieldsMap.keyset()){
            fieldDetails details = new fieldDetails();
            Schema.DescribeFieldResult fieldDFR = fieldsMap.get(field).getDescribe();
            if(fieldDFR.getType().Name() == 'REFERENCE' && fieldDFR.getSoapType().Name() == 'Id' && String.isNotBlank(fieldDFR.getRelationshipName())){
                details.relationshipName = fieldDFR.getRelationshipName();
                details.type = 'Relationship';                    
            }
            else{
                details.relationshipName = null;
                details.type = null;
            }
            details.isAccessible = fieldDFR.isAccessible();
            details.isUpdateable = fieldDFR.isUpdateable();
            details.isCustom = fieldDFR.isCustom();
            String fieldName = fieldDFR.getName();
            details.name = fieldName;
            details.objectName = objectName;
            fieldDetailsMap.put(fieldName, details);
        }
        return fieldDetailsMap;
    }
    
}