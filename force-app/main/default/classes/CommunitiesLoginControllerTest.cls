@isTest
public class CommunitiesLoginControllerTest {

    public static testmethod void testController() {
        CommunitiesLoginController controller = new CommunitiesLoginController();
        pageReference pageref = page.CommunitiesLogin;
		Test.setCurrentPage(pageref);
        controller.forwardToAuthPage();
        
    }
    
}