@IsTest
public class CustomLabelTranslatorControllerTest {

    private static CustomLabelTranslatorController controllerFactory() {
        Test.setCurrentPage( Page.CustomLabelsTranslator );
        Map<String,String> params = ApexPages.currentPage().getParameters();

        params.put( 'labelsCsv', 'label1,label2' );

        CustomLabelTranslatorController ctrlr = new CustomLabelTranslatorController();

        return ctrlr;
    }

    @IsTest
    public static void testConstructor() {
        
        Test.startTest();
        CustomLabelTranslatorController ctrlr = controllerFactory();
        Test.stopTest();

        Integer totLabels = ctrlr.labels.size();
        System.assert( totLabels == 2, 'Expect 2 labels... Got ' + totLabels );
    }

    @IsTest
    public static void testGetLexOrigin() {
        CustomLabelTranslatorController ctrlr = controllerFactory();

        Test.startTest();
        String origin = ctrlr.getLexOrigin();
        Test.stopTest();

        System.debug( '--->>> lex origin [' + origin + ']' );

        System.assert( 
            !String.isBlank( origin ) && origin.endsWith( '.lightning.force.com' ),
            'Error getting LEX origin'
        );
    }

    @IsTest
    public static void testUserType() {
        Test.startTest();
        String ut = CustomLabelTranslatorController.userType();
        Test.stopTest();

        System.debug( '--->>> user type [' + ut + ']' );

        System.assert( 
            !String.isBlank( ut ),
            'User Type cannot be blank!'
        );
    }

    @IsTest
    public static void testVisualforceOrigin() {
        Test.startTest();
        String origin = CustomLabelTranslatorController.visualforceOrigin();
        Test.stopTest();

        System.assert( 
            !String.isBlank( origin ) && origin.endsWith( '--c.visualforce.com' ),
            'Expected visualforce domain... Got [' + origin + ']'
        );
    }

    @IsTest
    public static void testGetHost() {
        Test.startTest();
        String host = CustomLabelTranslatorController.getHost();
        Test.stopTest();

        System.assert( !String.isBlank( host ), 'Expected not blank host' );
    }
}