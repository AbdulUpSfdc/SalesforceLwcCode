/*
 * Test Class: ContentDocumentLinkTriggerHelperTest
*/
public with sharing class ContentDocumentLinkTriggerHelper {
    static Map<ID,String> cdlToTypeMap{
        get{
            if(cdlToTypeMap==null){
                getCdlToTypeMap();
                return cdlToTypeMap;
            }
            return cdlToTypeMap;
        }
        set;
    }
    
    public static void filterBeforeDelete(){
        List<ContentDocumentLink> contentDocumentLink = new List<ContentDocumentLink>();
        for(ContentDocumentLink cdl : (List<ContentDocumentLink>)trigger.old){
            if(cdlToTypeMap.containsKey(cdl.ContentDocumentId) 
               && cdlToTypeMap.get(cdl.ContentDocumentId).equalsIgnoreCase('SNOTE')  
               && String.valueOf(cdl.LinkedEntityId).startsWithIgnoreCase('500')){
                   restrictContentNoteDeletion(cdl);      
               }                            
        }        
    }
    
    private static Map<Id,String> getCdlToTypeMap(){
        cdlToTypeMap = new  Map<ID, String>();
        Set<ID> cdIds_Set = new Set<ID>();
        for(ContentDocumentLink cdl : (List<ContentDocumentLink>)trigger.old){ 
            cdIds_Set.add(cdl.ContentDocumentId);    
        }
        for(ContentDocument cd : [Select FileType From ContentDocument Where ID IN :cdIds_Set]){
            cdlToTypeMap.put(cd.ID,cd.FileType);    
        }
        return cdlToTypeMap;
    }
    private static void restrictContentNoteDeletion(ContentDocumentLink cdl){
        cdl.addError(Label.NotesCaseDeletion); 
    }
}