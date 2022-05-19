public without sharing class KM_Utility {
    public KM_Utility() {

    }

    public static KM_Settings__mdt getFeatureSettings(String featureName) {
        KM_Settings__mdt featureSettings = new KM_Settings__mdt();
        try{
            featureSettings = [ SELECT Batch_Size__c, Batch_Frequency__c, Cron_Expression__c, Feature_Switch__c
		                        FROM KM_Settings__mdt
		                        WHERE DeveloperName =: featureName];                              
        }
        catch(Exception e){
            String errorMessage = 'Custom metadata for the feature - "' + featureName + '" does not exist. Error message - '  +e;
			makeLog(featureName, JSON.serialize(errorMessage));
        }
        return featureSettings;
    }

    public static void makeLog(String topicName, String exceptionJson) {
        List<Object> params = new List<Object>{topicName,  null, 'Message: ' + exceptionJson};  
        LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
        Logger.error(logMessage).setTopics(new List<String>{topicName});
        Logger.saveLog();
    }
}