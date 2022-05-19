global class ArticlePublishScheduler implements Schedulable {

    global void execute(SchedulableContext ctx){
      
      ArticleScheduledPublishBatch  batch = new ArticleScheduledPublishBatch();
      Database.executebatch(batch, 100);
    }
}