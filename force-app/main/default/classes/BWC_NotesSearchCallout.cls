/*
    Call Mulesoft to get Notes.
*/
public with sharing class BWC_NotesSearchCallout {
    public static final String NOTES_SEARCH_DETAILS = 'Notes_Search';
    public class  GetNotesSearchCallOut extends BWC_Callout{
        
        //Request and Response state
        List<BWC_NotesSearch.NotesSearchRequest> request;
        BWC_NotesSearch.NotesSearchResponse response;
         /*
            Construct the callout object from request.
        */
        public GetNotesSearchCallOut(BWC_NotesSearch.NotesSearchRequest request) {
            this.setCallout(NOTES_SEARCH_DETAILS, request, null, null, null);
        }
        /*
            Returns BWC_NotesSearch.NotesSearchResponse.
        */
        public override Object buildResponse() {
          
            this.response = (BWC_NotesSearch.NotesSearchResponse)this.deserialize(BWC_NotesSearch.NotesSearchResponse.class);
            return this.response;
        }
    } 
}