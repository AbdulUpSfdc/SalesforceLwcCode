({
    checkStatus : function(component, event, helper) {
        var message ='';
        var checkinAction = component.get("c.getCheckInStatus");
        checkinAction.setParams({ "recordId" : component.get("v.recordId") });

        checkinAction.setCallback(this, function(response) {
            var state = response.getState();       
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                if(data.Status__c != "Engaged") {  
                    message = $A.get("$Label.c.FinishCustomerError");
                    helper.handleToast($A.get("$Label.c.Error"), message, 'error');             
                    component.set("v.isValidStatus", false) ;
                    var dismissAction = $A.get("e.force:closeQuickAction");
                    dismissAction.fire();               
                } else {
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
        $A.enqueueAction(checkinAction);
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

    handleSubmit : function(component, event, helper) {
        var result = event.getParam("result");
        helper.handleToast(result.status, result.message, result.type);
        helper.redirectToHome(component, event, helper);
    },

    redirectToHome : function (component, event, helper){
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            sforce.one.navigateToURL("/lightning/n/Retail_Home_Page",true);
        } else {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": "/lightning/n/Retail_Home_Page"
            });
            urlEvent.fire();
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
    },

    handleStatusEngaged : function(component, event, helper) {
        var message = $A.get("$Label.c.FinishCustomerError");
        helper.handleToast($A.get("$Label.c.Error"), message, 'error');
        var dismissAction = $A.get("e.force:closeQuickAction");
        dismissAction.fire();
    }


})