({
    init : function(component, event, helper) {
        helper.getLeadList(component, event, helper);
    },
    handleListNameClick:function(component,event,helper){
        helper.fireEventToInvokeFilter(component,event,helper);
    },
    onPageReferenceChange : function(component,event,helper){
        $A.get('e.force:refreshView').fire();
    }
})