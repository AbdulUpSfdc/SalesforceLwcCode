@IsTest
public class BWC_User_Selector_Test {    
    
    @TestSetup
    static void makeData(){
        BWC_TestDataFactory.createUser();
    }
    
    @IsTest
    static void getEmployeeTest() {
        User testUser = [SELECT Id FROM User WHERE LastName = 'Testing'];
        
        Test.startTest();
        User response = BWC_User_Selector.getUserById(testUser.Id);
        Test.stopTest();
        
        System.assert(response.Name.length()>0);
    }
    
}