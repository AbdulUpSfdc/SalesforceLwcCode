({
    createActivity : function(component) {

        let createAction = component.get("c.createInteractionActivity");
        createAction.setParams({"interactionId": component.get("v.recordId"), "actionName": 'Device | Support', "detailRecord": JSON.stringify({Info:'Unauthorized Interaction',interactionId: component.get("v.recordId")})});
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

    }
})