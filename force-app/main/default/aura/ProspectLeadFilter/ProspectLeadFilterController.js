({
    init : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        if(pageReference!=null){
            //generate Lead List
            helper.getLeadListNames(component,event,helper);
            //Set values from pagereference values
            helper.setPageReferenceValues(pageReference,component,event,helper);
            //Generate dynamic picklist values
            helper.getPicklistValuesFromController(component,event,helper);
            //Get Max Proximity
            helper.getMaxProximity(component,event,helper);
        }
        helper.getTooltip(component,event,helper);
    },

    applyFilter : function(component,event,helper){
        //check proximity validation
        helper.validateFilters(component,event,helper);
        if(!component.get("v.isError")){
            //reset StrFilterOperatorDisplay
            helper.resetStrFilterOperatorDisplay(component,event,helper);
            //Set filter option
            helper.setFilterOptions(component,event,helper);
            helper.setStrListFilterOptions(component,event,helper);   
            // Create Default Operator Map to get firld name -->operator
            helper.createMapOfDefaultOperators(component,event,helper);
            // Generate the filter string to display on the results header
            helper.deserializeJSONFilters(component,event,helper);
            //Navigate To Result  page
            helper.navigateToResultPage(component,event,helper);
        }
    },

    handleApplicationEvent : function(component, event,helper) {
        // Send default filter values to the controller to fetch results
        helper.sendDefaultsToController(component, event,helper);
    },
    goToProspectPage :function(component,evt,helper){
       // helper.navigateToResultPage(component,evt,helper);
       component.set("v.LeadListName", component.get("v.LeadListName"));
        window.history.back();
    },
    clearAllFilterValues:function(component,evt,helper){
        helper.clearAllFilterValues(component,evt,helper);
    },
    handleStoreChange : function(component,evt,helper){
        console.log("inside change");
        var action  = component.get("c.getStore");
        action.setParam("strStoreId",component.get("v.lead.Store__c"));
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state=="SUCCESS"){
                var respObj = response.getReturnValue();
                if(respObj != null)
                    component.set("v.storeName",respObj.Name);
            }
        });
        $A.enqueueAction(action);
    },
    handlePageReferenceChange : function(component, event, helper){
        var pageReference = component.get("v.pageReference");
        //generate Lead List
        helper.getLeadListNames(component,event,helper);
    	helper.setPageReferenceValues(pageReference,component,event,helper);
        
        
    }
})