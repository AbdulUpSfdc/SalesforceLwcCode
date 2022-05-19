({
     getUserAccess : function(component, event, helper) {
        var action = component.get("c.hasRecordAccess");
        action.setParams({
            title:$A.get("$Label.c.BWC_RSA_Token_Title")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.setFocusedTabLabel(component, event, helper);
            }
            else {
                helper.showToast();
            }
        });
        $A.enqueueAction(action);
    } ,
    
    setFocusedTabLabel : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        
        workspaceAPI.getAllTabInfo()
        .then(response=>{
            for(var i=0; i<response.length; i++){
            console.log('resp--' +JSON.stringify((response[i]) ));
            if(response[i].pageReference.attributes && 
            response[i].pageReference.attributes.apiName == "Request_Token_Authentication_Code"
            ){
            var focusedTabId = response[i].tabId;
            workspaceAPI.setTabLabel({
            tabId: focusedTabId,
            label: "Request Authentication Code"
        });
        workspaceAPI.setTabIcon({
            tabId: focusedTabId,
            icon: "action:",
            iconAlt: "Request Authentication Code"
        });
        
    }
}
 })
.catch(error=>{
    console.error(error);
});
},
    
    showToast : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Access Error',
            message:$A.get("$Label.c.BWC_RSA_Access_Error_Message"),
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    
     closetab: function(component, event, helper)
    {
            sforce.console.getEnclosingTabId( //getEnclosingTabId will return you the Id of closing tab
            $A.getCallback(function(result){
            sforce.console.closeTab(result.Id);
            })
        );
    }
})