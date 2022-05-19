/*
 * Test Class: ContentDocumentLinkTriggerHelperTest
*/
public class ContentDocumentTriggerHelper {
    public static void filterBeforeDelete(){
        List<ContentDocument> contentNoteList = new List<ContentDocument>();
        for(ContentDocument cd : (List<ContentDocument>)trigger.old){
            if(cd.FileType=='SNOTE'){
                restrictContentNoteDeletion(cd);
            }	    
        }	     
    }
    
    private static void restrictContentNoteDeletion(ContentDocument cd){
        cd.addError(Label.NotesCaseDeletion); 
    }
}