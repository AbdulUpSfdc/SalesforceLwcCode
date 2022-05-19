({
    createActivity : function(component) {

    let createAction = component.get('c.createInteractionActivity');    
    createAction.setParams({"interactionId": component.get("v.recordId"), "actionName": 'Device | Issues', "detailRecord": JSON.stringify({Info:'Unauthorized Interaction',interactionId: component.get("v.recordId")})});
    createAction.setCallback(this, response => {
        const state = response.getState();
        if(state === "SUCCESS"){
            console.log("Interaction Activity created successfully");
        }
        else if (state === "ERROR") {
            console.log('Error creating record: ' + JSON.stringify(response.getError()));
        }

    });

    $A.enqueueAction(createAction);

},
handleFetch : function(urlData,request,helper,component,closer){
    fetch(urlData.endpoint, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        mode: 'cors', // no-cors, *cors, same-origin
        credentials: "include",
        headers: {
            cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
            credentials: 'include', // include, *same-origin, omit
            'Content-Type': 'application/json'
        },
        body: request
    }).then((response)=> {
        
        window.open(urlData.redirectUrl);
        helper.logAPICallAura(request,response,component);        

    }).catch((error)=>{
    console.error(error);
    }).finally(()=>{
        closer.fire();
    });
} ,
getTSRMConfigs : function(component){
   
    return new Promise($A.getCallback(function(resolve, reject) {
        let createAction = component.get('c.getTSRMMetaData');    
        createAction.setCallback(this, response => {
            const state = response.getState();
            if(state === "SUCCESS"){
                //console.debug(response);
                resolve(response.getReturnValue());
            }
            else if (state === "ERROR") {
                console.debug(response);
                console.log('Error creating record: ' + JSON.stringify(response.getError()));
                reject();
            }
    
        });
    
        $A.enqueueAction(createAction);
    
   
      
    }));
},
getRequest : function(component){
    return new Promise($A.getCallback(function(resolve, reject) {
        let createAction = component.get("c.getTSRMRequest");
        createAction.setParams({
            "ctn": "Unauth",
            "interactionId": component.get("v.recordId"),
            "ban": null
        });

        createAction.setCallback(this, response => {
            const state = response.getState();
            if(state === "SUCCESS"){
                //console.debug(response);
                resolve(response.getReturnValue());
            }
            else if (state === "ERROR") {
                console.debug(response);
                console.log('Error creating record: ' + JSON.stringify(response.getError()));
                reject();
            }
    
        });
    
        $A.enqueueAction(createAction);
    
   
      
    }));
},
logAPICallAura : function(req1,res1,component){

    let resWrapper = {status: res1.status, statusText: res1.statusText };
    let APIcallLoggerAction = component.get("c.logAPICall");
    if(APIcallLoggerAction){
    APIcallLoggerAction.setParams({
        request: req1,
        response: JSON.stringify(resWrapper),
        recordId: component.get("v.recordId")
    });
   
    APIcallLoggerAction.setCallback(this, response => {
        const state = response.getState();
        if(state === "SUCCESS"){
            //console.debug(response);
        }
        else if (state === "ERROR") {
            console.debug(response);
            console.log('Error creating record: ' + JSON.stringify(response.getError()));
        }

    });

    $A.enqueueAction(APIcallLoggerAction);
} 




}
})