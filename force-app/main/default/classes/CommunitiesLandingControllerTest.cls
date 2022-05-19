@isTest
public class CommunitiesLandingControllerTest {

    public static testmethod void testController() {
        CommunitiesLandingController controller = new CommunitiesLandingController();
        pageReference pageref = page.CommunitiesLanding;
		Test.setCurrentPage(pageref);
        controller.forwardToStartPage();
        
    }
    
}