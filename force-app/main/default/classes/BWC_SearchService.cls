public with sharing class BWC_SearchService {
//Method to lookup records for a given object
public static List<sObject> searchRecords(String objectName, List<String> fields, String searchTerm){
    
    String searchKeyword = searchTerm + '*';
    String returningQuery = ''; 
    String folderName = CaseConstants.EMAIL_TEMPLATE_FOLDER_NAME;
    if(objectName == 'EmailTemplate' ){    
        //Find {Case} IN ALL FIELDS RETURNING EmailTemplate(Id,Name where Folder.Name = 'Escalation Case Auto Communications') 
        returningQuery = objectName + (' (Id,' + String.join(fields, ',') + ' WHERE Folder.Name=\'' + folderName + '\')');
    }else{
        returningQuery = objectName+' ( Id, '+String.join(fields,',')+')';
    }
    String query = 'FIND :searchKeyword IN ALL FIELDS RETURNING '+returningQuery+' LIMIT 20';
    List<List<sObject>> searchRecords = Search.Query(Query);
    return searchRecords.get(0);
}
}