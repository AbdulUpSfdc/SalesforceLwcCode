/*------------------------------------------------------------------------
Utility class to create test data.

History
<Date>      <Authors Name>     <Brief Description of Change>
26-May-2020  Mammet Developer   Utility class to create test data.  
----------------------------------------------------------------------------*/
@isTest
public class Utility_Test {
    
    public static User createTestUser(Id profID, String fName, String lName) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                                lastName = lName,
                                email = uniqueName + '@test' + orgId + '.org',
                                Username = uniqueName + '@test' + orgId + '.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profId);
        return tuser;
    }
    
    public static User createTestUserWithRole(Id profID, String fName, String lName, Id roleId) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        User tuser = new User(  firstname = fName,
                                lastName = lName,
                                email = uniqueName + '@test' + orgId + '.org',
                                Username = uniqueName + '@test' + orgId + '.org',
                                EmailEncodingKey = 'ISO-8859-1',
                                Alias = uniqueName.substring(18, 23),
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US',
                                ProfileId = profId,
                                UserRoleId = roleId);
        return tuser;
    }
    
    //methods assigns role to the user.
    public static void assignPermissionSet(List<UserPermissionSetWrapper> userPermissionSet_List){
        Set<String> permissionSetNames = new Set<String>();
        Map<String,PermissionSet> permissionSetToName_Map;
        
        for(UserPermissionSetWrapper wrapper : userPermissionSet_List){
            if(wrapper.permissionSetNames!=null & wrapper.permissionSetNames.size()>0){
                permissionSetNames.addAll(wrapper.permissionSetNames);	    
            }    
        }
        
        if(permissionSetNames.size()>0){
            permissionSetToName_Map = new Map<String,PermissionSet>();
            for(PermissionSet permissionSet : [Select ID,Name From PermissionSet Where Name IN : permissionSetNames]){
                permissionSetToName_Map.put(permissionSet.Name, permissionSet);	    
            }
        }
        if(permissionSetToName_Map!=null && permissionSetToName_Map.size()>0){
            List<PermissionSetAssignment> permissionSetAssignment_List = new List<PermissionSetAssignment>();
            PermissionSetAssignment permissionSetAssignment;
            for(UserPermissionSetWrapper wrapper : userPermissionSet_List){
                for(String prSt : wrapper.permissionSetNames){
                    if(permissionSetToName_Map.containsKey(prSt)){
                        permissionSetAssignment = new PermissionSetAssignment();
                        permissionSetAssignment.AssigneeId = wrapper.user.Id;
                        permissionSetAssignment.PermissionSetId = permissionSetToName_Map.get(prSt).ID;
                        permissionSetAssignment_List.add(permissionSetAssignment);
                    }
                }    
            } 
            if(permissionSetAssignment_List.size()>0){
                insert permissionSetAssignment_List;
            }
        }
    }
    
    @future
    public static void createCaseAdminRecords(){
        List<CaseAdmin__c> caseAdminState_List = new List<CaseAdmin__c>();
        
        //1
        CaseAdmin__c newCaseAdmin =  new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='4-FCC';
        newCaseAdmin.ExpectedCloseDays__c=17;
        newCaseAdmin.ExpectedResponseDays__c=17;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='4 FCC';
        newCaseAdmin.Subject__c='External';
        caseAdminState_List.add(newCaseAdmin);
        
        //2
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='6PR-PR/Media';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.Feature__c='Official Non-Regulatory';
        newCaseAdmin.FeatureType__c='Executive';
        newCaseAdmin.ResponseRequired__c=false;
        newCaseAdmin.Name='6PR-PR/Media';
        newCaseAdmin.ExpectedCloseDaysChild__c=3;
        caseAdminState_List.add(newCaseAdmin);
        
        //3
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='3C-State Commission';
        newCaseAdmin.ExpectedCloseDays__c=5;
        newCaseAdmin.ExpectedResponseDays__c=17;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='State Reg';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='3C-State Commission';
        caseAdminState_List.add(newCaseAdmin);
        
        //4
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='4R-FCC Rebuttal';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='4R-FCC Rebuttal';
        caseAdminState_List.add(newCaseAdmin);
        
        //5
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='1CEO-Chairman';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='1CEO-Chairman';
        newCaseAdmin.Subject__c='External';
        caseAdminState_List.add(newCaseAdmin);
        
        //6
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='1V-Web Officer Referral';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='1V-Web Officer Referral';
        caseAdminState_List.add(newCaseAdmin);
        
        //7
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='2-Direct from Customer';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='2-Direct from Customer';
        newCaseAdmin.Subject__c='External';
        caseAdminState_List.add(newCaseAdmin);
        
        //8
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='6L-Legal';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='6L-Legal';
        caseAdminState_List.add(newCaseAdmin);
        
        //BBB
        //9
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='7B-Better Business Bureau-BBB';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='6L-Legal';
        caseAdminState_List.add(newCaseAdmin);
        
        //10
        newCaseAdmin = new CaseAdmin__c();
        newCaseAdmin.SubmissionSource__c='7BR-BBB Rebuttal';
        newCaseAdmin.ExpectedCloseDays__c=10;
        newCaseAdmin.ExpectedResponseDays__c=10;
        newCaseAdmin.Feature__c='Regulatory';
        newCaseAdmin.FeatureType__c='FCC';
        newCaseAdmin.ResponseRequired__c=true;
        newCaseAdmin.Name='6L-Legal';
        caseAdminState_List.add(newCaseAdmin);
        
        insert caseAdminState_List;
        
        createAdminStatesRecords(caseAdminState_List[2]);
        createSubmissionSourceEmailRecords(caseAdminState_List);
        
        
    }
    
    private static void createAdminStatesRecords(CaseAdmin__c caseAdmin){
        List<CaseAdminState__c> caseAdminState_List = new List<CaseAdminState__c>();
        
        CaseAdminState__c caseAdminState =  new CaseAdminState__c();
        caseAdminState.CaseAdminValue__c=caseAdmin.ID;
        caseAdminState.State__c='Alaska';
        caseAdminState.Name='Alaska';
        caseAdminState.ExpectedCloseDays__c=8;
        caseAdminState.ExpectedResponseDays__c=5;
        caseAdminState.ExpectedCloseDaysChild__c=2;
        caseAdminState_List.add(caseAdminState);
        
        caseAdminState =  new CaseAdminState__c();
        caseAdminState.CaseAdminValue__c=caseAdmin.ID;
        caseAdminState.State__c='Arizona';
        caseAdminState.Name='Arizona';
        caseAdminState.ExpectedCloseDays__c=8;
        caseAdminState.ExpectedResponseDays__c=5;
        caseAdminState_List.add(caseAdminState);
        
        caseAdminState =  new CaseAdminState__c();
        caseAdminState.CaseAdminValue__c=caseAdmin.ID;
        caseAdminState.State__c='Arkansas';
        caseAdminState.Name='Arkansas';
        caseAdminState.ExpectedCloseDays__c=8;
        caseAdminState.ExpectedResponseDays__c=5;
        caseAdminState_List.add(caseAdminState);
        
        caseAdminState =  new CaseAdminState__c();
        caseAdminState.CaseAdminValue__c=caseAdmin.ID;
        caseAdminState.State__c='California';
        caseAdminState.Name='California';
        caseAdminState.ExpectedCloseDays__c=8;
        caseAdminState.ExpectedResponseDays__c=6;
        caseAdminState_List.add(caseAdminState);
        
        caseAdminState =  new CaseAdminState__c();
        caseAdminState.CaseAdminValue__c=caseAdmin.ID;
        caseAdminState.State__c='Colorado';
        caseAdminState.Name='Colorado';
        caseAdminState.ExpectedCloseDays__c=7;
        caseAdminState.ExpectedResponseDays__c=4;
        caseAdminState_List.add(caseAdminState);
        
        insert caseAdminState_List;
    }
    //create submission source email records...
    private static void createSubmissionSourceEmailRecords(List<CaseAdmin__c> caseAdmin_List){
        List<SubmissionSourceEmail__c> submissionSourceEmail_List = new List<SubmissionSourceEmail__c>();
        
        SubmissionSourceEmail__c submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@example.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[4].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@test.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[4].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='test@test.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[4].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='fantom@test.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[4].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@fest.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[5].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@fest.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[6].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@xest.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[7].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        //9
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@bbb.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[8].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        //10
        submissionSourceEmail = new SubmissionSourceEmail__c();
        submissionSourceEmail.Name='@bbb.com';
        submissionSourceEmail.CaseAdmin__c=caseAdmin_List[9].Id;
        submissionSourceEmail_List.add(submissionSourceEmail);
        
        insert submissionSourceEmail_List;
    }

     //create cg product mapping records...
    public static void createProductMapping(){
        List<CGProductMapping__c> cgProductMapping_List = new List<CGProductMapping__c>();
        CGProductMapping__c cgProductMapping = new CGProductMapping__c();

        cgProductMapping.CGProductName__c='AT&T DIRECTV';
        cgProductMapping.ProductName__c='DIRECTV';
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='AT&T U-verse TV';
        cgProductMapping.ProductName__c='Uverse TV';
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='firstnet';
        cgProductMapping.ProductName__c='FirstNet'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='hbomax';
        cgProductMapping.ProductName__c='HBO MAX'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='AT&T Phone';
        cgProductMapping.ProductName__c='Uverse Phone'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='digitallife';
        cgProductMapping.ProductName__c='Digital Life'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='dtvnow';
        cgProductMapping.ProductName__c='DIRECTV STREAM'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='AT&T Internet';
        cgProductMapping.ProductName__c='Uverse Internet'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='AT&T Fixed Wireless Internet';
        cgProductMapping.ProductName__c='Fixed Wireless/Internet'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='wireless';
        cgProductMapping.ProductName__c='Wireless'; 
        cgProductMapping_List.add(cgProductMapping);

        cgProductMapping = new CGProductMapping__c();
        cgProductMapping.CGProductName__c='prepaid';
        cgProductMapping.ProductName__c='Wireless Prepaid'; 
        cgProductMapping_List.add(cgProductMapping);

        insert cgProductMapping_List;
    }

    // create cg customer mapping
    public static void cgCustomerMapping(){
        List<CGCustomerMapping__c> cgCustomerMapping_List = new List<CGCustomerMapping__c>();
        CGCustomerMapping__c mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='wireless';
        mapping.ProductName__c ='Digital Life';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='uverse';
        mapping.ProductName__c ='Uverse Internet';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='dtvnow';
        mapping.ProductName__c ='AT&T TV';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='wireless';
        mapping.ProductName__c ='Fixed Wireless/Internet';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='uverse';
        mapping.ProductName__c ='Uverse Phone';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='wireless';
        mapping.ProductName__c ='FirstNet';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='uverse';
        mapping.ProductName__c ='DIRECTV';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='wireless';
        mapping.ProductName__c ='Wireless';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='uverse';
        mapping.ProductName__c ='Uverse TV';
        cgCustomerMapping_List.add(mapping);

        mapping = new CGCustomerMapping__c();
        mapping.CGCustomerType__c='wireless';
        mapping.ProductName__c ='Wireless Prepaid';
        cgCustomerMapping_List.add(mapping);

        insert cgCustomerMapping_List;
    }
    
    
    //wrapper for user and permission set mapping..
    public class UserPermissionSetWrapper{
        public User user;
        public Set<String> permissionSetNames;
        
        public UserPermissionSetWrapper(){
            permissionSetNames = new Set<String>();
        }
    }
}