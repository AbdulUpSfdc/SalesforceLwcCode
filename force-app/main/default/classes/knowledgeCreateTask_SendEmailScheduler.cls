global class knowledgeCreateTask_SendEmailScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      knowledgeCreateTask_SendEmailBatch createTaskSendEmailBatch = new knowledgeCreateTask_SendEmailBatch(); 
      database.executebatch(createTaskSendEmailBatch);
   }
}