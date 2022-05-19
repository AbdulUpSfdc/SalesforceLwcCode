({
    getTheUrl: function(component) {
        
		let parentArticleId = component.get("v.recordId");
        let action = component.get("c.getPublicLink");
        action.setParams({'ArticleId': parentArticleId});
        action.setCallback(this, response => {
            
            let state = response.getState();
            let publicURL = response.getReturnValue();
            //if the response is success
            if (state === "SUCCESS") {
            	$A.get("e.force:closeQuickAction").fire();
                let copyText = document.createElement('input');
            	copyText.setAttribute("value", publicURL);
            	document.body.appendChild(copyText);
            	copyText.select();
            	copyText.setSelectionRange(0, 99999)
            	document.execCommand("copy");
            	
            	//alert(" \r\nThis URL has been copied to the clipboard: \r\n  \r\n" + publicURL);
            	  var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    title : 'Success',
                    message: ' \r\nThis URL has been copied to the clipboard: \r\n  \r\n' + publicURL,
                    key: 'info_alt',
                    type: 'success',
                    mode: 'dismissible'
                });
                toastEvent.fire();
            }
            //if the response is error
            else {
                console.log("Failed with state: " + state);
            }
        
        });
        $A.enqueueAction(action);
    }
})