({
    getLeadList : function(component,event,helper) {
        var action = component.get("c.getLeadListPickListValues");
        action.setCallback(this,function(response){
            var state=response.getState();
            if(state=="SUCCESS"){
                component.set("v.LeadListName",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    fireEventToInvokeFilter:function(component,event,helper){
         // Get values from onclick event to get the list name clicked
         var eventSource = event.getSource();
         var eventSourceValue = event.getSource().get("v.label");
         //Fire App Event
         var appEvent = $A.get("e.c:ProspectLeadDefaultFilter");
         appEvent.setParams({
             "SelectedLeadListName" : eventSourceValue,
             "LeadListName" : component.get("v.LeadListName"),
             "render" :true
          });
         appEvent.fire();
    }
    
})