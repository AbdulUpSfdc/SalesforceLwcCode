({
    /*
        Initialize on first render.
    */
    init: function (component, event, helper) {
        if (!component.get("v.isRendered")) {
            component.set("v.isRendered", true);

            // Get the button definitions from the modal body component
            const headerRichText = component.get("v.modalBody").getElement().getHeaderRichText();
            component.set("v.headerRichText", headerRichText);
        }
    }
});