({
    showOpusWindow : function(component, event, helper) {
        //TODO: use correct url
        let url = $A.get("$Label.c.OPUS_New_Customer_URL");
        let windowName = 'New Customer';
        let height = window.innerHeight;
        let width = window.innerWidth;
        let popheight = height * .9;
        let popwidth = width * .9;

        //Open popUp
        let opusWindow = window.open(url, windowName, `width=${popwidth},height=${popheight}`);
        if(opusWindow.closed || !opusWindow){
            console.error('popup is blocked');
            return
        }
        component.set("v.opusWindow", opusWindow);
    },

    closeOpusWindow : function(component, event, helper) {

        const opusWindow = component.get('v.opusWindow');

        //TODO validate if closing tab is the same as existing tab
        if(opusWindow || !opusWindow.closed){
            opusWindow.close();
        }
    }
})