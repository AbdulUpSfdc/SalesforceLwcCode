@isTest
public class RetailErrorTest {

    @isTest
    public static void unitTest()
    {
        RetailError newError=new RetailError();
        RetailError.ErrorJsonResponse e=new RetailError.ErrorJsonResponse('500','Internal Server Error');
    }
}