/**
 * A basic pub-sub mechanism for sibling component communication
 *
 * TODO - adopt standard flexipage sibling communication mechanism when it's available.
 */

const events = {};

// this method checks if the event is raisedin the same page
const samePageRef = (pageRef1, pageRef2) => {
    const obj1 = pageRef1.attributes;
    const obj2 = pageRef2.attributes;
    return Object.keys(obj1)
        .concat(Object.keys(obj2))
        .every(key => {
            return obj1[key] === obj2[key];
        });
};

/**
 * Registers a callback for an event
 * @param {string} eventName - Name of the event to listen for.
 * @param {function} callback - Function to invoke when said event is fired.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const bwcPubSubRegisterListener = (eventName, callback, thisArg) => {
    // Checking that the listener has a pageRef property. We rely on that property for filtering purpose in fireEvent()
    if (!thisArg.pageRef) {
        throw new Error(
            'pubsub listeners need a "@wire(CurrentPageReference) pageRef" property',
        );
    }

    // If event is being registered for the first time, create the listener array.
    if (!events[eventName]) {
        events[eventName] = [];
    }
    // check that the listener is not already subscribed
    const duplicate = events[eventName].find(listener => {
        return listener.callback === callback && listener.thisArg === thisArg;
    });

    // Not a duplicate request, so store the listener
    if (!duplicate) {
        events[eventName].push({ callback, thisArg });
    }
};

/**
 * Unregisters a callback for an event
 * @param {string} eventName - Name of the event to unregister from.
 * @param {function} callback - Function to unregister.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const bwcPubSubUnregisterListener = (eventName, callback, thisArg) => {
    // if listener exists remove it
    if (events[eventName]) {
        events[eventName] = events[eventName].filter(
            listener =>
                listener.callback !== callback || listener.thisArg !== thisArg,
        );
    }
};

/**
 * Unregisters all event listeners bound to an object.
 * @param {object} thisArg - All the callbacks bound to this object will be removed.
 */
const bwcPubSubUnregisterAllListeners = thisArg => {
    // Unregisters all events registered by a listener
    Object.keys(events).forEach(eventName => {
        events[eventName] = events[eventName].filter(
            listener => listener.thisArg !== thisArg,
        );
    });
};

/**
 * Fires an event to listeners.
 * @param {object} pageRef - Reference of the page that represents the event scope.
 * @param {string} eventName - Name of the event to fire.
 * @param {*} payload - Payload of the event to fire.
 */
const bwcPubSubFireEvent = (pageRef, eventName, payload) => {
    // event is raised, so find all the listeners of the event and invoke their callback.
    console.log('in fireevent:' + eventName);
    if (events[eventName]) {
        console.log('found fireevent:' + eventName);
        const listeners = events[eventName];
        listeners.forEach(listener => {
            console.log('checking pageref');
           // if (samePageRef(pageRef, listener.thisArg.pageRef)) {
                console.log('same page ref');
                try {
                    listener.callback.call(listener.thisArg, payload);
                    console.log('done calling subscriber');
                } catch (error) {
                    // fail silently
                    console.log('error calling subscriber:' + error);
                }
           // }
        });
    }
};

export {
    bwcPubSubRegisterListener,
    bwcPubSubUnregisterListener,
    bwcPubSubUnregisterAllListeners,
    bwcPubSubFireEvent,
};