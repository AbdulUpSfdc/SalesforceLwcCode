@istest
public class KnowledgeArchiveControllerTest {

    
    @testsetup 
    
    public static void setupDataKnwArch(){
        List<Knowledge__kav> KnwArchlst = new List<Knowledge__kav>();
        Knowledge__kav knowledgekav1 = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',true, 'ABC');
        Knowledge__kav knowledgekav2 = KM_TestDataFactory.getKnowledKav(system.today(),'test1','testurl1',true, 'testABC');
        KnwArchlst.add(knowledgekav1);     
        KnwArchlst.add(knowledgekav2);
        //insert KnwArchlst; 
    
       BWKnowledgeArticleLink__c bwKnwLeg  = new BWKnowledgeArticleLink__c();
        bwKnwLeg.Knowledge_Article__c = KnwArchlst[0].id;
        bwKnwLeg.Link_URL__c ='/testurl';
        insert bwKnwLeg;
        
         
    }
    
    public static testmethod void updateKnowledgeRecordArchiveTest(){
     list<Knowledge__kav> knowledgekav1 = [select id from Knowledge__kav];   
        for(Knowledge__kav kw :knowledgekav1 )
        KnowledgeArchiveController.updateKnowledgeRecordArchive(kw.id); 
        KnowledgeArchiveController.updateKnowledgeRecordArchive(null); 
    }
}