({
    doInit : function(component, event, helper) {
       var myPageRef = component.get("v.pageReference");
       var isFromHome = myPageRef.state.c__isFromHome;
       component.set("v.isFromHome", isFromHome);
   }
})