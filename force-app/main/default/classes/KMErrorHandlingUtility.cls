public with sharing class KMErrorHandlingUtility {

     public static void logError(String exceptionString, String topicName) {

         List<Object> params = new List<Object>{topicName, exceptionString};
         LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, params);
         Logger.error(logMessage).setTopics(new List<String>{topicName});
         Logger.saveLog(); 
     } 
    
    
    public static void logError(String exceptionString, String topicName, List<Object> params) {
		 List<Object> exceptionParams = new List<Object>{topicName, exceptionString};
         exceptionParams.addAll(params);
         LogMessage logMessage = new LogMessage(BWC_Constants.OPUS_NEBULA_MESSAGE_TEMPLATE, exceptionParams);
         Logger.error(logMessage).setTopics(new List<String>{topicName});
         Logger.saveLog(); 
     } 
}