export default class BwcError extends Error {

    constructor() {

        super();
        this.name = 'BwcError';

    }

    /*
        Return the best error from the source errorObject, which might the errorObject itself or a custom BwcError.
    */
    static convertError(errorObject) {

        if (errorObject instanceof Error) {
            return errorObject;
        }

        if (errorObject.body) {

            const error = new BwcError();
            error.message = errorObject.body.message;
            error.stackTrace = errorObject.body.stackTrace;
            if (errorObject.body.exceptionType) {
                error.name = errorObject.body.exceptionType;
            }
            return error;

        }

        return errorObject;

    }

}