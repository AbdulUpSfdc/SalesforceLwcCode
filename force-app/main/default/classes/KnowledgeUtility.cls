public with sharing class KnowledgeUtility {

    public static String formatExceptionMessage(Exception exceptionCaught) {
        String causeString = exceptionCaught.getTypeName() + ' ';
        causeString += exceptionCaught.getMessage() + ' ';
        causeString += exceptionCaught.getStackTraceString() + ' ';
        causeString += exceptionCaught.getLineNumber() + ' ';
        return causeString;
          
    }
    
     public static void addToMapOfLists(Map<String, List<SObject>> listMap, String key, SObject sobj) {
        List<SObject> sobjList = listMap.get(key);
        if(sobjList == null){
            sobjList = new List<SObject>();
        }
        sobjList.add(sobj);
        listMap.put(key, sobjList);
    }
    
    public static void addToMapOfLists(Map<Id, List<SObject>> listMap, Id key, SObject sobj) {
        List<SObject> sobjList = listMap.get(key);
        if(sobjList == null){
            sobjList = new List<SObject>();
        }
        sobjList.add(sobj);
        listMap.put(key, sobjList);
    }
     
    
}