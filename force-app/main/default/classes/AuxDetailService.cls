/* ================================================
* @author : Kevin Collins
* @date :   06/28/2021   
* @description : Service class for Aux Detail OBJECT
================================================*/
public inherited sharing class AuxDetailService  
{
	private ID targetObj;
	private String targetObjTypeName;

	public AuxDetailService(ID targetObj ) {
		this.targetObj = targetObj;
		this.targetObjTypeName = this.targetObj.getSobjectType().getDescribe().getName();
	}

	private class ObjSoqlTraits 
	{
		public String lookupField;
		public String sortByCriteria;

		public ObjSoqlTraits( String lookupField, String sortByCriteria ) 
		{
			this.lookupField = lookupField;
			this.sortByCriteria = sortByCriteria;
		}
	}

	private static final Map<String,ObjSoqlTraits> soqlHelperMap = new Map<String, ObjSoqlTraits>{
		'Case' => new ObjSoqlTraits( 'Case__c', 'OrderHint__c' ),
		'Account' => new ObjSoqlTraits( 'Account__c', 'OrderHint__c' )
	};

	//get Aux Details related to Case
    public List<AuxDetail__c> getAuxDetails()
	{
		ID myBindingVar = targetObj;   // targetObj = '300affgewrfecasfwef'

		String query = buildSoql( 'myBindingVar' );
		//query = 'select id, name from AuxDetail__c where Case__c = :myBindingVar';
		System.debug('### QUERY: ' + query);  
		List <AuxDetail__c> auxList = Database.query(query);
		System.debug('### soqlHelperMap: ' + soqlHelperMap);
		return auxList;
	}

	private  String buildSoql( String bindingVar ) {
		ID tobj = targetObj;
		Schema.DescribeSObjectResult dsobjr = AuxDetail__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = dsobjr.fields.getMap();
		String soql = 'SELECT ' + String.join( new List<String>(fieldMap.keySet()), ',' )
		+ ' FROM AuxDetail__c WHERE ' 
		+ soqlHelperMap.get( targetObjTypeName ).lookupField
		+ ' = :' + bindingVar; // 'select id, name from AuxDetail__c where Case__c = :myBindingVar';
		final String sortFld = soqlHelperMap.get( targetObjTypeName ).sortByCriteria;
		if(String.isNotEmpty( sortFld ))
		{
			soql += ' ORDER BY ' + sortFld;
		}
		return soql;	
	}

	public List<String> insertAuxDetails(List<List<AuxDetail__c>> listOfItems)
	{
		System.debug('### insertAuxDetails ITEMS: ' + listOfItems);
		List<AuxDetail__c> items = generateRecords(targetObj, listOfItems);
		List<String> strIds = new List<String>();
		Database.SaveResult[] srList = Database.insert(items);
		if(srList.isEmpty())
		{
			return null;
		}
		else
		{
			for (Database.SaveResult sr : srList)
			{
				strIds.add(sr.getId());
			}
		}
		return strIds;
	}

	private static List<AuxDetail__c> generateRecords(String targetObjId, List<List<AuxDetail__c>> items)
	{
		List<AuxDetail__c> allRecords = new List<AuxDetail__c>();
		for(Integer i = 1; i <= items.size(); i++)
		{
			List<AuxDetail__c> itemsList = items[i - 1];
			for(Integer j = 1; j <= itemsList.size(); j++)
			{
				itemsList[j - 1].OrderHint__c = createOrderHint(i,j);
				allRecords.add(itemsList[j - 1]);
			}
		}
		return allRecords;
	}

	private static string createOrderHint(Integer val1, Integer val2)
	{
		String orderHint = addLeftPadZero(val1, 5) +'_'+ addLeftPadZero(val2, 5);
		return orderHint;
	}

	private static string addLeftPadZero(Integer val, Integer valLen)
	{
		return String.valueOf(val).leftPad(valLen - String.valueOf(val).length(), '0');
	}

	public List<String> deleteAuxDetailsByLookupIds(List<String> lookupObjIds)
	{
		List<String> strIds = new List<String>();
		System.debug('### OBJECT API NAME: ' + soqlHelperMap.get( targetObjTypeName ).lookupField);
		List<AuxDetail__c> items = Database.query('SELECT Id FROM AuxDetail__c WHERE ' + 
		soqlHelperMap.get( targetObjTypeName ).lookupField + 
		' IN :lookupObjIds');
		System.debug('### RECORDS TO DELETE: ' + items);
		//[SELECT Id FROM AuxDetail__c WHERE Case__c IN :lookupObjIds];
		if(!items.isEmpty())
		{
			Database.DeleteResult[] drList = Database.delete(items, false);
			if(drList.isEmpty())
			{
				return null;
			}
			else
			{
				for (Database.DeleteResult dr : drList)
				{
					strIds.add(dr.getId());
				}
			}
		}
		return strIds;
	}
}