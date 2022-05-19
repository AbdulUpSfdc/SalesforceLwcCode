public with sharing class BWC_DependentPicklist {
    public static Map<String,List<BWC_Bitset.TPicklistEntry>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
        Map<String,List<BWC_Bitset.TPicklistEntry>> objResults = new Map<String,List<BWC_Bitset.TPicklistEntry>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!objGlobalMap.containsKey(pObjName))
            return objResults;
        //get the type being dealt with
        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
            return objResults;
        //get the control values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        //iterate through the values and get the ones valid for the controlling field name
        BWC_Bitset objBitSet = new BWC_Bitset();
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<BWC_Bitset.TPicklistEntry>());
        }
        //cater for null and empty
         objResults.put('',new List<BWC_Bitset.TPicklistEntry>());
         objResults.put(null,new List<BWC_Bitset.TPicklistEntry>());
        //check the dependent values
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){
            //get the pointer to the dependent index
           	Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
           	//get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);
            BWC_Bitset.TPicklistEntry objDepPLE = (BWC_Bitset.TPicklistEntry)JSON.deserialize(pEntryStructure, BWC_Bitset.TPicklistEntry.class);
            //if valid for is empty, skip
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            //iterate through the controlling values
            for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
            	if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)){
		            //get the label
		            String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                    objResults.get(pControllingLabel).add(objDepPLE);
                }
            }
        }
        return objResults;
    }
}