({
    updateStatus : function(component, event) {
        var action = component.get('c.changeRepStatus'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "status" : component.get('v.buttonName') 
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                console.log("Status Changed ");
                component.set("v.message", "Reps Status Changed");
            }
        });
        $A.enqueueAction(action);
    },
    handleNextCustomer : function(component, event) {
        var action = component.get('c.getNextCheckinCustomer'); 
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                console.log('Handle Next Customer');
                console.log(a.getReturnValue());
                var customerInfo = a.getReturnValue();
                component.set("v.message", customerInfo.message);
                if(customerInfo && customerInfo.checkinId){
                    component.find("navigation")
                    .navigate({
                        "type" : "standard__recordPage",
                        "attributes": {
                            "recordId"      : customerInfo.checkinId,
                            "objectApiName" : "RetailCheckinQueue__c",
                            "actionName"    :  "view"   //clone, edit, view
                        }
                    }, true);
                }
            }
        });
        $A.enqueueAction(action);
    }
    ,
    init : function(component, event) {
        var action = component.get('c.getLoggedInRepsDetails'); 
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var repInfo = a.getReturnValue();
                console.log(repInfo);
                if(repInfo){
                    component.set("v.repStore", repInfo.Store__r.Name);
                    component.set("v.repStatus", repInfo.DCIPresenceStatus__c);
                }    
            }
        });
        $A.enqueueAction(action);
    }
})