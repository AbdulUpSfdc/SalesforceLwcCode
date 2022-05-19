({
    clickAdd : function(component, event, helper) {
        // Publish LMS messages
        component.find("lmsBWCMsgToLIC").publish({msg: "PostToOpus"});
    }
})