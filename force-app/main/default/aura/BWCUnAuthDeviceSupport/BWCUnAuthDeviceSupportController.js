({
    
    doInit : function(component, event, helper) {
        window.open($A.get("$Label.c.Device_Support_Selector_URL") ,"_blank");
        $A.get("e.force:closeQuickAction").fire();
        helper.createActivity(component);
    },

})