@IsTest
public class BWC_OutboundMessageTest {
  public static final String GOOD_TEMLPATE = 'Redaction_OT_URL';

  private static final String GOOD_SUBJECT = 'Hello {!User.Name}! Test';
  private static final String USER_FIRST_NAME = 'Alex';
  private static final String USER_LAST_NAME = 'd\'LastName';
  private static final String GOOD_SUBJECT_EXPECTED =
    'Hello ' +
    USER_FIRST_NAME +
    ' ' +
    USER_LAST_NAME +
    '! Test';

  private static final String GOOD_BODY = 'Dear Customer, We are testing {!Account.Name}! Hope it works!';
  private static final String ACC_FIRST_NAME = 'John';
  private static final String ACC_LAST_NAME = 'Doe';
  private static final String GOOD_BODY_EXPECTED =
    'Dear Customer, We are testing ' +
    ACC_FIRST_NAME +
    ' ' +
    ACC_LAST_NAME +
    '! Hope it works!';

  private static final String BAD_SOBJ_TEMLPATE = 'BadSObjOutboundMessageTemplate';
  private static final String BAD_SOBJ_SUBJECT = 'Hello {!NoSuchSObject.Name}! Test';
  private static final String BAD_SOBJ_BODY = 'Some body without SObject';

  private static final String BAD_FLD_TEMLPATE = 'BadFldOutboundMessageTemplate';
  private static final String BAD_FLD_SUBJECT = 'Hello {!NOT_SOBJECT}! Test';
  private static final String BAD_FLD_BODY = 'Some body without Sobject and field';

  @TestSetup
  public static void makeData() {
    User usr = BWC_TestDataFactory.createUser();
    usr.FirstName = USER_FIRST_NAME;
    usr.LastName = USER_LAST_NAME;

    System.runAs(usr) {
      List<EmailTemplate> ets = new List<EmailTemplate>{
        new EmailTemplate(
          DeveloperName = GOOD_TEMLPATE,
          Name = GOOD_TEMLPATE,
          Subject = GOOD_SUBJECT,
          HtmlValue = GOOD_BODY,
          Body = GOOD_BODY,
          FolderId = UserInfo.getUserId(),
          TemplateType = 'text'
        ),
        new EmailTemplate(
          DeveloperName = BAD_SOBJ_TEMLPATE,
          Name = BAD_SOBJ_TEMLPATE,
          Subject = BAD_SOBJ_SUBJECT,
          HtmlValue = BAD_SOBJ_BODY,
          Body = BAD_SOBJ_BODY,
          FolderId = UserInfo.getUserId(),
          TemplateType = 'text'
        ),
        new EmailTemplate(
          DeveloperName = BAD_FLD_TEMLPATE,
          Name = BAD_FLD_TEMLPATE,
          Subject = BAD_FLD_SUBJECT,
          HtmlValue = BAD_FLD_BODY,
          Body = BAD_FLD_BODY,
          FolderId = UserInfo.getUserId(),
          TemplateType = 'text'
        )
      };
      insert ets;
    }

    Account acc = BWC_TestDataFactory.createAccount();
    acc.FirstName = ACC_FIRST_NAME;
    acc.LastName = ACC_LAST_NAME;

    List<SObject> objs = new List<SObject>{ acc, usr };
    upsert objs;
  }

  @isTest
  public static void testTemplateDataMergerNoTemplate() {
    List<Account> accs = [SELECT Id, Name, FirstName, LastName FROM Account];
    List<User> usrs = [
      SELECT Id, Name, FirstName, LastName
      FROM User
      WHERE LastName = :USER_LAST_NAME AND FirstName = :USER_FIRST_NAME
    ];

    Boolean isException = false;
    final String templ = 'NO_SUCH_' + GOOD_TEMLPATE;
    Test.startTest();
    try {
      BWC_OutboundMessage.TemplateDataMerger tdm = new BWC_OutboundMessage.TemplateDataMerger(
        templ,
        'en-US',
        new List<SObject>{ accs[0], usrs[0] }
      );
    } catch (BWC_OutboundMessage.EmailTemplateException ex) {
      final String msg = ex.getMessage();
      isException = msg.contains(templ);
    }
    Test.stopTest();

    System.assert(
      isException,
      'Expected exception for unknown template [' +
      templ +
      ']'
    );
  }
  
  @isTest
  public static void testTemplateDataMerger() {
    List<Account> accs = [SELECT Id, Name, FirstName, LastName FROM Account];
    List<User> usrs = [
      SELECT Id, Name, FirstName, LastName
      FROM User
      WHERE LastName = :USER_LAST_NAME AND FirstName = :USER_FIRST_NAME
    ];

    final String templ = GOOD_TEMLPATE;
    Test.startTest();
    BWC_OutboundMessage.TemplateDataMerger tdm = new BWC_OutboundMessage.TemplateDataMerger(
      templ,
      'en-US',
      new List<SObject>{ accs[0], usrs[0] }
    );
    Test.stopTest();

    Boolean check = GOOD_SUBJECT_EXPECTED == tdm.getSubject() 
                    && GOOD_BODY_EXPECTED == tdm.getTextBody()
                    && GOOD_BODY_EXPECTED == tdm.getTextBody();
    System.assert( check, 'TemplateDataMerger failed!' );
  }

  @isTest
  public static void testTemplateDataMergerNoSObject() {
    Boolean isException = false;
    final String templ = BAD_SOBJ_TEMLPATE;
    BWC_OutboundMessage.TemplateDataMerger tdm = new BWC_OutboundMessage.TemplateDataMerger(
      templ,
      'en-US',
      new List<SObject>()
    );
  
    Test.startTest();
    try {
      final String subj = tdm.getSubject();
      System.debug( '--->>> testTemplateDataMergerNoSObject :: subj ' + subj + ';' );
    } catch (BWC_OutboundMessage.EmailTemplateException ex) {
      final String msg = ex.getMessage();
      System.debug( '--->>> testTemplateDataMergerNoSObject :: got msg ' + msg );
      isException = msg.contains(templ);
    }
    Test.stopTest();

    System.assert(
      isException,
      'Expected exception for unknown SObject [' +
      templ +
      ']'
    );
  }

  public static BWC_OutboundMessage.TemplateDataMerger initTemplateDataMerger() {
    List<Account> accs = [SELECT Id, Name, FirstName, LastName FROM Account];
    List<User> usrs = [
      SELECT Id, Name, FirstName, LastName
      FROM User
      WHERE LastName = :USER_LAST_NAME AND FirstName = :USER_FIRST_NAME
    ];

    final String templ = GOOD_TEMLPATE;
    BWC_OutboundMessage.TemplateDataMerger tdm = new BWC_OutboundMessage.TemplateDataMerger(
      templ,
      'en-US',
      new List<SObject>{ accs[0], usrs[0] }
    );

    return tdm;
  }

  @isTest
  public static void testSimplePlatformSmsSender() {
    BWC_OutboundMessage.TemplateDataMerger tdm = initTemplateDataMerger();

    Test.startTest();
    BWC_OutboundMessage.SimplePlatformSmsSender smsSender = 
      new BWC_OutboundMessage.SimplePlatformSmsSender( ' not phone ', tdm );
    Boolean isSent = smsSender.send();     
    Test.stopTest();

    System.assert( isSent, 'testSimplePlatformSmsSender failed to test SMS sender' );
  }

  @isTest
  public static void testSimplePlatformEmailSender() {
    BWC_OutboundMessage.TemplateDataMerger tdm = initTemplateDataMerger();

    Test.startTest();
    BWC_OutboundMessage.SimplePlatformEmailSender emailSender = 
      new BWC_OutboundMessage.SimplePlatformEmailSender( 
        new List<String>{ 'wrong_email@stub.artificial-to-address.nonexist.com' },
        'wrong_email@stub.artificial-reply.nonexist.com',
        tdm  
      );
    Boolean isSent = emailSender.send();     
    Test.stopTest();

    System.assert( isSent, 'testSimplePlatformEmailSender failed to test Email sender' );
  }
}