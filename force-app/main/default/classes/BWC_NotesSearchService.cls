public with sharing class BWC_NotesSearchService {
    
    //can be called synchronously or async
    public class GetNotesSearchService extends BWC_InteractionServiceBase{
       
        public BWC_NotesSearch.NotesSearchRequest request;
        public BWC_NotesSearch.NotesSearchResponse response;
         /*
            Construct the service object from caller arguments.
        */
        public GetNotesSearchService(Id recordId, BWC_NotesSearch.NotesSearchRequest request) {

            super(recordId,null);

            this.request = request;
            
            this.buildRequest();

            this.callout = new BWC_NotesSearchCallout.GetNotesSearchCallOut(this.request);

        }

        public void buildRequest() {

            list<BWC_NotesSearch.Ban> listBans = new list<BWC_NotesSearch.Ban>();

            for(Billing_Account__c billingAccount : this.billingAccounts) {
                
                String authLevel = this.getAuthorizationLevel(billingAccount.Billing_Account_Number__c);

                if(!BWC_Authorization.AUTHORIZATION_LEVELS_L1_PRIVILEGED.contains( authLevel )) {
                    continue;
                }

                listBans.add(new BWC_NotesSearch.Ban(billingAccount.Billing_Account_Number__c, billingAccount.Account_Type__c));
            }

            if (this.request.noteFilterParams == null) {
                this.request.noteFilterParams = new BWC_NotesSearch.NoteFilterParams();
            }

            this.request.noteFilterParams.callingApp = BWC_Constants.NOTES_CALLING_APP;

            if( this.request.noteFilterParams.bans == null || this.request.noteFilterParams.bans.size() == 0 )
            {
                this.request.noteFilterParams.bans = listBans;
            }
        }

        /*
            Builds and returns final response.
        */
        public override Object buildResponse() {
            this.response =  (BWC_NotesSearch.NotesSearchResponse) this.callout.getResponse();
            return this.response;
        }
    }
}