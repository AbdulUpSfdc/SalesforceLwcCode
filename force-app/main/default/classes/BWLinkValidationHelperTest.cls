@isTest
public class BWLinkValidationHelperTest {
    
    //class BWLinkValidationHelper is without sharing, so profiles/permission sets shouldn't matter
    
    public static Knowledge__kav knowledgekav;
    public static Knowledge__kav knowledgekav1;
    public static List<Knowledge__DataCategorySelection> dataCategories;
    public static BWKnowledgeArticleLink__c bwLink;
    public static Map<Id, BWKnowledgeArticleLink__c> linkMap;
        
    public static void createTestData(){
      	List<Knowledge__kav> knowledgeList = new List<Knowledge__kav>();
        
        knowledgekav = KM_TestDataFactory.getKnowledKav(system.today(),'test','testurl',false,'ABC');
        //knowledgekav.ContentSponsor__c = 'Content Sponsor';
        
        knowledgeList.add(knowledgekav);
        
        knowledgekav1 = KM_TestDataFactory.getKnowledKav(system.today(),'test1','testurl1',false,'ABC');
        //knowledgekav1.ContentSponsor__c = 'Content Sponsor';
        
        knowledgeList.add(knowledgekav1);
        
        insert knowledgeList;  
        
        Map<Id, Knowledge__kav> knowledgeMap = new Map<Id, Knowledge__kav>([SELECT Id, UrlName FROM Knowledge__kav WHERE Id in :knowledgeList]);
        
        List<Knowledge__DataCategorySelection> existingCategories = BWLinkValidationHelper.getDataCategories(knowledgeMap.keySet());
        System.debug('Existing data category selections: ' + existingCategories);
        //delete any automatically created data categories
        delete existingCategories;
    
    }
    
    public static Map<Id, BWKnowledgeArticleLink__c> queryLink(Id linkId) {
        return queryLinks(new Set<Id>{linkId});
    }
    
    public static Map<Id, BWKnowledgeArticleLink__c> queryLinks(Set<Id> linkIdSet) {
        linkMap = new Map<Id, BWKnowledgeArticleLink__c>([SELECT Id,Knowledge_Article__c,Type__c,Link_URL__c,ValidationMessage__c 
                                                          FROM BWKnowledgeArticleLink__c
                                                         WHERE Id In :linkIdSet]);
        return linkMap;
    }
    
    public static void createLink() {
        bwLink = new BWKnowledgeArticleLink__c();
        bwLink.Knowledge_Article__c = knowledgekav.Id;
        bwLink.Type__c = 'Knowledge Article';
        bwlink.Link_URL__c = BWLinkValidationHelper.ARTICLE_URL_PATH + knowledgekav1.UrlName;
        insert bwLink;
    }
    
    public static testMethod void testvalidateLinksNoChannels(){
        createTestData();
        //validate with no links
        BWLinkValidationHelper.validateLinks(knowledgekav.id);
        //nothing to validate because there are no innks
        
        createLink();
        
         //validate with no links where neither has data categories
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
      
        linkMap = queryLink(bwLink.Id) ;
        System.debug('Validation message: ' + linkMap.get(bwLink.Id).ValidationMessage__c);
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.DATA_CATEGORIES_MATCH));
        
    }        
 
 	public static testMethod void testvalidateLinksParentAllChannels(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'All';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.DATA_CATEGORIES_CHILD_NONE));
    }    

    public static testMethod void testvalidateLinksParentAllChannelsChildAll(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'All';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'All';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);

        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.DATA_CATEGORIES_BOTH_ALL));
    }  
    
       public static testMethod void testvalidateLinksParentSomeChannelsChildAll(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'ACC';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'All';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);

        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.DATA_CATEGORIES_CHILD_ALL));
    }   
 
    
    public static testMethod void testvalidateLinksMatch(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'Carriers';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'Carriers';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);

        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.DATA_CATEGORIES_MATCH));
    }   

     public static testMethod void testvalidateLinksParentAllChildSome(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'All';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'Carriers';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);

        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.MSG_LINK_ONLY));
    	//System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains('Carriers'));

     }   
    
	public static testMethod void testvalidateLinksParentAllChildNoMatch(){
        createTestData();
       
        createLink();
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'ACC';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'Carriers';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);

        insert dataCategories;
        
        BWLinkValidationHelper.validateLinks(knowledgekav.id); 
        
        linkMap = queryLink(bwLink.Id) ;
        System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains(BWLinkValidationHelper.MSG_LINK_NOT_AVAILABLE));
        //System.assert(linkMap.get(bwLink.Id).ValidationMessage__c.contains('ACC'));

	} 

    public static testMethod void testGetArticleId(){
    	createTestData();
        System.assertEquals(BWLinkValidationHelper.getArticleId(knowledgekav.id), knowledgekav.id);
        System.assert(BWLinkValidationHelper.getArticleId('BADID').contains(BWLinkValidationHelper.ERROR_INVALID_ID));
    }    
    
    public static testMethod void testcompareDataCategories(){
        createTestData();
       
        dataCategories = new List<Knowledge__DataCategorySelection>();
        Knowledge__DataCategorySelection dataCat_AdvTechSupport1 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport1.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport1.DataCategoryName = 'All';
        dataCat_AdvTechSupport1.ParentId = knowledgekav.Id;
        dataCategories.add(dataCat_AdvTechSupport1);
        
        Knowledge__DataCategorySelection dataCat_AdvTechSupport2 = new Knowledge__DataCategorySelection();
        dataCat_AdvTechSupport2.DataCategoryGroupName = 'Channel';
        dataCat_AdvTechSupport2.DataCategoryName = 'All';
        dataCat_AdvTechSupport2.ParentId = knowledgekav1.Id;
        dataCategories.add(dataCat_AdvTechSupport2);
 
        insert dataCategories;
        
        String compareresult = BWLinkValidationHelper.compareDataCategories(knowledgekav.id, knowledgekav1.id); 
        System.assert(compareresult.contains(BWLinkValidationHelper.DATA_CATEGORIES_BOTH_ALL));
        
        compareresult = BWLinkValidationHelper.compareDataCategories(knowledgekav.id, null); 
        System.assert(compareresult.contains(BWLinkValidationHelper.ERROR_INVALID_ID));
    }  
 	
        public static testMethod void testisValidArticleURL() {
            String kmArticleURl = '/articles/Knowledge/TESTURL';
     		Set<String> linkedArticleURLNames = new Set<String>();
    		System.assertEquals(true, BWLinkValidationHelper.isValidArticleURL(kmArticleURL));
            kmArticleURL = 'es/Knowled';
            System.assertEquals(false, BWLinkValidationHelper.isValidArticleURL(kmArticleURL));
        }
    
    	 public static testMethod void testGetArticleURL() {
            String kmArticleURl = '/articles/Knowledge/TESTURL';
     		Set<String> linkedArticleURLNames = new Set<String>();
    		linkedArticleURLNames.add('AT-T-DC1');
    		System.assertEquals('TESTURL', BWLinkValidationHelper.getArticleURL(kmArticleURL));
        }
 
}