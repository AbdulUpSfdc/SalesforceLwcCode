({
	init : function(component, event, helper) {
        const pageReference = component.get("v.pageReference");
        if(pageReference){
            component.set("v.recId", pageReference.state.c__recordId);
        }
        
		const workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo()
        .then(response=>{
            for(let i=0; i<response.length; i++){
                if(response[i].pageReference.attributes && 
                        response[i].pageReference.attributes.componentName === "c__BWCDirectoryToolPage"
                        ){
                            const focusedTabId = response[i].tabId;
                            workspaceAPI.setTabLabel({
                                tabId: focusedTabId,
                                label: "Directory Tool"
                            });
                            workspaceAPI.setTabIcon({
                                tabId: focusedTabId,
                                icon: "action:",
                                iconAlt: "Directory Tool"
                            });
                            
                        }
            }
        })
        .catch(error=>{
                console.error(error);
        });
	}
})