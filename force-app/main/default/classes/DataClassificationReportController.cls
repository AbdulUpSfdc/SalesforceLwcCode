public with sharing class DataClassificationReportController {
    public DataClassificationReportController() {

    }
    @AuraEnabled
    public static string getEntityData(string entityName){
        DataClassificationReportController controller = new DataClassificationReportController();
        List<FieldDefinition> CacheQueryResultFields= [
            SELECT DeveloperName,QualifiedApiName, SecurityClassification, EntityDefinition.QualifiedApiName
            FROM FieldDefinition
            WHERE EntityDefinition.QualifiedApiName =:entityName
            ];
        return JSON.serialize(controller.removeOmittedFields(CacheQueryResultFields));
    }
    @AuraEnabled
    public static string getEntities(){
       //getting metadata info for reportable values
        Data_Classification__mdt  metaSOQLData = [SELECT reportable_entity_json__c  FROM Data_Classification__mdt WHERE MasterLabel = 'default' ];

        list<string> apexList = (list<string>)JSON.deserialize(metaSOQLData?.reportable_entity_json__c, list<string>.class);

        return JSON.serialize(apexList);
    }
    @AuraEnabled
    public static string getEntitiesForInput(){
        // 
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        list<Schema.SObjectType> targetList = new list<Schema.SObjectType>();
        //
        list<String> returnList = new list<String>();
        //
        for(Schema.SObjectType d : gd.values())
        {
            Schema.DescribeSObjectResult ds = d.getDescribe();
            //sorting out entities
            if(ds.isCustom() ||
            !ds.getName().contains('.')&& 
            !ds.getName().contains('__ChangeEvent')&&
            !ds.getName().contains('__mtd')&&
            !ds.getName().contains('__Share')&&
            !ds.getName().contains('__History')){
                returnList.add(ds.getName());
            }
        }
        return JSON.serialize(returnList);
    }
    @AuraEnabled
    public static string getMetaDataForValues(){

       // String metaRecord = Data_Classification__mdt.getInstance('default')?.reportable_entity_json__c;
        Data_Classification__mdt  metaSOQLData = [SELECT reportable_entity_json__c  FROM Data_Classification__mdt WHERE MasterLabel = 'default' ];

        return Json.serialize(metaSOQLData?.reportable_entity_json__c);
    }
    @AuraEnabled
    public static string saveMetaValues(string valueList, String fieldName){
        string fullname='Data_Classification.default';
        string label = 'default';
        Map<string,string> myMap = new Map<string,string>();
        myMap.put(fieldName,valueList);
        metadataDML.createUpdateMetadata(fullName, label, myMap);
        return Json.serialize(null);

    }
    @AuraEnabled
    public static string getMetaDataForOmittedValues(){
        Data_Classification__mdt  metaSOQLData = [SELECT Omitted_Fields__c  FROM Data_Classification__mdt WHERE MasterLabel = 'default' ];
        return Json.serialize(metaSOQLData?.Omitted_Fields__c);
    }
    public list<FieldDefinition> removeOmittedFields(list<FieldDefinition> valueList){
        Data_Classification__mdt  metaSOQLData = [SELECT Omitted_Fields__c  FROM Data_Classification__mdt WHERE MasterLabel = 'default' ];
        list<string> apexList = (list<string>)JSON.deserialize(metaSOQLData?.Omitted_Fields__c, list<string>.class);
        for (Integer i = (valueList.size()-1) ; i>= 0 ; i--){
           // system.debug('in field list: '+ valueList[i].DeveloperName);

            if(apexList.contains(valueList[i].DeveloperName)){
                valueList.remove(i);
            }

        }
        /*
        for (Integer i = (apexList.size()-1) ; i>= 0 ; i--){

            system.debug('in remove list: '+ apexList[i]);

        }
        for (Integer i = (valueList.size()-1) ; i>= 0 ; i--){
            system.debug('in return list: '+ valueList[i].DeveloperName);

        }*/
        return valueList;
    }
}