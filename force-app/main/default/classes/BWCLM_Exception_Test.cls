/*
   Test class for class BWCLM_Exception
*/
@isTest
private  class BWCLM_Exception_Test {

    @isTest private static void testConstructor() {
        String myerror= 'error';
        BWCLM_Exception bwclme = new BWCLM_Exception();
        bwclme.BWCLM_Exception(myerror);
    }
    @isTest private static void testConstructor2() {
        String myerror= 'error';
        BWCLM_Exception bwclme1 = new BWCLM_Exception();
        bwclme1.BWCLM_Exception(myerror);
        //this.error = error; 
    }
}