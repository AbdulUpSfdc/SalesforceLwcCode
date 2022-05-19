/*
    Abstract base class used for service objects that implement an Apex service that calls one or more callouts.
*/
public inherited sharing abstract class BWC_AsyncServiceBase {

    public BWC_Callout callout;

    /*
        Make the API callout synchronously.
    */
    public virtual Object call() {
        if (this.callout != null) {
            this.callout.makeCallout();
        }
        return this.getResponse();
    }

    /*
        Make the API callout asynchronously.
    */        
    public virtual Object callWithContinuation() {
        return callWithContinuation(this);
    }
    
    /*
        Make the API callout asynchronously, pass in state.
    */        
    public virtual Object callWithContinuation(Object state) {
        if (this.callout != null) {
            this.callout.makeCalloutWithContinuation(state != null ? state : this);
        }
        return this.getResponse();
    }
    
    /*
        Process the Continuation response.
    */
    public virtual Object processContinuationResponse() {
        if (this.callout != null) {
            this.callout.processContinuationResponse();
        }
        return this.getResponse();
    }

    /*
        Returns API response OR Continuation.
    */
    protected virtual Object getResponse() {

        if (this.callout != null && this.callout.continuation != null) {
            // It's a continuation, just return that
            return this.callout.continuation;
        }

        return this.buildResponse();

    }
    
    /*
        Derived class must implement this to build the final service response from the callout results.
    */
    protected abstract Object buildResponse();

}