({
    doInit: function (component, event, helper) {
        let action = component.get("c.checkRecordEditability");
        action.setParams({
            workItemId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let permission = JSON.parse(response.getReturnValue());

                // Set permission on UI
                component.set("v.hasPermission", permission);

                // If user does not have permission, show error message
                if (!permission) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Warning",
                        type: "Warning",
                        mode: "sticky",
                        message: $A.get("$Label.c.ReturnBackUnauthorizedMsg")
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