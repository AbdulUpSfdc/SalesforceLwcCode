({
    
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
    handleMobile : function(component, event, helper) {
        var result = event.getParam("result");
        /* commented for back button on iPad to land on DCI record */
        //var dismissAction = $A.get("e.force:closeQuickAction"); 
        //dismissAction.fire();
        result = encodeURI(result);
        helper.handleOpenInNewWindow(result);
       
    },

    handleDesktop : function(component, event, helper) {
        var dismissAction = $A.get("e.force:closeQuickAction");
        dismissAction.fire();
        helper.handleToast("Error", "This feature is not available on the desktop mode", "Error");
    },

    handleOpenInNewWindow : function(result) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": result
        });
        urlEvent.fire();    
    }

    
})