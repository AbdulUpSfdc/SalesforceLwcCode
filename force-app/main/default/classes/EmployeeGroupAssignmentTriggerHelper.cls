public without sharing class EmployeeGroupAssignmentTriggerHelper {
    //A GroupId will be assigned based on the Public Group/Queue Name provided by user
    //and, a record will be created/updated in Employee_Group_Assignment__c 
    public static void updateGroupIdHelper(List<Employee_Group_Assignment__c> empGroupAssign){
        try{
            Set<String> queueNames = new Set<String>();
            Set<String> publicGrpNames = new Set<String>();

            List<Employee_Group_Assignment__c> listQueueEmpGrpAssign = new List<Employee_Group_Assignment__c>();
            List<Employee_Group_Assignment__c> listPGEmpGrpAssign = new List<Employee_Group_Assignment__c>();

            Map<String, Id> mapQueues = new Map<String, Id>();
            Map<String, Id> mapPublicGroups = new Map<String, Id>();

            for(Employee_Group_Assignment__c empGrpAssign: empGroupAssign){
                if(empGrpAssign.Group_Type__c == 'Queue'){
                    queueNames.add(empGrpAssign.Public_Group_Queue_Name__c);
                    listQueueEmpGrpAssign.add(empGrpAssign);
                }
                else if(empGrpAssign.Group_Type__c == 'Public Group'){
                    publicGrpNames.add(empGrpAssign.Public_Group_Queue_Name__c);
                    listPGEmpGrpAssign.add(empGrpAssign);
                }
            }

            //updating Group Id for the type: Queue
            if(listQueueEmpGrpAssign?.size() > 0){
                for(Group grpQ: [SELECT Id, Name FROM Group WHERE Name IN :queueNames AND Type = 'Queue' WITH SECURITY_ENFORCED]){
                    mapQueues.put(grpQ.Name, grpQ.Id);
                }
                for(Employee_Group_Assignment__c empGAssignQ: listQueueEmpGrpAssign){
                    if(mapQueues?.size() > 0)
                        empGAssignQ.Group_ID__c = mapQueues.get(empGAssignQ.Public_Group_Queue_Name__c);
                    else
                        empGAssignQ.addError(Label.Update_GroupId_Error);
                }
            }

            //updating Group Id for the type: Public Group
            if(listPGEmpGrpAssign?.size() > 0){
                for(Group grpPG: [SELECT Id, Name FROM Group WHERE Name IN :publicGrpNames AND Type = 'Regular' WITH SECURITY_ENFORCED]){
                    mapPublicGroups.put(grpPG.Name, grpPG.Id);
                }
                for(Employee_Group_Assignment__c empGAssignPG: listPGEmpGrpAssign){
                    if(mapPublicGroups?.size() > 0)
                        empGAssignPG.Group_ID__c = mapPublicGroups.get(empGAssignPG.Public_Group_Queue_Name__c);
                    else
                        empGAssignPG.addError(Label.Update_GroupId_Error);
                }
            }
        }catch(Exception e){
            System.debug(e);
            Logger.error('An exception occured while updating the Group Id' + e.getMessage());
            for(Employee_Group_Assignment__c errorEmpGrpAssign: empGroupAssign)
                errorEmpGrpAssign.addError(Label.Update_GroupId_Error);
        }
    }
}