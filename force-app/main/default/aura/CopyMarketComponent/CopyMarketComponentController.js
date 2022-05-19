({
    doInit : function(component, event, helper) {
        var action = component.get("c.copyMarket");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseObj = response.getReturnValue();
                console.log('response: ', responseObj);
                if(responseObj.isSuccess){
                    helper.showToast('success', 'Copy of Market is successful.', 'success');
                }else{
                    helper.showToast('error', responseObj.errorMessage, 'Failed');
                }
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
        });
        $A.enqueueAction(action);
    },
})