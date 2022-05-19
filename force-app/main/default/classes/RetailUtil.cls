/* 
 * This is a util class used by Retail team for generic utility methods
 * @Author - Reshma Jewrani
*/
public with sharing class RetailUtil {
    /*
     * This method returns all the values for the RetailCustomSetting
    */
    public static Map<String, RetailCustomSetting__c> getRetailCustomSettings(){
        Map<String, RetailCustomSetting__c> retailSettingsMap = RetailCustomSetting__c.getAll();
        return retailSettingsMap;
    }
    
    /*
     * This method returns all the specifc value for the RetailCustomSetting
    */
    public static String getRetailCustomSettings(String key){
        RetailCustomSetting__c retailSetting = RetailCustomSetting__c.getValues(key);
        if(retailSetting != null)
            return retailSetting.KeyValue__c;
        return null;
    }

    /** */
    public static String getEmployeeNotification() {
        List<CustomNotificationType> notifList = [SELECT Id FROM CustomNotificationType WHERE DeveloperName =: RetailConstants.EMP_NOTIF LIMIT 1];
        if(notifList.size()  > 0)  {
            return notifList.get(0).id;
        }
        return null;
    }

    /**This method converts the degree value to radians */
    public static Double radianToDegree(Double degrees) {
        return (degrees * (180 / Math.PI));
    }
    
    /**This method converts the radians value to degree */
    public static Double degreeToRadian(Double radians) {
        return (radians * (Math.PI / 180));
    }
}