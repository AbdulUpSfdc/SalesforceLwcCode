@isTest
public with sharing class ScheduledOverdueTasks_Tst
{
    static testMethod void tstScheduledOverdueTasks()
    {
        Test.startTest();

        ScheduledOverdueTasks myClass = new ScheduledOverdueTasks();
        String chron = '0 0 23 * * ?';
        System.schedule('Test Sched ' + DateTime.now(), chron, myClass);

        Test.stopTest();
    }
}