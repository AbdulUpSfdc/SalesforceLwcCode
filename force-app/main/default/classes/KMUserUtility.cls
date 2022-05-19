public with sharing class KMUserUtility {

// Colin Higgin’s (CH3990)
//  Robert Andrews (ra5719) 
//  
//KMUserUtility.cloneUser('CH3990', 'ra5719', false);

    public static void cloneUser(String sourceAttUID, String targetAttUID, Boolean createNewTargetUser) {
       User sourceUser = getUserByAttuid(sourceAttUID, false);
        if (createNewTargetUser == true) {
            throw new KMUserUtilityException('Creating a new target user not yet implemented');
        }
       User targetUser = getUserByAttuid(targetAttUID, true);
       List<PermissionSetAssignment> newPermissionSets = copyPermissionSetAssignments(sourceUser, targetUser);  
       List<BWUserMarketAssociation__c> newMarkets = copyMarketAssignments(sourceUser,targetUser);
    }
    
    public static List<PermissionSetAssignment> copyPermissionSetAssignments(User sourceUser, User targetUser) {
               List<PermissionSetAssignment> assignedPermissionSets = getAssignedPermissionSets(sourceUser.Id);
        System.debug(assignedPermissionSets.size() + ' permission sets assigned to ' +sourceUser.Name);

        if (assignedPermissionSets.isEmpty()) {
            return assignedPermissionSets;
        }
        List<PermissionSetAssignment> newPermissionSets = cloneAssignedPermissionSets(targetUser.Id, assignedPermissionSets);
                              insert newPermissionSets;
        return newPermissionSets;
    }
    
    
     public static List<BWUserMarketAssociation__c> copyMarketAssignments(User sourceUser, User targetUser) {
                List<BWUserMarketAssociation__c> assignedMarketList = getAssignedMarketList(sourceUser.Id);
         
        System.debug(assignedMarketList.size() + ' markets assigned to ' +sourceUser.Name);

        if (assignedMarketList.isEmpty()) {
            return assignedMarketList;
        }
        List<BWUserMarketAssociation__c> newMarketAssignmentList = cloneAssignedMarkets(targetUser.Id, assignedMarketList);
                              insert newMarketAssignmentList;
        return newMarketAssignmentList;
    }
    
    
    public static User getUserByAttuid(String attuid, Boolean requireActiveUser) {
        List<User> userList;
        if (requireActiveUser == true) {
               userList = [SELECT Id, Name, email, ProfileId, ATTUID__c from User WHERE ATTUID__c = :attuid AND isActive = true];
        } else {
               userList = [SELECT Id, Name, email, ProfileId, ATTUID__c from User WHERE ATTUID__c = :attuid];

        }
        
        if (userList.isEmpty()) {
            return null;
        } else {
            return userList[0];
        }  
    }
    
    public static List<PermissionSetAssignment> getAssignedPermissionSets(Id userId) {
               //get non-system permission sets for the specified user
        return [SELECT Id, PermissionSetId from PermissionSetAssignment WHERE AssigneeId = :userId AND 
                PermissionSetId IN (SELECT Id 
                                     FROM PermissionSet
                                     WHERE IsOwnedByProfile =false)];   
    }
    
     public static List<BWUserMarketAssociation__c> getAssignedMarketList(Id userId) {
               return [SELECT Id, Primary__c, BWMarketMaster__c, UserId__c from BWUserMarketAssociation__c WHERE  UserId__c = :userId];   
    }
    
    public static List<PermissionSetAssignment> cloneAssignedPermissionSets(Id userId, List<PermissionSetAssignment> permissionsToBeAssigned) {
               List<PermissionSetAssignment> newPermissionSetList = new List<PermissionSetAssignment>();
        PermissionSetAssignment newPSA;
        for (PermissionSetAssignment psa : permissionsToBeAssigned) {
                              newPSA = new PermissionSetAssignment();
            newPSA.AssigneeId = userId;
            newPSA.PermissionSetId = psa.PermissionSetId;
            newPermissionSetList.add(newPSA);
        }
        System.debug(newPermissionSetList.size() + ' new permission set assignments created');
        return newPermissionSetList;
    }
    
    
    public static List<BWUserMarketAssociation__c> cloneAssignedMarkets(Id userId, List<BWUserMarketAssociation__c> assignedMarketList) {
               List<BWUserMarketAssociation__c> newMarketAssignmentList = new List<BWUserMarketAssociation__c>();
        BWUserMarketAssociation__c newAssignedMarket;
        for (BWUserMarketAssociation__c assignedMarket : assignedMarketList) {
                              newAssignedMarket = new BWUserMarketAssociation__c();
            newAssignedMarket.Primary__c = assignedMarket.Primary__c;
            newAssignedMarket.BWMarketMaster__c = assignedMarket.BWMarketMaster__c;
            newAssignedMarket.UserId__c = userId;
            newMarketAssignmentList.add(newAssignedMarket);
        }
        System.debug(newMarketAssignmentList.size() + ' new market assignments created');
        return newMarketAssignmentList;
        
    }
    
    public static Employee__c getEmployeeRecordByUserId(Id userId) {
        List<Employee__c> employeeList = [SELECT Channel__c,BWDefaultKMChannel__c, Email__c,EmployeeId__c,FirstName__c,HireDate__c,HomeStoreLocation__c,Id,IsActive__c,IsDeleted,LastName__c,Name,NumberOfAssociatedStores__c,OfficePhone__c,OwnerId,PositionStartDate__c,RecordTypeId,SFProfileId__c,TerminationDate__c,User__c,WirelessPhone__c
                        FROM Employee__c where User__c = :userId];
        if (employeeList.size() == 0) {
            return null;
        } else {
            return employeeList[0];
        }  
    }

    public static String  getUserPrimaryChannel()
    {
      return getUserPrimaryChannel(UserInfo.getUserId());
       
    }
    
    public static String  getUserPrimaryChannel(Id userId){
        Employee__c emp = getEmployeeRecordByUserId(userId);
        System.debug('emp :::' + emp);
        
        String primaryPermLabel;
        String channelId;
        List<BW_Channel_Mapping__c> channelMapping = new List<BW_Channel_Mapping__c>();
        List<PermissionSet> permSets = new List <PermissionSet>();
        String primaryChannelEmployee = emp!=null?emp.BWDefaultKMChannel__c: null;
        if(!String.isBlank(primaryChannelEmployee))
        {
                channelMapping = [SELECT Permission_Set_Id__c FROM BW_Channel_Mapping__c where KM_Channel_ID__c =:primaryChannelEmployee LIMIT 1];
                if(!channelMapping.isEmpty())
                {
                    channelId = channelMapping[0].Permission_Set_Id__c;
                    permSets = [SELECT Label FROM PermissionSet where Id =:channelId];
                    if(!permSets.isEmpty())
                    {
                        primaryPermLabel = permSets[0].Label;
                    }                   
                }                
       	}
        System.debug('The Primary Label returned is '+primaryPermLabel);
        return primaryPermLabel;
    }
    
    public static Sobject handleEmptyList(List<Sobject> objectRowList) {
               if (objectRowList.isEmpty()) {
            return null;
        } else {
            return objectRowList[0];
        }     
    }
    
    public class KMUserUtilityException extends Exception {}
}