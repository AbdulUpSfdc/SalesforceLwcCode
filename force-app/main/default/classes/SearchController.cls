/***********************************************************************************************************************************************
 *  @Author     :Aditya Gandi
 *  @File Name  : SearchController
 *  @Version    : V0.0
 *  @Description: This Class Find Email Template and bind to Communication Template Record 
 *  @TestClass  : SearchControllerTest
 *  @History
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 *
 ***********************************************************************************************************************************************/

 public with sharing class SearchController {
    //This controller will search records for a given Object 
   
    @AuraEnabled
    public static List<sObject> search(String objectName, List<String> fields, String searchTerm){
        return BWC_SearchService.searchRecords(objectName,fields,searchTerm);
    }
    
}