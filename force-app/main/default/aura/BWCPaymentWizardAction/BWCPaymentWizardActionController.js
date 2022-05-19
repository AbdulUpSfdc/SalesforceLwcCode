({
    init: function(component, event, helper) {

        // Only do on first render
        if (component.get('v.isRendered')) {
            return;
        }
        component.set('v.isRendered', true);

        // Prepare message to open subtab
        const message = {
            pageReference: {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__BWCPaymentWizardPage'
                },
                state: {
                    c__recordId: component.get("v.recordId")
                }                
            },
            label: 'Make a Payment',
            icon: 'custom:custom41'
        };

        // Send the message
        component.find('openSubTabMC').publish(message);

    }
})