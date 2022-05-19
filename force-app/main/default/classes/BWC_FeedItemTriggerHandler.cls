/*user story: 1675
* test class: BWC_FeedItemTriggerHandler_Test
Created Initial version - 03/22/2021
*/
public class BWC_FeedItemTriggerHandler {
    public static void delegateProcessing(){
        
        if(trigger.isBefore){
            try{
                
                BWC_FeedItemTriggerHelperClass.maskFeedPost();
            }
            catch(Exception e) {
                BWC_ExceptionUtils.handleException(e, true);
            }
        }

        if(trigger.isAfter) {
            if(trigger.isInsert || trigger.isUpdate){
                BWC_FeedItemTriggerHelperClass.updateLastActivityonCase();    
            }
        }
    }
}