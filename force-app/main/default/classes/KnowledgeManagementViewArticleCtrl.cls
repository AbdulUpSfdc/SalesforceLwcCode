public with sharing class KnowledgeManagementViewArticleCtrl {

    public String articleDetail{public get;set;}

    public String articleSummary{public get;set;}

    public String relatedLinksLable{public get;set;}
    public String relatedLinks{public get;set;}

    public String previewImageFull{public get;set;}

    public Decimal IPADImageWidth{public get;set;}

    public String showRelatedLink{public get;set;}
    
    public KnowledgeManagementViewArticleCtrl() {
	   String ArticleId;

        String showRelatedLink = '';
        String externalLink;
        String extrnalURL;
        String fullImageElement;

        relatedLinks = '';
        relatedLinksLable = '';

       ArticleId = ApexPages.currentPage().getParameters().get('id');
       //BW_ExternalLinkURL__c, BW_External_URL__c
 			String thequery = 'Select BW_Article_Summary__c, BW_Article_Details__c, BW_Preview_Image__c,KnowledgeArticleId, IsVisibleInPkb, UrlName, BW_ExternalLinkURL__c, BW_External_URL__c From Knowledge__kav WHERE Id=\'' +String.escapeSingleQuotes(ArticleId)+'\'';
        List<Knowledge__kav> theArticle  = Database.query(thequery);

        articleSummary = theArticle[0].BW_Article_Summary__c;
        articleDetail = theArticle[0].BW_Article_Details__c;

        fullImageElement = theArticle[0].BW_Preview_Image__c;
// src="https://attone--ctqa--c.documentforce.com/servlet/rtaImage?eid=ka00U000000J0hN&amp;feoid=00N6g00000UM7LH&amp;refid=0EM0U0000009kaA"         
        previewImageFull = (fullImageElement!=null) ? (fullImageElement).substringAfter('src="').replace('&amp;','&').substringBefore('"'):'';
          
        KM_Image_Width__mdt   KM_Image_Width_record =  [SELECT IPAD_Width__c  FROM KM_Image_Width__mdt];
        IPADImageWidth = KM_Image_Width_record.IPAD_Width__c;


        externalLink = theArticle[0].BW_ExternalLinkURL__c;
        extrnalURL = theArticle[0].BW_External_URL__c;

        if(String.isNotBlank(externalLink))
        {
            this.relatedLinksLable = 'Related Links:';
            relatedLinks += '<a href="'+externalLink+'">'+externalLink+'<a><br>';
        }

        if(String.isNotBlank(extrnalURL))
        {

            this.relatedLinksLable = 'Related Links:';
            relatedLinks += extrnalURL;
        }


    }

}