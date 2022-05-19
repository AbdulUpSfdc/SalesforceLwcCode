@isTest
public class KMErrorHandlingUtilityTest {

    
    
     public static testMethod void testLogError() {
		 String exceptionString = 'This is the exception'; 
         String topicName = 'KMTopic';
         KMErrorHandlingUtility.logError(exceptionString, topicName);
         List<Object> params = new List<Object>{topicName, exceptionString};
         KMErrorHandlingUtility.logError(exceptionString, topicName, params);    
             
         
     } 
    
    
   
    
}