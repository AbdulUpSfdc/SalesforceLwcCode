@istest
public class callArticleKeywodSearchBatch_Test {
    @isTest
    public static void testcallArticleKeywodSearchBatch(){
        id jobID=callArticleKeywodSearchBatch.InvokeBatch('Test','nk1476');
        callArticleKeywodSearchBatch.getuserattid();
        callArticleKeywodSearchBatch.checkpermission('nk1476');
        callArticleKeywodSearchBatch.getBatchJobStatus(jobID);
    }

}