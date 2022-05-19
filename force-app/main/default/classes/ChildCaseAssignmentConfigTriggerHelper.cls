//PBCNTRSENT-520
public class ChildCaseAssignmentConfigTriggerHelper {
    Static Set<ID> userId_Set = new Set<ID>();
    public static void filterOnBeforeInsert(){
        ChildCaseAssignmentConfig__c childConfig = ((List<ChildCaseAssignmentConfig__c>)trigger.new)[0];
        validateUserAssignment(childConfig);                
    }//filterOnBeforeInsert ends...

    public static void filterOnUpdate(){
        ChildCaseAssignmentConfig__c childConfig = ((List<ChildCaseAssignmentConfig__c>)trigger.new)[0];
        validateUserAssignment(childConfig);
    }
    
    // method to validate if user belong to the queue mapped on child case config object record.
    private static void validateUserAssignment(ChildCaseAssignmentConfig__c childConfig){
        if(String.isNotBlank(childConfig.Queue__c) && childConfig.User__c!=null){
            userId_Set = MetadataSelector.fetchUsers(childConfig.Queue__c);
            if(!userId_Set.contains(childConfig.User__c)){
                childConfig.addError('This user is not assigned to this group : '+childConfig.Queue__c);    
            }    
        }
    }//validateUserAssignment ends..
    
    
}