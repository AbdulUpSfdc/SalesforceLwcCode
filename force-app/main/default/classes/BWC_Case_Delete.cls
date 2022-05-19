/* ================================================
* @class name: BWC_Case_Delete
* @author: Salesforce Inc.
* @purpose: User needs to delete a case is created by mistake
* @created date (mm/dd/yyyy) :  02/03/2021
================================================*/ 
public without sharing class BWC_Case_Delete {
 
    @AuraEnabled
    public static string deleteCase(string caseId){
       
       //User needs to delete a case is created by mistake
        try{
			List<String> ids = new List<String>();
            List<case> caseListToDelete = [SELECT Id 
                                            FROM Case   
                                            WHERE Id =:caseId];
			/* ***************************************************** */
			for(Case c : caseListToDelete)
			{
				ids.add(c.Id);
			}
			System.debug('### IDS TO DELETE: ' + ids);
			BWC_AuxDetailController.removeAuxDetails(ids);
			/* ***************************************************** */
            delete caseListToDelete;
            }catch(exception e){return e.getMessage();
        }
        return 'Success';
    }
}