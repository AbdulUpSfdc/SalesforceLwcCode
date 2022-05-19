({
    applyFilter: function(component, evt, helper){
        helper.goToFilterComp(component,event,helper);
    },
    init:function(cmp, evt, helper){
        helper.setPageReferenceValues(cmp, evt, helper);
    },
    onPageReferenceChange : function(cmp,evt,helper){
            $A.get('e.force:refreshView').fire();
    },
    handleLoadMore : function(component,event,helper){
        if(!(component.get("v.currentCount") >= component.get("v.totalRows"))){
            //To display the spinner
            component.set("v.isLoading", true); 
            //To handle data returned from Promise function
            helper.loadData(component); 
        }
        else{
            //To stop loading more rows
            component.set("v.isDisabled",true);
            component.set("v.isLoading", false); 
        }
    },
    gotoProspectPage:function(component,event,helper){
        helper.gotoProspectPage(component,event,helper);
    }
})