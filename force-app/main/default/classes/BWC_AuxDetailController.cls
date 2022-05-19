/* ================================================
* @author : Kevin Collins
* @date :   06/28/2021   
* @group : Redaction
* @description : Controller class for Aux Detail OBJECT
================================================*/

public with sharing class BWC_AuxDetailController  
{
	//get Aux Details related to Case
    @AuraEnabled(cacheable=true)
    public static List<AuxDetail__c> getAuxDetails(String recordId)
	{
		System.debug('### RECORD ID: ' + recordId);
		try
		{
			AuxDetailService service = new AuxDetailService(recordId);
			return service.getAuxDetails();
		}
		catch(Exception ex)
		{
			throw new AuraHandledException(ex.getMessage());
		}
	}

	//Insert Aux Details List
    @AuraEnabled
    public static List<String> saveAuxDetailsObj(String targetObjId, List<List<AuxDetail__c>> items)
	{
		try
		{
			AuxDetailService service = new AuxDetailService(targetObjId);
			return service.insertAuxDetails(items);
		}
		catch(Exception ex)
		{
			throw new AuraHandledException(ex.getMessage());
		}
	}

	//Delete Aux Details by Lookup Ids
    @AuraEnabled
    public static List<String> removeAuxDetails(List<String> lookupObjIds)
	{
		try
		{
			AuxDetailService service = new AuxDetailService(lookupObjIds[0]);
			return service.deleteAuxDetailsByLookupIds(lookupObjIds);
		}
		catch(Exception ex)
		{
			throw new AuraHandledException(ex.getMessage());
		}
	}
}