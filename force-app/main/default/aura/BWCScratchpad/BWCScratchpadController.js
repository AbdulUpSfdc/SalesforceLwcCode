({
    /*
        Clear clicked.
    */
    handleClear : function(component, event, helper) {

        // Reset text
        component.find('notetext').getElement().value = '';

    },

    /*
        Copy All Text clicked.
    */
    handleCopy : function(component, event, helper) {

        // Get <textarea> element
        const textarea = component.find('notetext').getElement();

        // Retain selection
        const selectionStart = textarea.selectionStart;
        const selectionEnd = textarea.selectionEnd;

        // Select all
        textarea.select();

        // Copy to clipboard
        document.execCommand('copy');

        // Restore selection
        textarea.setSelectionRange(selectionStart, selectionEnd);

    },

    /*
        Reset when interaction is complete.
    */
    onInteractionComplete: function(component) {

        // Reset
        component.find('notetext').getElement().value = '';

        // Minimize
        component.find("utilitybar").minimizeUtility();

    }

})