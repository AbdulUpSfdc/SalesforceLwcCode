/* ================================================
* @author : Kevin Collins
* @date :   08/19/2021
* @group : Billing Account
* @description : Controller class for Communication History External OBJECT
================================================*/

public class BWC_CommunicationHistoryController
{

    @AuraEnabled
    public static String requestResend(String objId, String category)
	{
		System.debug('### RECORD ID: ' + objId);

		try
		{

			BWC_CommunicationHistory.ResendResponse response = BWC_CommunicationHistoryService.requestResend(objId, category);

			return JSON.serialize(response, true);
		}
		catch(Exception ex)
		{
			throw new AuraHandledException(ex.getMessage());
		}
	}

}