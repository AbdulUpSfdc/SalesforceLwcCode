@isTest
public with sharing class ScheduledOverdueChildCases_Tst
{
    static testMethod void tstScheduledOverdueChildCases()
    {
        Test.startTest();

        ScheduledOverdueChildCases myClass = new ScheduledOverdueChildCases();
        String chron = '0 0 23 * * ?';
        System.schedule('Test Sched ' + DateTime.now(), chron, myClass);

        Test.stopTest();
    }
}