@isTest
public class CommunitiesSelfRegControllerTest {

    
    public static testmethod void testController() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        pageReference pageref = page.CommunitiesSelfReg;
		Test.setCurrentPage(pageref);
        controller.registerUser();
        
        controller.password = 'Goodpass';
        controller.confirmPassword = 'Badpass';
        controller.registerUser();
        

        
        
    }
}