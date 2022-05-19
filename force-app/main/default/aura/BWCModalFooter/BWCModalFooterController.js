({
    /*
        Initialize on first render.
    */
    init: function (component, event, helper) {
        if (!component.get("v.isRendered")) {
            component.set("v.isRendered", true);

            // Get the button definitions from the modal body component
            const buttons = component.get("v.modalBody").getElement().getFooterButtons();
            component.set("v.buttons", buttons);
        }
    },

    /*
        Generate the lists of buttons for left and right.
    */
    updateButtonLists: function (component, event, helper) {
        let buttons = component.get("v.buttons");
        if (!buttons) {
            buttons = [];
        }

        component.set(
            "v.leftButtons",
            buttons.filter((button) => button.position === "left")
        );
        component.set(
            "v.rightButtons",
            buttons.filter((button) => !button.position || button.position === "right")
        );
    },

    /*
        A footer button was clicked. Will try to call button's handler.
    */
    handleButtonClick: function (component, event, helper) {
        // Find the button
        const button = component.get("v.buttons").find((button) => button.name === event.getSource().get("v.name"));
        if (button.click) {
            // There's a click handler, run it.
            component.set("v.isBusy", true);

            // It might return a promise
            const promise = button.click();

            if (promise && promise.then) {
                // The handler returned a promise, so wait until it's resolved before going to not busy.
                // This way buttons are all disabled while a button click is being processed.
                promise.finally(() => {
                    component.set("v.isBusy", false);
                });
            } else {
                // No promise returned, just unset busy.
                component.set("v.isBusy", false);
            }
        }
    }
});