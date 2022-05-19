({
    showPopupBlockToast : function(msg) {
        var toastEvent = $A.get("e.force:showToast");
        console.log('show toast :');
        toastEvent.setParams({
            mode: 'dismissible',
            type : 'warning',
            message: 'Please disable your pop-up blocker and retry',
        });
        toastEvent.fire();
    }
})