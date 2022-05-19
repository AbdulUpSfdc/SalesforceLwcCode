({
    doInit: function (component, event, helper) {
        let action = component.get("c.checkAdjustmentApprovalPerm");
        action.setParams({
            workItemId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var returnMsg = JSON.parse(response.getReturnValue());

                // User has permission
                if (returnMsg === "authorized") {
                    component.set("v.hasPermission", true);
                } else if (returnMsg === "unauthorized") {
                    // User is not authorized
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Warning",
                        type: "Warning",
                        mode: "sticky",
                        message: $A.get("$Label.c.ApproveAdjustmentUnauthorizedMsg")
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else if (returnMsg === "insufficientSOA") {
                    // Insufficient SOA
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Warning",
                        type: "Warning",
                        mode: "sticky",
                        message: $A.get("$Label.c.ApproveAdjustmentSOAerrorMsg")
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        });
        $A.enqueueAction(action);
    },

    handleModalClose: function (cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();
    }
});