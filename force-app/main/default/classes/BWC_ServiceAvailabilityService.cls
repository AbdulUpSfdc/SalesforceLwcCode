public inherited sharing class BWC_ServiceAvailabilityService {

    //Availability Status
    private static String  MDU_STATUS = 'MDU';
    private static String  CLOSEMATCH_STATUS = 'CLOSEMATCH';
    private static String  NOMATCH_STATUS = 'NOMATCH';

    //Service Availability Mode
    private static String FULL_ADDRESS_MODE = 'fullAddress';

    //Customer type
    private static String CONSUMER_CUSTOMER_TYPE = 'consumer';

    /*
        Implements GetServiceAvailability, can be called synchronously or async.
    */
    public class GetServiceAvailabilityService extends BWC_InteractionServiceBase {

        // Request and Response state
        public BWC_ServiceAvailability.ServiceAvailabilityRequest request;
        public BWC_ServiceAvailability.ServiceAvailabilityResponse response;
        public Map<String, Object> updatedAddress;

        /*
            Construct the service object from caller arguments.
        */
        public GetServiceAvailabilityService(Id interactionId, Map<String, Object> updatedAddress) {

            super(interactionId, null);
            this.updatedAddress = updatedAddress;
            this.buildRequest();

        }

        public void buildRequest() {

            this.request = new BWC_ServiceAvailability.ServiceAvailabilityRequest();
            String addressId;

            if (this.updatedAddress == null) {
                Id banId = [SELECT ID, Billing_Account__c FROM Interaction__c WHERE Id=:this.interactionId].Billing_Account__c;

                Billing_Account__c ban = [SELECT
                                            Id,
                                            Billing_Address_Line_1__c,
                                            Billing_City__c,
                                            Billing_State__c,
                                            Billing_Zipcode__c,
                                            Customer_Type__c,
                                            Service_Address_Line_1__c,
                                            Service_City__c,
                                            Service_State__c,
                                            Service_Zipcode__c
                                        FROM Billing_Account__c
                                        WHERE Id=:banId];

                if(!String.isBlank(ban.Service_Address_Line_1__c)){
                    this.request.addressLine1 = ban.Service_Address_Line_1__c;
                    if(!String.isBlank(ban.Service_City__c)) this.request.city = ban.Service_City__c;
                    if(!String.isBlank(ban.Service_State__c)) this.request.state = ban.Service_State__c;
                    if(!String.isBlank(ban.Service_Zipcode__c)){
                        String zipCode =ban.Service_Zipcode__c;
                        Integer index = zipCode.indexOf('-');
                        String zip = index > 0 ? zipCode.substring(0, index) : zipCode;
                        this.request.zip = zip;
                    }
                }else if(!String.isBlank(ban.Billing_Address_Line_1__c)){
                    this.request.addressLine1 = ban.Billing_Address_Line_1__c;
                    if(!String.isBlank(ban.Billing_City__c)) this.request.city = ban.Billing_City__c;
                    if(!String.isBlank(ban.Billing_State__c)) this.request.state = ban.Billing_State__c;
                    if(!String.isBlank(ban.Billing_Zipcode__c)){
                        String zipCode =ban.Billing_Zipcode__c;
                        Integer index = zipCode.indexOf('-');
                        String zip = index > 0 ? zipCode.substring(0, index) : zipCode;
                        this.request.zip = zip;
                    }
                }

                this.request.customertype = CONSUMER_CUSTOMER_TYPE;
                this.request.mode = FULL_ADDRESS_MODE;
                this.request.addressLine2 = ''; //Empty for now as Service Address line 2 is not being populated

            } else {

                String aptUnitNumber = (String) this.updatedAddress.get('aptUnitNumber');
                addressId = (String) this.updatedAddress.get('addressId');

                this.request.addressLine1 = (String) this.updatedAddress.get('addressLine1');
                this.request.unitNumber1 = String.isBlank(aptUnitNumber) ? null : aptUnitNumber;
                this.request.city = (String) this.updatedAddress.get('city');
                this.request.state = (String) this.updatedAddress.get('state');
                this.request.zip = (String) this.updatedAddress.get('zip');
                this.request.customertype = CONSUMER_CUSTOMER_TYPE;
                this.request.mode = FULL_ADDRESS_MODE;
                this.request.addressLine2 = ''; //Empty for now as Service Address line 2 is not being populated

            }

            if(String.isNotBlank(addressId)){
                // When searching using addressId, we perform a GET request
                this.callout = new BWC_ServiceAvailabilityCallout.GetServiceAvailabilityByAddressIdCallout(addressId);
            }else{
                // When searching using a fullAddress, we perform a POST request
                this.callout = new BWC_ServiceAvailabilityCallout.GetServiceAvailabilityCallout(this.request);
            }

        }

        /*
            Builds and returns final response.
        */
        public override Object buildResponse() {

            BWC_ServiceAvailability.ServiceAvailabilityResponses response = (BWC_ServiceAvailability.ServiceAvailabilityResponses)this.callout.getResponse();
            this.response = response.response;
            return this.response;

        }

        public String getServiceAvailabilityMtd(){
            List<BWC_Layout_Fields__mdt> records = [SELECT
                                                        Type__c,
                                                        FieldName__c,
                                                        DisplayName__c,
                                                        Existing_Service_FieldName__c,
                                                        DisplaySequence__c
                                                    FROM BWC_Layout_Fields__mdt
                                                    WHERE Layout_Name__c = 'Service Availability'
                                                    WITH SECURITY_ENFORCED
                                                    ORDER BY DisplaySequence__c ASC];
    
            return JSON.serialize(records);
        }

    }
}