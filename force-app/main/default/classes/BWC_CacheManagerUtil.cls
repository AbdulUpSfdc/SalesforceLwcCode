/***********************************************************************************************************************************************
*  @Author     :wkhan
*  @File Name  : BWC_CacheManagerUtil
*  @Version    : V0.0
*  @Description: This Class for to store orge cache info.
*  @TestClass  : 
*  @History
* ----------------------------------------------------------------------------------------------------------------------------------------------
*
***********************************************************************************************************************************************/

public with sharing class BWC_CacheManagerUtil {
    
     /*
        Build key name.
    */
    public  static String makeKey(String ctiCallIdentifier, string partionName) {
        // Step non-alphanumeric from key name
        return 'local.' + partionName + '.' + ctiCallIdentifier.replaceAll('[^a-zA-Z0-9]', ''); 
    }
    
     
    
}