/*******
    Name : KnowledgeFrontlineTest
    Desription: This is the test class for KnowledgeFrontline
*******/
@isTest
public class KnowledgeFrontlineTest {
    
    @testSetup
    public static void testData(){
        Knowledge__kav knowledge = KM_TestDataFactory.getKnowledKavdata(System.Today().AddDays(5),'testone','testing',true, 'ABC');
    }
    
    @isTest
    public static void KnowledgeFrontTest(){
        test.startTest();
        KnowledgeFrontline.getKnowledgeList();
        test.stopTest();
    }
    @isTest
    public static void KnowledgeFrontTest2(){
        test.startTest();
        KnowledgeFrontline.getSingleKnowledge();
        KnowledgeFrontline.CompWrapper wrp = new KnowledgeFrontline.CompWrapper();
        test.stopTest();
    }
    
}