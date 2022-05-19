({
    handleCloseEvent: function(cmp, event, helper) {
        let msg = event.getParam('msg');
        let ban = event.getParam('ban');
        let url = event.getParam('url');
        
        if(msg === 'OPEN'){
            var prevWinRef = cmp.get('v.windowHandle');
            if(prevWinRef != undefined && prevWinRef != null && !prevWinRef.closed){
                prevWinRef.close();
                cmp.set("v.windowHandle", null);
            }
            var winRef = window.open(url, ban, "width=1000, height=1000");
            if (!winRef || winRef.closed || typeof winRef == 'undefined' || typeof winRef.closed == 'undefined') {
                helper.showPopupBlockToast();
                return;
            }
            cmp.set("v.windowHandle", winRef);
        } else {
            const content = cmp.get('v.windowHandle');
            if (content != undefined && content != null && !content.closed) {
                content.close();
            }
        }
    }
})