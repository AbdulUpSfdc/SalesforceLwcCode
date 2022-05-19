({
    checkStatus : function(component, event, helper) {
        var message ='';
        var checkinAction = component.get("c.getCheckInStatus");
        checkinAction.setParams({ "recordId" : component.get("v.recordId") });

        checkinAction.setCallback(this, function(response) {
            var state = response.getState();       
            console.log(state);
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                if(data.Status__c != "Arrived") {               
                    message = $A.get("$Label.c.HelpNextCustomerError");  
                    helper.handleToast($A.get("$Label.c.Error"), message, 'error');             
                    component.set("v.isValidStatus", false) ;
                    var dismissAction = $A.get("e.force:closeQuickAction");
                    dismissAction.fire();               
                }else {
                    if(data.Store__c != null){
                        var checkinAction2 = component.get("c.checkIfBusywithCustomer");
                        checkinAction2.setParams({ "recordId" : data.Store__c });
                        checkinAction2.setCallback(this, function(response) {
                            if(response.getState() == 'SUCCESS'){
                                var data1 = response.getReturnValue();
                                if(data1){
                                    message = $A.get("$Label.c.HelpNextCustomerErrorIfBusy");  
                                    helper.handleToast($A.get("$Label.c.Error"), message, 'error');             
                                    component.set("v.isValidStatus", false) ;
                                    var dismissAction = $A.get("e.force:closeQuickAction");
                                    dismissAction.fire();
                                }else {
                                    component.set("v.isValidStatus", true);
                                }
                            } else {
                                var errors = response.getError();
                                if (errors) {
                                    if (errors[0] && errors[0].message) {
                                        // log the error passed in to AuraHandledException
                                        console.log("Error message: " + errors[0].message);
                                        helper.handleToast($A.get("$Label.c.Error"), errors[0].message, "error");
                                        var dismissAction = $A.get("e.force:closeQuickAction");
                                        dismissAction.fire();
                                    }
                                }
                            }

                        });
                        $A.enqueueAction(checkinAction2);
                    }else {
                        component.set("v.isValidStatus", true);
                    }    
                }
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + errors[0].message);
                        helper.handleToast($A.get("$Label.c.Error"), errors[0].message, "error");
                        var dismissAction = $A.get("e.force:closeQuickAction");
                        dismissAction.fire();
                    }
                }
            }
        });
        $A.enqueueAction(checkinAction);
    },

    handleSubmit : function(component, event, helper) {
        var type = event.getParam("type");
        var msg = event.getParam("message");
        var status = event.getParam("status");
        helper.handleToast(status, msg, type);
        helper.handleClose(component, event, helper);
        },

    handleToast : function(title, message, type) {
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            sforce.one.showToast({
                "title": title,
                "message": message,
                "type": type
            });
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": title,
                "message": message,
                "type": type
            });
            toastEvent.fire();
        }
    },
    
    handleClose : function(component, event, helper) {
        var recId = component.get("v.recordId");     
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            sforce.one.navigateToSObject(recId, "detail");
        } else {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recId,
                "slideDevName": "detail"
            });
            navEvt.fire();
            $A.get("e.force:refreshView").fire();
        }
    }

})