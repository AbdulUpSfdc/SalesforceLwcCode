public with sharing class BWC_InteractionCompleteEvent {


    @AuraEnabled
    public static void publishEvent(String recordId, Boolean isTransfer){
        try {

            List<Interaction_Complete__e> icEvents = new List<Interaction_Complete__e>();

            Interaction_Complete__e icEvent = new Interaction_Complete__e(
                InteractionId__c = recordId,
                isTransfer__c = isTransfer
            );

            icEvents.add(icEvent);

            if(!icEvents.isEmpty()){

                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(icEvents);

                // Inspect publishing result for each event
                for (Integer index = 0; index < results.size(); index++) {
                    Database.SaveResult sr = results[index];

                    if (sr.isSuccess()) {
                        System.debug('Successfully published Interaction Complete Platform Event for Interaction Id: ' + icEvents[index].InteractionId__c);
                    } else {
                        String errMesage = '';
                        for(Database.Error err : sr.getErrors()) {
                            errMesage += 'Status code: ' + err.getStatusCode() + ': Error Message: ' + err.getMessage();
                        }
                        System.debug('Error punlishing Interaction Complete Platform Event for Interaction Id: ' + icEvents[index].InteractionId__c + ' -- ' + errMesage);
                    }
                }

            }


        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}