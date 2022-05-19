public without sharing class BWKMRedirectController 
{

    public static PageReference getkmarticle()
    {

        String redirectId='';
        PageReference redirectpage=ApexPages.currentPage();
        
        redirectId = ApexPages.currentPage().getParameters().get('Id');
        if(redirectId!='')
        {
            try{
                BWKnowledgeRedirect__c rd=[Select Id,Article_Link__c from BWKnowledgeRedirect__c where Id=:redirectId];
                String kmArticlelink=rd.Article_Link__c;
                if(kmArticlelink != null)
                {
                    redirectpage = new pagereference(kmArticlelink);
                    redirectpage.setRedirect(true);
                }
            }
            finally
            {

            }
          
        }
        
        return redirectpage;

    }

}