({
    // Append the newMessage to errorMessage arttribute
    addError : function(component, newMessage) {
        let errorMessage = component.get("v.errorMessage");
        errorMessage = errorMessage + newMessage + '<br />';
        component.set("v.errorMessage", errorMessage);
    },
    
    // Compare page references in order to find if a subtab is already open
    isEqualPageReference: function(newPageRef, existingPageRef) {

        // Compare type
        if (newPageRef.type !== existingPageRef.type) {
            return false;
        }

        if ((newPageRef.attributes && !existingPageRef.attributes) || (!newPageRef.attributes && existingPageRef.attributes)) {
            return false;
        }

        // Compare all attributes specified in the new reference
        if (newPageRef.attributes) {

            for (let propertyName of Object.getOwnPropertyNames(newPageRef.attributes)) {
                if (existingPageRef.attributes[propertyName] !== newPageRef.attributes[propertyName]) {
                    return false;
                }
            }

            for (let propertyName of Object.getOwnPropertyNames(existingPageRef.attributes)) {
                if (existingPageRef.attributes[propertyName] !== newPageRef.attributes[propertyName]) {
                    return false;
                }
            }

        }

        if ((newPageRef.state && !existingPageRef.state) || (!newPageRef.state && existingPageRef.state)) {
            return false;
        }

        // Compare all state specified in the new reference
        if (newPageRef.state) {

            for (let propertyName of Object.getOwnPropertyNames(existingPageRef.state).filter(name => name.startsWith('c__'))) {
                if (existingPageRef.state[propertyName] !== newPageRef.state[propertyName]) {
                    return false;
                }
            }

            for (let propertyName of Object.getOwnPropertyNames(newPageRef.state).filter(name => name.startsWith('c__'))) {
                if (existingPageRef.state[propertyName] !== newPageRef.state[propertyName]) {
                    return false;
                }
            }

        }

        return true;

    }
})