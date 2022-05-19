/*
  CreateChildCase
  Used in aura component CreateChildCase
*/  

public without sharing class CreateChildCase {
        
    //Mammet
    @AuraEnabled 
    public static ChildCaseInfo getChildCaseInfo(String parentCaseId){
        ChildCaseInfo wrapper = new ChildCaseInfo();
        
        wrapper.parentCase = getParentCase(parentCaseId);
        system.debug('wrapper.parentCase==>'+wrapper.parentCase);
        wrapper.regionName = fetchRegionNameForState(wrapper.parentCase);
        wrapper.childExpectedCloseDate = Utility.populateDates(wrapper.parentCase);
        wrapper.parentExpectedCloseDate = wrapper.parentCase.ExpectedCloseDate__c; 
                        
        //wrapper.regionName = fetchRegionNameForState(wrapper.parentCase);
        wrapper.childRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OOP').getRecordTypeId();
        String userRole = [Select UserRole.Name From User Where ID = :UserInfo.getUserId() WITH SECURITY_ENFORCED].UserRole.Name;
        wrapper.display = (String.isNotBlank(userRole) && userRole.equalsIgnoreCase('Field Agent')) ? false : true; 
        system.debug('wrapper==>'+wrapper);
        checkDates(wrapper);
        return wrapper;
    }
    
    private static void checkDates(ChildCaseInfo wrapper){
        if(wrapper.childExpectedCloseDate > wrapper.parentExpectedCloseDate){
            wrapper.childCloseDateValid = false;
        }
    }
    
    //return the region for against the case of the parent case..
    private static String fetchRegionNameForState(Case parentCase){
        String state;
        String region;
        
        if(parentCase != NULL) {
            if(String.isNotBlank(parentCase.ComplainantState__c)){
                state = parentCase.ComplainantState__c;
            }
            else if(String.isNotBlank(parentCase.State__c)){
                state = parentCase.State__c;     
            }
            if(String.isNotBlank(state)){
                List<ChildCaseRegion__mdt> caseRegion_List = [SELECT 
                                                              RegionName__c 
                                                              FROM ChildCaseRegion__mdt 
                                                              WHERE State__c =:state WITH SECURITY_ENFORCED];
                if(caseRegion_List.size()>0){
                    region = caseRegion_List[0].RegionName__c;    
                }
            }
        }
        
        return region;
    }
    
    //Return Parent Case details
    private static Case getParentCase(String caseId){
        List<Case> caseList = new List<Case>();
        if(String.isNotBlank(caseId)){
            caseList = [Select
                        Type,
                        Subject,
                        Description,
                        Product__c, 
                        AccountId,
                        BillingCity__c,
                        BillingCountry__c,
                        BillingCustFirstName__c,
                        BillingCustLastName__c,
                        BillingEmail__c,
                        BillingPhone__c,
                        BillingState__c,
                        BillingStreet__c,
                        BillingZip__c,
                        City__c,
                        ComplainantCity__c,
                        ComplainantFirstName__c,
                        ComplainantLastName__c,
                        ComplainantState__c,
                        ComplainantStreet__c,
                        ComplainantZip__c,
                        ContactId,
                        ContactEmail,
                        ContactPhone,
                        Country__c,
                        CustomerType__c,
                        Cust_Type__c,
                        Origin,
                        Priority,
                        ReferenceData__c,
                        AccountIdentifier__c,
                        ServiceBusinessHours__c,
                        ServiceCustFirstName__c,
                        ServiceCustLastName__c,
                        ServicePhone__c,
                        //Source__c,
                        State__c,
                        StreetName__c,
                        SubmissionSourceCode__c,
                        ZipPostalCode__c,
                        SuppliedPhone,
                        SuppliedEmail,
                        SuppliedCompany,
                        BusinessHoursId,
                        ExpectedCloseDate__c,
                        Product_Type_OOP__c,
                        OwnerId,
                        Billing_Account__c
                        From Case 
                        Where ID = :caseId WITH SECURITY_ENFORCED];
            
        }
        if(caseList.size()>0){
            return caseList[0];
        }
        return null;
    }
    
    //Wrapper for child case information
    public class ChildCaseInfo{
        @AuraEnabled
        public Date childExpectedCloseDate;
        
        @AuraEnabled
        public Date parentExpectedCloseDate;
        
        @AuraEnabled
        public Boolean childCloseDateValid=true;
        
        @AuraEnabled
        public String regionName;
        
        @AuraEnabled
        public String childRecordTypeId;
        
        @AuraEnabled
        public Case parentCase;
        
        @AuraEnabled
        public Boolean display=true;
        
        public ChildCaseInfo(){
            parentCase = new Case();    
        }
    }
    //Mammet
}