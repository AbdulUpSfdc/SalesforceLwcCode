({
    handleSubmit : function(component, event, helper) {
        var recId = component.get("v.recordId");     
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            sforce.one.navigateToSObject(recId, "detail");
        }
        else
        {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
            "recordId": recId,
            "slideDevName": "detail"
            });
            navEvt.fire();
            $A.get("e.force:refreshView").fire();
        }
    },
    
    handleCancel : function(component, event, helper) {
        var recId = component.get("v.recordId");     
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            sforce.one.navigateToSObject(recId, "detail");
        }
        else
        {
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