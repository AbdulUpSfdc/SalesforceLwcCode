({
    doInit : function(component, event, helper) {      
        //to-do
    },

    handleRelease :function(component, event, helper) {            
        var isMobileApp = $A.get("$Browser.formFactor") == "DESKTOP" ? false : true; 
        var sendPromise = helper.resendSMS(component, event, helper, isMobileApp);
    },

    handleFlowComplete: function(component, event, helper){
        helper.handleFlowComplete(component, event);
    }
  
})