/*
* Metadata Selector class to query & generate collections from metadata and custom object used as metadata.
*/
public without sharing class MetadataSelector {
    private static Map<String, CaseAdmin__c> caseAdminToSubmissionSourceCode_Map;
    private static Map<String, CaseAdminState__c> compositeKeyToCaseAdminState_Map;

    public static Map<String,RecordType> caseRecordTypeToDeveloperName_Map{
        get{
            if(caseRecordTypeToDeveloperName_Map!=null && caseRecordTypeToDeveloperName_Map.size()>0){
                return caseRecordTypeToDeveloperName_Map;
            }
            else{
                caseRecordTypeToDeveloperName_Map = new Map<String,RecordType>();
                for(RecordType rt : getRecordTypeList('Case')){
                    caseRecordTypeToDeveloperName_Map.put(rt.DeveloperName,rt);
                }
                return caseRecordTypeToDeveloperName_Map;
            }
        }
        private set;
    }

    public static ID oopBusinessHourId{
        get{
            if(oopBusinessHourId!=null && (oopBusinessHourId.getSobjectType() == Schema.BusinessHours.SObjectType)){
                return oopBusinessHourId;
            }
            else{
                oopBusinessHourId = getBusinessHourId('OOP Business Hour');
                return oopBusinessHourId;
            }

        }
        private set;
    }
    public static Map<String,Group> publicGroupToDeveloperName_Map{
        get{
            if(publicGroupToDeveloperName_Map==null){
                publicGroupToDeveloperName_Map = new Map<String, Group>();
                publicGroupToDeveloperName_Map = getPublicGroups();
            }
            return publicGroupToDeveloperName_Map;
        }
        set;
    }

    public static Map<String,String> stateCodeToName_Map{
        get{
            if(stateCodeToName_Map==null){
                getStateCodeToNameMap();
            }
            return stateCodeToName_Map;
        }
        set;
    }

    public static Set<String> productValueSet{
        get{
            if(productValueSet==null){
                populateProducts();
            }
            return productValueSet;
        }
        set;
    }

    /* Customer Mapping  */
    public static Map<String, String> customerToProduct_Map{
        get{
            if(customerToProduct_Map==null){
                populatedCustomerMapping();
            }
            return customerToProduct_Map;
        }
        set;
    }

    private static void populatedCustomerMapping(){
        customerToProduct_Map = new Map<String, String>();
        for(CGCustomerMapping__c mapping : [Select ProductName__c, CGCustomerType__c From CGCustomerMapping__c]){
            if(String.isNotBlank(mapping.ProductName__c)
                && String.isNotBlank(mapping.CGCustomerType__c)){
                customerToProduct_Map.put(mapping.ProductName__c, mapping.CGCustomerType__c);
            }
        }
    }
    /* Customer Mapping  */
    /* Product Mapping  */
    public static Map<String, String> productToCgProduct_Map{
        get{
            if(productToCgProduct_Map==null) {
                populateCgProductMapping();
            }
            return productToCgProduct_Map;
        }
        set;
    }

    private static void populateCgProductMapping(){
        productToCgProduct_Map = new Map<String, String>();
        for(CGProductMapping__c mapping : [Select CGProductName__c, ProductName__c From CGProductMapping__c]){
            if(String.isNotBlank(mapping.CGProductName__c) && String.isNotBlank(mapping.ProductName__c)){
                productToCgProduct_Map.put(mapping.CGProductName__c, mapping.ProductName__c);
            }
        }
    }

    //customer mapping metadata
    public static Map<String, String> customerToCgCustomerMap{
        get{
            if(customerToCgCustomerMap==null){
                populateCustomerType();
            }
            return customerToCgCustomerMap;
        }
        set;
    }
    private static void populateCustomerType(){
        customerToCgCustomerMap = new Map<String, String>();
        for(CustomerMapping__mdt csType : [Select CGCustomerType__c, OOPCustomerType__c From CustomerMapping__mdt]){
            customerToCgCustomerMap.put(csType.CGCustomerType__c, csType.OOPCustomerType__c);
        }
    }//method ends...

    //customer mapping metadata


    /* Product Mapping  */

    /*
    public static Map<String, String> cgToCgProduct_Map{
        get{
            if(cgToCgProduct_Map==null){
                populateCgMappings();
            }
            return cgToCgProduct_Map;
        }
        set;
    }

    public static Map<String, String> productToCgCustomerType_Map{
        get{
            if(productToCgCustomerType_Map==null){
                populateCgMappings();
            }
            return productToCgCustomerType_Map;
        }
        set;
    }

    private static void populateCgMappings(){
        cgToCgProduct_Map = new Map<String, String>();
        productToCgCustomerType_Map = new Map<String, String>();

        for(CGProductMapping__c cgMapping : [Select CGCustomerType__c, ProductName__c, CGProductName__c From CGProductMapping__c]){
            if(String.isNotBlank(cgMapping.CGCustomerType__c) && String.isNotBlank(cgMapping.ProductName__c)){
                productToCgCustomerType_Map.put(cgMapping.ProductName__c.toLowerCase(),cgMapping.CGCustomerType__c);
            }
            if(String.isNotBlank(cgMapping.CGProductName__c) && String.isNotBlank(cgMapping.ProductName__c)){
                cgToCgProduct_Map.put(cgMapping.CGProductName__c.toLowerCase(), cgMapping.ProductName__c);
            }

        }
    }
*/
    private static void populateProducts(){
        productValueSet = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Case.Product__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            productValueSet.add(pickListVal.getValue());
        }
    }


    private static void getStateCodeToNameMap(){
        stateCodeToName_Map = new Map<String,String>();
        for(State__mdt state : [Select StateCodes__c, State_Name__c From State__mdt]){
            stateCodeToName_Map.put(state.StateCodes__c, state.State_Name__c);
        }
    }

    //methods
    private static Map<String, Group> getPublicGroups(){
        Map<String,Group> publicGroupToDeveloperName_Map = new Map<String,Group>();
        for(Group grp : [Select ID, DeveloperName From Group Where Type='Regular']){
            if(String.isNotBlank(grp.DeveloperName)){
                publicGroupToDeveloperName_Map.put(grp.DeveloperName,grp);
            }
        }
        return publicGroupToDeveloperName_Map;
    }
    private static ID getBusinessHourId(String businessHourName){
        List<BusinessHours> businessHourList = [Select ID From BusinessHours Where Name = :businessHourName];
        if(businessHourList.size()>0){
            return businessHourList[0].ID;
        }
        return null;
    }
    public static Map<String, CaseAdmin__c> getCaseAdminToSubmissionSourceCodeMap(){
        if(caseAdminToSubmissionSourceCode_Map!=null && caseAdminToSubmissionSourceCode_Map.size() > 0){
            return caseAdminToSubmissionSourceCode_Map;
        }
        populateCaseAdminAndCaseAdminStateMaps();
        return caseAdminToSubmissionSourceCode_Map;
    }

    public static Map<String, CaseAdminState__c> getCaseAdminStatesToCompositeKey_Map(){
        if(compositeKeyToCaseAdminState_Map!=null && compositeKeyToCaseAdminState_Map.size() > 0){
            return compositeKeyToCaseAdminState_Map;
        }
        populateCaseAdminAndCaseAdminStateMaps();
        return compositeKeyToCaseAdminState_Map;
    }
    private static void populateCaseAdminAndCaseAdminStateMaps(){
        if(caseAdminToSubmissionSourceCode_Map!=null && caseAdminToSubmissionSourceCode_Map.size()>0){
            return;
        }else{
            caseAdminToSubmissionSourceCode_Map = new Map<String, CaseAdmin__c>();
            compositeKeyToCaseAdminState_Map = new Map<String, CaseAdminState__c>();
            for(CaseAdmin__c caseAdmin : getCaseAdminRecord()){
                caseAdminToSubmissionSourceCode_Map.put(caseAdmin.SubmissionSource__c, caseAdmin);

                if(caseAdmin.Case_Admin_States1__r!=null && caseAdmin.Case_Admin_States1__r.size()>0){
                    for(CaseAdminState__c caseAdminState : caseAdmin.Case_Admin_States1__r){
                        compositeKeyToCaseAdminState_Map.put(caseAdminState.SubmissionSourceCode__c+'-'+caseAdminState.State__c, caseAdminState);
                    }

                }
            }
        }
    }

    //return List of Case Admin record for given Submission Code Type.
    private static List<CaseAdmin__c> getCaseAdminRecord(){
        return([Select
                SubmissionSource__c,
                ExpectedCloseDays__c,
                ExpectedCloseDaysChild__c,
                ExpectedResponseDays__c,
                Feature__c,
                FeatureType__c,
                ResponseRequired__c,
                SendCommunication__c,
                (Select
                 CaseAdminValue__c,
                 SubmissionSourceCode__c,
                 ExpectedCloseDays__c,
                 ExpectedCloseDaysChild__c,
                 ExpectedResponseDays__c,
                 State__c,
                 CaseAdminFeature__c,
                 CaseAdminFeatureType__c,
                 SendCommunication__c
                 From Case_Admin_States1__r)
                From CaseAdmin__c]);
    }

    //return record type for any sObjectType passed as arguement in function call..
    private static List<RecordType> getRecordTypeList(String sObjectType){
        return ([Select
                 DeveloperName,
                 sObjectType
                 From RecordType
                 Where sObjectType = :sObjectType]);
    }

    public static Set<ID> exemptedProfileIds_Set{
        get{
            if(exemptedProfileIds_Set==null){
                exemptedProfileIds_Set = getProfileIds();
                return exemptedProfileIds_Set;
            }
            else{
                return exemptedProfileIds_Set;
            }
        }
        private set;
    }
    private static Set<ID> getProfileIds(){
        Set<String> exemptedProfileName_Set = new Set<String>();
        List<CaseCancellationException__mdt> caseCancellationException_List = [Select ProfileName__c From CaseCancellationException__mdt];
        for(CaseCancellationException__mdt cce : caseCancellationException_List){
            exemptedProfileName_Set.add(cce.ProfileName__c);
        }
        Map<ID,Profile> profileToId_Map = new Map<ID, Profile>([Select Id From Profile Where Name IN:exemptedProfileName_Set]);

        if(profileToId_Map!=null && profileToId_Map.size()>0){
            return profileToId_Map.keySet();
        }
        return (new Set<ID>());
    }

    public static boolean checkUserEligibilityToOpenClosedCase(){
        ID currentUserID = UserInfo.getUserId();
        Integer count = [Select count() From PermissionSetAssignment Where PermissionSetId IN (Select ID From PermissionSet Where PermissionsTransferAnyCase=true) And AssigneeId = :currentUserID];
        if(count>0){
            return true;
        }
        return false;
    }

    //starts -- childCaseConfigToCompositeKey_Map
    public static Map<String,ChildCaseAssignmentConfig__c> childCaseConfigToCompositeKey_Map{
        get{
            if(childCaseConfigToCompositeKey_Map==null){
                populatedChildCaseConfigToCompositeKey_Map();
            }
            system.debug('====??'+ childCaseConfigToCompositeKey_Map);
            return childCaseConfigToCompositeKey_Map;
        }
        set;
    }
    private static void populatedChildCaseConfigToCompositeKey_Map(){
        String key;
        childCaseConfigToCompositeKey_Map = new Map<String,ChildCaseAssignmentConfig__c>();
        for(ChildCaseAssignmentConfig__c config : [Select Action1__c, Action2__c, Action3__c, CustomerType__c, Product__c, Queue__c, User__c From ChildCaseAssignmentConfig__c]){
            key = config.Action1__c+'--'+config.Action2__c+'--'+config.Action3__c+'--'+config.CustomerType__c+'--'+config.Product__c;
            if(String.isNotBlank(key) && !childCaseConfigToCompositeKey_Map.containsKey(key)){
                childCaseConfigToCompositeKey_Map.put(key,config);
            }
            key='';
        }
    }// ends -- childCaseConfigToCompositeKey_Map

    //starts -- queueToDeveloperName_Map
    public static Map<String, Group> queueToDeveloperName_Map{
        get{
            if(queueToDeveloperName_Map==null){
                getQueues();
            }
            return queueToDeveloperName_Map;
        }
        set;

    }
    private static void getQueues(){
        queueToDeveloperName_Map = new Map<String,Group>();
        for(Group grp : [Select ID, DeveloperName From Group Where Type='Queue']){
            if(String.isNotBlank(grp.DeveloperName)){
                queueToDeveloperName_Map.put(grp.DeveloperName,grp);
            }
        }
    }// ends -- queueToDeveloperName_Map

    public static Map<String,UserRole> rolesToDeveloperName_Map{
        get{
            if(rolesToDeveloperName_Map==null){
                getRoles();
            }
            return rolesToDeveloperName_Map;
        }
        set;
    }
    private static void getRoles(){
        rolesToDeveloperName_Map = new Map<String,UserRole>();
        for(UserRole role : [Select DeveloperName From UserRole]){
            rolesToDeveloperName_Map.put(role.DeveloperName,role);
        }
    }

    //set that contains all the users of the queue.
    Static Set<ID> queueMemberUserIds_Set = new Set<ID>();
    //set of roleIds & subRoleIds of user...
    Static Set<ID> roleId_Set = new Set<ID>();

    // This methods return all the users in a particular Queue.
    public static Set<ID> fetchUsers(String queueName){
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        String roleType = Schema.SObjectType.UserRole.getKeyPrefix();
        Set<ID> groupId_Set = new Set<ID>();

        for(GroupMember member : [Select userOrGroupId, GroupId, Group.relatedId From GroupMember Where Group.DeveloperName = :queueName]){
            system.debug('>>>>'+member);
            system.debug('====>>>'+String.valueOf(member.userOrGroupId));
            //user member..
            if(String.valueOf(member.userOrGroupId).startsWith(userType)){
                queueMemberUserIds_Set.add(member.userOrGroupId);
            }//Role
            else if(String.valueOf(member.userOrGroupId).startsWith(groupType)
                    && groupIdToRelatedId_Map!=null
                    && groupIdToRelatedId_Map.containsKey(member.userOrGroupId)
                    && groupIdToRelatedId_Map.get(member.userOrGroupId)!=null
                    && String.valueOf(groupIdToRelatedId_Map.get(member.userOrGroupId)).startsWith(roleType)){
                    roleId_Set.add(groupIdToRelatedId_Map.get(member.userOrGroupId));
            }//Group
            else if(String.valueOf(member.userOrGroupId).startsWith(groupType)){
                groupId_Set.add(member.userOrGroupId);
            }
        }//for ends..
        system.debug('queueMemberUserIds_Set==>'+queueMemberUserIds_Set);
        system.debug('roleId_Set==>'+roleId_Set);
        system.debug('groupId_Set==>'+groupId_Set);
        if(groupId_Set.size()>0){
            fetchUsers(groupId_set);
        }
        if(roleId_Set.size()>0){
            for(User member : [Select ID From User Where UserRoleId IN :roleId_Set And isActive=True]){
                queueMemberUserIds_Set.add(member.Id);
            }
        }
        return queueMemberUserIds_Set;
    }//method ends.

    //
    private static void fetchUsers(Set<ID> groupIds_Set){
        if(groupIds_Set!=null && groupIds_Set.size()>0){
            String userType = Schema.SObjectType.User.getKeyPrefix();
            String groupType = Schema.SObjectType.Group.getKeyPrefix();
            String roleType = Schema.SObjectType.UserRole.getKeyPrefix();
            Set<ID> groupId_Set = new Set<ID>();
            for(GroupMember member : [Select userOrGroupId, GroupId, Group.relatedId From GroupMember Where GroupId IN :groupIds_Set]){
                //user member..
                if(String.valueOf(member.userOrGroupId).startsWith(userType)){
                    queueMemberUserIds_Set.add(member.userOrGroupId);
                }//Role
                else if(String.valueOf(member.userOrGroupId).startsWith(groupType)
                        && groupIdToRelatedId_Map!=null
                        && groupIdToRelatedId_Map.containsKey(member.userOrGroupId)
                        && groupIdToRelatedId_Map.get(member.userOrGroupId)!=null
                        && String.valueOf(groupIdToRelatedId_Map.get(member.userOrGroupId)).startsWith(roleType)){
                        roleId_Set.add(groupIdToRelatedId_Map.get(member.userOrGroupId));
                }//Group
                else if(String.valueOf(member.userOrGroupId).startsWith(groupType)){
                    groupId_Set.add(member.userOrGroupId);
                }
            }//for ends...
            system.debug('groupId_Set2==>'+groupId_Set);
            if(groupId_Set.size()>0){
                fetchUsers(groupId_set);
            }
        }else{
            return;
        }
    }
    private static Map<ID,ID> groupIdToRelatedId_Map{
        get{
            if(groupIdToRelatedId_Map==null){
                getPublicGroupsForRole();
            }
        return groupIdToRelatedId_Map;
        }
        set;
    }
    private static void getPublicGroupsForRole(){
        groupIdToRelatedId_Map = new Map<ID,ID>();
        for(Group roleGroup : [Select relatedId,Type From Group Where relatedId!=null]){
            groupIdToRelatedId_Map.put(roleGroup.ID, roleGroup.relatedId);
        }
    }//methods ends...
    public static Integer getBatchSize(String batchName){
        List<BatchSetting__mdt> batchSettings = [Select
                                                 BatchSize__c
                                                 From
                                                 BatchSetting__mdt
                                                 Where DeveloperName = :batchName];
        if(batchSettings.size()>0 && batchSettings[0].batchSize__c!=null && batchSettings[0].batchSize__c>0){
            return Integer.valueOf(batchSettings[0].batchSize__c);
        }
        return 200;
    }

    public static List<BWC_Interaction_Metadata__mdt> getInteractionMetadata(){

        List<BWC_Interaction_Metadata__mdt> returnList = [
            SELECT Action__c, Allow_LIC_Escalation__c, Type__c
            FROM BWC_Interaction_Metadata__mdt
            WHERE Allow_LIC_Escalation__c = true ];
            return returnList;
    }

}