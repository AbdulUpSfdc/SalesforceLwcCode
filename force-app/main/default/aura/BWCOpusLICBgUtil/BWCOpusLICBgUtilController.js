({
    doInit: function(cmp) {
        // Set the attribute value. 
        // You could also fire an event here instead.
        var action = cmp.get("c.getInitDetails");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let opusvar = response.getReturnValue();
                console.log("From server: " + response.getReturnValue());
                cmp.set("v.globalParam", opusvar); 
                console.log('value of URL :'+opusvar['PageURL']);
            }
        });
        $A.enqueueAction(action);
    },
    onTabCreated: function(cmp,event, helper) { 
        var workspace = cmp.find("workspace"); 
        var focustabId = event.getParam('tabId');
        var globalParam = cmp.get("v.globalParam");
        var tabMap = cmp.get("v.tabHolder");
        if(tabMap == undefined){
            tabMap = new Map();
        }
        console.log('focustabId :'+focustabId);
        console.log('ObjectName :'+globalParam['ObjectName']);
        workspace.getTabInfo({
            tabId: focustabId
        }).then(function(response) {
            let myurl = response.url;
            let objToTrack = globalParam['ObjectName'];
            let objToTrackIndx = myurl.search(objToTrack);
            if(objToTrackIndx > 0){
                //helper.closeExistingTab();
                let url = globalParam['PageURL'] + '?Id=' + response.recordId;
                var winRef = window.open(url, globalParam['WindowName'], "width=1920,height=1080");
                console.log('waiting for ready message');
                cmp.set("v.windowHandle",winRef);
                winRef.addEventListener("message",function(){
                    console.log('Received ready message ');
                });
            }
        });
             
    },
    myAction : function(component, event, helper) {

    }
})