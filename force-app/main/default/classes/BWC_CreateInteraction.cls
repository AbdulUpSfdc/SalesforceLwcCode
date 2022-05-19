public without sharing class BWC_CreateInteraction {

    public static final String OFFLINE_INTERACTION_RT_LABEL = 'Offline';
    public static String OFFLINE_INTERACTION_RT='';

    public static List<Case> filterCasesWOInteraction(List<Case> cases){
        List<Case> casesWithoutInteraction = new List<Case>();
        for(Case cs : cases){

            if(String.isBlank(cs.First_Interaction__c)){
                casesWithoutInteraction.add(cs);
            }
        }

        return casesWithoutInteraction;
    }

    public static void createInteractionFromCases(List<Case> cases){

        populateInteractionRT();

        Map<String, String> caseIdCtiIdentMap = new Map<String, String>();
        Map<String, Interaction__c> ctiIdentInteractionMap = new Map<String, Interaction__c>();
        List<Case_Interaction__c> caseInteractions = new List<Case_Interaction__c>();

        try{

            // Create interaction record
            for(Case cs : cases){
                Interaction__c interaction = getInteractionFromCase(cs);

                caseIdCtiIdentMap.put(cs.Id, interaction.CTI_Call_Identifier__c);
                ctiIdentInteractionMap.put(interaction.CTI_Call_Identifier__c, interaction);
            }

            insert ctiIdentInteractionMap.values();

            // Assign interactionId as firstInteraction on Case
            for(Case cs : cases){

                String ctiIdent = caseIdCtiIdentMap.get(cs.Id);
                Id interactionId = ctiIdentInteractionMap.get(ctiIdent).Id;
                cs.First_Interaction__c = interactionId;
                cs.Last_Interaction__c = interactionId;

                Case_Interaction__c caseInteraction = new Case_Interaction__c();
                caseInteraction.Interaction__c = interactionId;
                caseInteraction.Case__c = cs.Id;

                caseInteractions.add(caseInteraction);
            }

            insert caseInteractions;

            updateInteractionAuthStatus(ctiIdentInteractionMap.values());
        }catch(Exception e){
            System.debug('Exception ' + e.getStackTraceString());
            BWC_ExceptionUtils.handleException(e, 'BWC_CreateInteraction.createInteractionFromCases', null);
        }
    }

    public static Interaction__c getInteractionFromCase(Case cs){
        Interaction__c interaction = new Interaction__c();

        interaction.CTI_Call_Identifier__c = BWC_Utils.getAutoCTIIdent();
        interaction.Billing_Account__c = cs.Billing_Account__c;
        interaction.Customer__c = cs.AccountId;
        interaction.Wireless_Authorization_Level__c = BWC_Constants.AUTHORIZATION_LEVEL_BYPASS;
        interaction.Is_Authorized__c = true;
        interaction.RecordTypeId = OFFLINE_INTERACTION_RT;
        interaction.User_Account_Number__c = cs.AccountIdentifier__c;
        interaction.CompletedDate__c = System.now();

        return interaction;
    }

    public static List<Case> filterUpdatedAccCases(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap){
        List<Case> updatedCases = new List<Case>();

        for(Case cs : newCaseMap.values()){
            Case oldCase = oldCaseMap.get(cs.Id);

            if(cs.AccountId == null || cs.Billing_Account__c == null ){
                continue;
            }

            if(cs.AccountId != oldCase.AccountId || cs.Billing_Account__c != oldCase.Billing_Account__c){
                updatedCases.add(cs);
            }
        }

        return updatedCases;
    }

    public static void updateInteractionsFromCases(List<Case> cases){

        System.debug('Updating interaction');

        List<Interaction__c> interactions = new List<Interaction__c>();
        for(Case cs : cases){
            Interaction__c interaction = new Interaction__c();
            //TODO: is it first or last?
            interaction.Id = cs.Last_Interaction__c;
            interaction.Billing_Account__c = cs.Billing_Account__c;
            interaction.Customer__c = cs.AccountId;
            interaction.User_Account_Number__c = cs.AccountIdentifier__c;

            interactions.add(interaction);
        }

        try{
            if(!interactions.isEmpty()){
                update interactions;

                updateInteractionAuthStatus(interactions);
            }
        }catch(Exception e){
            System.debug('Exception ' + e.getStackTraceString());
            BWC_ExceptionUtils.handleException(e, 'BWC_CreateInteraction.updateInteractionsFromCases', null);
        }
    }

    public static void updateInteractionAuthStatus(List<Interaction__c> interactions){

        for(Interaction__c interaction : interactions){
            BWC_AuthorizationCallout.AuthorizationStatusResponse authStatusResponse = BWC_AuthorizationService.getFullAuthorizationStatus(interaction.Id);
            String contentStr = JSON.serialize(authStatusResponse.content);
            interaction.Authorization_Json__c = contentStr;
        }

        update interactions;

    }

    public static void populateInteractionRT(){
        OFFLINE_INTERACTION_RT = Schema.SObjectType.Interaction__c.getRecordTypeInfosByDeveloperName().get(OFFLINE_INTERACTION_RT_LABEL).getRecordTypeId();
    }

}