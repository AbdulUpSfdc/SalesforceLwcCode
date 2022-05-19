({
    closeExistingTab : function(component){
        const windowhandle = component.get('v.windowHandle');
        if(windowhandle != undefined && windowhandle != null){
            windowhandle.close();
        }
    },
    
    helperMethod : function() {

    }
})