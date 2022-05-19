({
    /*
        Perform console API action on behalf of an LWC component.
    */
    handleConsoleApi: function (component, event, helper) {

        // Check for matching page URL, to avoid multiple listeners responding to console subtabs
        if (event.getParam("pageUrl") !== window.location.href) {
            return;
        }

        try {
            const methodName = event.getParam("methodName");
            const args = event.getParam("arguments");
            switch (methodName) {
                case "openSubtab":
                    helper.consoleOpenSubtab(component, args);
                    break;

                case "closeFocusedTab":
                    helper.consoleCloseFocusedTab(component, args);
                    break;

                default:
                    throw new Error("Unhandled console API method: " + methodName);
            }
        } catch (error) {
            console.error(error.message);
        }
    },

    /*
        Received a message to open a modal.
    */
    handleShowModalMessage: function (component, event, helper) {

        // Check for matching page URL, to avoid multiple listeners responding to console subtabs
        if (event.getParam("pageUrl") !== window.location.href) {
            return;
        }

        // This is the name of the custom component that implements the modal body and also provides information about header text and footer buttons.
        const bodyComponentName = event.getParam("bodyComponentName");

        // Component definitions
        const componentDefs = [
            ["c:BWCModalHeader", {}], // Data driven header
            [bodyComponentName, event.getParam("bodyComponentArguments")], // Custom body component
            ["c:BWCModalFooter", {}] // Data driven footer
        ];

        // Create the components
        $A.createComponents(componentDefs, function (components, status, errorMessages) {
            switch (status) {
                case "SUCCESS":
                    // Components are created
                    const header = components[0];
                    const body = components[1];
                    const footer = components[2];

                    // Reference to successfully opened modal
                    let openModal;

                    // Add listeners to custom modal body to allow it to tell us when to modify header and footer, or close
                    body.set("v.onupdateheaderrichtext", function (headerEvent) {
                        helper.setModalHeaderRichText(header, headerEvent);
                    });
                    body.set("v.onupdatebuttons", function (footerEvent) {
                        helper.setModalFooterButtons(footer, footerEvent);
                    });
                    body.set(
                        "v.onclose",
                        $A.getCallback(function (closeEvent) {
                            helper.closeModal(component, closeEvent, openModal, bodyComponentName);
                        })
                    );

                    // Link header and footer to body component
                    // It needs this because modalBody is not available to be called until modal is rendered
                    header.set("v.modalBody", body);
                    footer.set("v.modalBody", body);

                    // Show the modal
                    const overlayLibrary = component.find("overlayLibrary");
                    overlayLibrary
                        .showCustomModal({
                            header: header,
                            body: body,
                            footer: footer,
                            cssClass: event.getParam("cssClass"),
                            showCloseButton:
                                event.getParam("showCloseButton") !== undefined
                                    ? event.getParam("showCloseButton")
                                    : true,
                            closeCallback: function () {
                                // Tell the custom body component that modal is being closed.
                                try {
                                    body.getElement().notifyClosed();
                                } catch (error) {
                                    console.warn("Unable to call notifyClosed.");
                                }

                                // Publish response message -- response data is undefined since modal was closed by the X button.
                                component.find("responseChannel").publish({ bodyComponentName });
                            }
                        })
                        .then((newModal) => {
                            // This object reference is used in the close callback to command the modal to close.
                            openModal = newModal;
                        });
                    break;

                default:
                    console.error(
                        `Failed to create modal components: Status = ${status}, errorMessages = ${JSON.stringify(
                            errorMessages
                        )}`
                    );
                    break;
            }
        });
    }
});