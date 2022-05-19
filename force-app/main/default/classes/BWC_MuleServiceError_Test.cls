@isTest
public with sharing class BWC_MuleServiceError_Test {

    @isTest
    private static void test() {

        // Exercise properties
        BWC_MuleServiceError error = new BWC_MuleServiceError();
        error.node = '';
        error.code = 0;
        error.message = '';
        error.description = '';
        error.transactionId = '';
        error.traceId = '';
        error.idpTraceId = '';

    }

}