public with sharing class BWC_Service {

    /*
        Base class for a serializable service response.
    */
    public abstract class ServiceResponse {

        /*
            Serialize.
        */
        public String serialize() {

            // Serialize current value to string
            return JSON.serialize(this, true);

        }

    }

}