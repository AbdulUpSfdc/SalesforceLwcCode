public with sharing class SyncCaseWithProducts implements Queueable, Database.AllowsCallouts{
    ID caseId;
    String ban;
    public SyncCaseWithProducts() {}

    public SyncCaseWithProducts(ID caseId, String ban){
        this.caseId = caseId;
        this.ban = ban;
    }
    public void execute(QueueableContext context){
        
        if(caseId!=null && String.isNotBlank(ban)){
            Case currentCase  = fetchCase(caseId);
            if(currentCase!=null && currentCase.AccountId!=null){
                //String products = getProductsFromPlan(currentCase.AccountId, ban);
                getProductsFromPlan(currentCase, ban);

                if(String.isNotBlank(currentCase.Product__c)
                    || String.isNotBlank(currentCase.PlanName__c)){
                    //currentCase.Product__c = products;
                    updateCase(currentCase);        
                }
            }
        }
    }

    private void updateCase(Case currentCase){
        try {
            update currentCase;    
        } catch(Exception ex) {
            BWC_ExceptionUtils.handleException(ex, true);
        }
    }
    private Case fetchCase(ID caseId){
        List<Case> caseList = [Select AccountId,PlanName__c,Product__c From Case Where ID = :caseId];
        if(caseList.size()>0){
            return caseList[0];    
        }
        return null;
    }// method ends...
    
    private void getProductsFromPlan(Case currentCase, String ban){
        String products;
        String personAccountId = currentCase.AccountId;
        if(String.isNotBlank(personAccountId)){
            List<BWC_ProductSearchService.ServiceModel> serviceModel_List = new List<BWC_ProductSearchService.ServiceModel>();
            Set<String> planId_Set = new Set<String>();
            serviceModel_List = BWC_ProductSearchService.getProductsGroupedByService(currentCase.Id);

            for(BWC_ProductSearchService.ServiceModel model : serviceModel_List){
                system.debug('model==>'+model);
            }
            
            if(serviceModel_List!=null && serviceModel_List.size()>0){
                for(BWC_ProductSearchService.ServiceModel serviceModel : serviceModel_List){
                    if(serviceModel.plans!=null && serviceModel.plans.size()>0){
                        for(Plan__c plan : serviceModel.plans){
                            if(String.isNotBlank(String.valueOf(plan.Id)) && String.isNotBlank(plan.Ban__c) && plan.Ban__c.equalsIgnoreCase(ban)){
                                planId_Set.add(plan.Id);    
                            }
                        }// inner for ends...        
                    }        
                }//outer for ends...    
                if(planId_Set.size()>0){
                    fetchPlans(planId_Set, currentCase);   
                }
            }
        } 
 
        
        //return products;
    }//method ends..

    private void fetchPlans(Set<String> planId_Set, Case currentCase){
        String products;
        //String planName;
        system.debug('MetadataSelector.productValueSet==>'+ MetadataSelector.productValueSet);
        for(Plan__c plan : [Select Plan_Name__c,Product__c, Billing_Account__r.Account_Type__c,Transport_Type__c From Plan__c Where ID IN :planId_Set]){
            //if(String.isNotBlank(plan.Product__c) && MetadataSelector.productValueSet.contains(plan.Product__c.toLowerCase())){
            if(String.isNotBlank(plan.Product__c)){
                if(String.isNotBlank(products) 
                    && MetadataSelector.productToCgProduct_Map.containsKey(plan.Product__c)){
                    products = products+';'+ MetadataSelector.productToCgProduct_Map.get(plan.Product__c);
                    system.debug('products - Lingeh'+products);
                }
                else{
                    //system.debug('productToCgProduct_Map --- 777'+ productToCgProduct_Map);
                    system.debug('Plan Name Lingesh'+ plan.Product__c.toLowerCase());
                    if(MetadataSelector.productToCgProduct_Map!=null 
                        && MetadataSelector.productToCgProduct_Map.size()>0 
                        && MetadataSelector.productToCgProduct_Map.containsKey(plan.Product__c)
                        && String.isNotBlank(MetadataSelector.productToCgProduct_Map.get(plan.Product__c))){
                            products = MetadataSelector.productToCgProduct_Map.get(plan.Product__c);
                                        
                    }
                }
                //AT&T - Uverse Internet
                if(String.isBlank(currentCase.PlanName__c) 
                    && plan.Product__c==Label.AttInternet 
                    && plan.Billing_Account__r.Account_Type__c=='uverse'){
                    currentCase.PlanName__c = plan.Plan_Name__c;
                    currentCase.TransportType__c = plan.Transport_Type__c;
                }
            }
                
               
        }//for ends...
        if(String.isNotBlank(products)){
            currentCase.Product__c = products;
        }
        //return products;
    }// 
}