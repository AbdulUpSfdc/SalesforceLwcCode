@isTest
private class CaseOOP_ServiceTest {
    // As of 10/21/2021, only method being called in CaseOOP_Service is updateLastActivityonCase()
    @IsTest
    static void testUpdateLastActivityOnCase() {
        // Creating test data
        Case c = new Case();
        c.Type = 'OOP';
        c.Origin = 'Email';
        c.recordTypeId = MetadataSelector.caseRecordTypeToDeveloperName_Map.get(
                'OOP'
            )
            .ID;
        c.Description = 'Test Scenario Test';
        c.Status = 'New';
        c.Priority = 'Medium';
        c.CustomerType__c = 'Consumer';
        c.Last_Activity_Date__c = DateTime.newInstance(2008, 12, 1, 12, 30, 2);
        insert c;

        // Adding case to set
        Set<Id> caseIds = new Set<Id>();
        caseIds.add(c.Id);

        // Calling method
        CaseOOP_Service.updateLastActivityonCase(caseIds);

        // Verifying result
        Case updatedCase = [
            SELECT Id, Last_Activity_Date__c
            FROM Case
            WHERE ID = :c.Id
        ];
        System.assert(
            updatedCase.Last_Activity_Date__c !=
            DateTime.newInstance(2008, 12, 1, 12, 30, 2)
        );
    }
}