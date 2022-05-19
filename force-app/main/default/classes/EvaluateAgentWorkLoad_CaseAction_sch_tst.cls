@isTest
private class EvaluateAgentWorkLoad_CaseAction_sch_tst {
   @isTest
    private static void scheduler_test(){
        system.runAs(new User(ID=UserInfo.getUserId())){
            EvaluateAgentWorkLoad_CaseAction_sch scheduler = new EvaluateAgentWorkLoad_CaseAction_sch();
            String cronString = '0 0 22 * * ?';
            test.starttest();
            String jobID = system.schedule('AgentLoadProcessTest', cronString, scheduler);
            test.stoptest();
            system.assertEquals(cronString,[Select CronExpression From CronTrigger Where ID = :jobID][0].CronExpression);
        }
    }
}