@IsTest
public with sharing class BWC_DependentPicklistTest {
    @IsTest
    static void getDependentOptionsTest(){
        Map<String,List<BWC_Bitset.TPicklistEntry>> res = BWC_DependentPicklist.GetDependentOptions('Case', 'Type', 'CaseAction__c');
    }
}