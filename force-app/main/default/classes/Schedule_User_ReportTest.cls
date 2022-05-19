@isTest
public class Schedule_User_ReportTest {
@isTest
public static void testUserRptSchedule(){
String CRON_EXP = '0 0 0 15 3 ? 2032';
Test.startTest();
String jobId = System.schedule('ScheduledUserReportTest',
            CRON_EXP,
            new Schedule_User_Report());
 CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
 System.assertEquals(CRON_EXP, ct.CronExpression);
 System.assertEquals(0, ct.TimesTriggered);   
Test.stopTest();
    
}
}