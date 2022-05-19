/*
    Unit test coverage for BWC_UserAssociationsCallout.
*/
@isTest
public with sharing class BWC_UserAssociationsCallout_Test {

    @isTest
    private static void test_Wireless() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsMock_wireless', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociationsRequest> request = new List<BWC_UserAssociations.UserAssociationsRequest>{
            new BWC_UserAssociations.UserAssociationsRequest('287245899042', BWC_Constants.BillingAccount_AccountType_Wireless)
        };

        //Get response
        List<BWC_UserAssociations.UserAssociationsResponse> response = BWC_UserAssociationsCallout.getUserAssociations(request);

        System.assertNotEquals(null, response);
        System.assertEquals(1, response.size());
       // System.assertEquals(1, response[0].record.users.size());

    }

    @isTest
    private static void test_Negative_BadBody() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociationsRequest> request = new List<BWC_UserAssociations.UserAssociationsRequest>{
            new BWC_UserAssociations.UserAssociationsRequest('287245899042', BWC_Constants.BillingAccount_AccountType_Wireless)
        };

        //Get response
        try {
            List<BWC_UserAssociations.UserAssociationsResponse> response = BWC_UserAssociationsCallout.getUserAssociations(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }

    }

    @isTest
    private static void test_Negative_MissingRequest() {

        // Setup request
        List<BWC_UserAssociations.UserAssociationsRequest> request = new List<BWC_UserAssociations.UserAssociationsRequest>{
            new BWC_UserAssociations.UserAssociationsRequest('287245899042', BWC_Constants.BillingAccount_AccountType_Wireless)
        };

        //Get response
        try {
            List<BWC_UserAssociations.UserAssociationsResponse> response = BWC_UserAssociationsCallout.getUserAssociations(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (BWC_Exception e) {
            System.assert(true, 'Expected failure due to null request.');
        }

    }

    @isTest
    private static void test_Add_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{};

        //Get response
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.addUserAssociations(request);

        System.assertEquals('SUCCESS', responses[0].result.status);

    }

    @isTest
    private static void test_Add_Negative() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Missing argument
        try {
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.addUserAssociations(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (Bwc_Exception e) {
            System.assert(true, 'Expected failure due to null request.');
        }

        //Get response with bad JSON
        try {
            List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{};
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.addUserAssociations(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }

    }

    @isTest
    private static void test_Delete_Positive() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_UserAssociationsAddDelMock', 200);

        // Setup request
        List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{};

        //Get response
        List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.deleteUserAssociations(request);

        System.assertEquals('SUCCESS', responses[0].result.status);

    }

    @isTest
    private static void test_Delete_Negative() {

        // Setup mock
        BWC_Utils.setStaticResourceMock('BWC_Mock_NotJson', 200);

        // Missing argument
        try {
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.deleteUserAssociations(null);
            System.assert(false, 'Expected exception not thrown.');
        }
        catch (Bwc_Exception e) {
            System.assert(true, 'Expected failure due to null request.');
        }

        //Get response with bad JSON
        try {
            List<BWC_UserAssociations.UserAssociation> request = new List<BWC_UserAssociations.UserAssociation>{};
            List<BWC_UserAssociations.AddDeleteUserAssociationsResponse> responses = BWC_UserAssociationsCallout.deleteUserAssociations(request);
            System.assert(false, 'Excpected exception not thrown.');
        }
        catch (BWC_Exception e) {

            // Cause should be JSON exception
            System.assert(e.getCause() instanceOf System.JSONException);

        }

    }

}