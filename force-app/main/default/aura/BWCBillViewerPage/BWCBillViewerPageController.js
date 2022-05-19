({
    setBan : function(component, event, helper) {
        component.set("v.ban", component.get("v.pageReference").state.c__ban);
        component.set("v.accountType", component.get("v.pageReference").state.c__accountType);
        component.set("v.interactionId", component.get("v.pageReference").state.c__interactionId);
        component.set("v.defaultStatementId", component.get("v.pageReference").state.c__defaultStatementId);
        component.set("v.caseId", component.get("v.pageReference").state.c__caseId);
    }
})