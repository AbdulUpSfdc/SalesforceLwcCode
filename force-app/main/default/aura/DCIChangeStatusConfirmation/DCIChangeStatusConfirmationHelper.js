({
    validateStatus : function(component, event, helper) {
        var validateStatusAction = component.get("c.validateStatus");
        validateStatusAction.setParams({ "recordId" : component.get("v.recordId"), "action" : component.get("v.actionType")});

        validateStatusAction.setCallback(this, function(response) {
            var state = response.getState();       
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                var isValid = data.isValid;
                if(isValid) {
                    component.set("v.isValidStatus", true);
                } else {
                    helper.handleToast($A.get("$Label.c.Error"), data.errorMessage, "error");
                    helper.closeAction();
                }
            } else {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + errors[0].message);
                        helper.handleToast($A.get("$Label.c.Error"), errors[0].message, "error");
                    }
                }
                helper.closeAction(component, event, helper);
            }
        });

        $A.enqueueAction(validateStatusAction);
    },

    handleSubmit : function(component, event, helper) {
        var type = event.getParam("type");
        var msg = event.getParam("message");
        var status = event.getParam("status");
        helper.handleToast(status, msg, type);
        helper.closeAction();
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

    closeAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
        var closeActionEvent = $A.get("e.c:CloseQA");
        closeActionEvent.fire();
    }
})