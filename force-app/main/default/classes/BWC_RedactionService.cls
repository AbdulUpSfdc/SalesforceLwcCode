public inherited sharing abstract class BWC_RedactionService {

  public static final String VIEW_SECURE_PAYMENT_INFO_PS = 'View_Secure_Payment_Information';

  private enum PaymentProfileType {
    temporaryPaymentProfiles, paymentProfiles    
  }

  public enum MessageType {
    SMS,
    EMAIL
  }

  public enum PaymentCapability {
    BANK_NO_CHECK_NUM,
    BANK_WITH_CHECK_NUM,
    CREDCARD,
    CREDCARD_CVV_ONLY,
    REFUND_BANK_NOCHECK_CREDCARD,
    REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT
  }

  public static final Map<Schema.sObjectType, List<String>> INITIATOR_OBJ_2_DEFAULT_CAPABILITIES = new Map<Schema.sObjectType, List<String>>{
    Case.SObjectType => new List<String>{
      PaymentCapability.CREDCARD.name(),
      PaymentCapability.BANK_WITH_CHECK_NUM.name(),
      PaymentCapability.REFUND_BANK_NOCHECK_CREDCARD.name()
    },
    Interaction_Activity__c.SObjectType => new List<String>{
      PaymentCapability.CREDCARD.name(),
      PaymentCapability.BANK_NO_CHECK_NUM.name()
    }
  };

  private static final Set<String> DEFINED_CAPABILITIES = new Set<String>();
  static {
    for (PaymentCapability pc : PaymentCapability.values()) {
      DEFINED_CAPABILITIES.add(pc.name());
    }
    System.debug( '--->>> DEFINED_CAPABILITIES ' + DEFINED_CAPABILITIES );
  }

  public enum RedactionStep {
    OTP,
    OTURL
  }

  private static final Integer MASK_VIS_CHARS_NUM = 4;
  private static final String MASK_CHAR = '*';

  public static final Integer OTP_LEN = 5;

  private static final String URLPATH = 'SecureInformationExchange';

  private static final Map<String, Schema.RecordTypeInfo> RecTypeInfoByDevName = 
    SecureInformationExchange__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
  private static final String SEI_RT_PAYMENT_XCHG = 'PaymentExchange';
  private static final String SEI_RT_INVESTIGATION_XCHG = 'InvestigationExchange';
  public static final String SEI_RT_REFUND_XCHG = 'RefundExchange';
  private static final ID INVEST_RT_ID = RecTypeInfoByDevName.get(SEI_RT_INVESTIGATION_XCHG).getRecordTypeId();
  private static final ID REFUND_RT_ID = RecTypeInfoByDevName.get(SEI_RT_REFUND_XCHG).getRecordTypeId();
  private static final ID PAYMENT_RT_ID = RecTypeInfoByDevName.get(SEI_RT_PAYMENT_XCHG).getRecordTypeId();

  private static final String INTER_ACTIVITY_INTERACTION = 'InteractionActivity__r.Interaction__c';
  private static final String INTER_ACTIVITY_CALLID = 'InteractionActivity__r.Interaction__r.CTI_Call_Identifier__c';
  private static final String INTER_ACTIVITY_CUSTOMER = 'InteractionActivity__r.Customer__c';

  private static final String SEI_SOQL =
    'select' +
    ' Id, CreatedById, CreatedDate,' +
    ' RecordtypeId, Recordtype.DeveloperName,' +
    ' Case__c,' +
    ' InteractionActivity__c, ' +
    INTER_ACTIVITY_CALLID +
    ', ' +
    ' ' +
    INTER_ACTIVITY_INTERACTION +
    ',' +
    ' ' +
    INTER_ACTIVITY_CUSTOMER +
    ',' +
    ' RequestorATTUID__c,' +
    ' OneTimeText__c,' +
    ' IsOtpVerified__c,' +
    ' RequestID__c, RequestPublishedAt__c, RequestAccessedAt__c,' +
    ' PaymentMethodToken__c,' +
    ' NameOnBankAccount__c,	NameOnBankAccountMasked__c,' +
    ' RoutingBankNumber__c, RoutingBankNumberMasked__c,' +
    ' BankAccountNumber__c,	BankAccountNumberMasked__c,' +
    ' CheckNumber__c,' +
    ' Capabilities__c,' +
    ' PaymentProfileName__c' +
    ' from' +
    ' SecureInformationExchange__c';

  private static final Map<Schema.SObjectType, Schema.SObjectField> objToLinkField = new Map<Schema.SObjectType, Schema.SObjectField>{
    Case.sObjectType => SecureInformationExchange__c.Case__c.getDescribe()
      .getSObjectField(),
    Interaction_Activity__c.sObjectType => SecureInformationExchange__c.InteractionActivity__c.getDescribe()
      .getSObjectField()
  };

  private static final Map<MessageType, Map<RedactionStep, String>> channelStepToConfigField = new Map<MessageType, Map<RedactionStep, String>>{
    MessageType.SMS => new Map<RedactionStep, String>{
      RedactionStep.OTP => 'OTPsmsTemplate__c',
      RedactionStep.OTURL => 'OTUrlSMSTemplateName__c'
    },
    MessageType.EMAIL => new Map<RedactionStep, String>{
      RedactionStep.OTP => 'OTPEmailTemplateName__c',
      RedactionStep.OTURL => 'OTUrlEmailTemplateName__c'
    }
  };

  public class RedactionServiceException extends Exception {
  }

  public static Boolean crudeIsOneWayHashBad( String oneWayHash ) {
    return ( String.isBlank( oneWayHash ) || oneWayHash.length() < 40 );
  }

  /**
   * InitiatorObject represents objects from which redaction has been initiaated
   */
  private inherited sharing class InitiatorObject {
    public ID id { get; private set; }
    public Schema.SObjectType objType { get; private set; }
    public Schema.SObjectField fld { get; private set; }
    private Account customer;
    private Billing_Account__c billingAcc;

    public InitiatorObject(ID initiatorObj) {
      id = initiatorObj;
      objType = initiatorObj.getSObjectType();
      System.debug(
        System.LoggingLevel.DEBUG,
        '--->>> InitiatorObject type ' + objType
      );
      fld = objToLinkField.get(objType);
      String soql =
        'select' +
        ' Id, Account_Type__c, Billing_Account_Number__c' +
        ' from Billing_Account__c where id in';
      if (isInvestigation()) {
        soql += ' (select Billing_Account__c from Case where id = :id)';
      } else if (isInteractionActivity()) {
        soql += ' (select Billing_Account__c from Interaction_Activity__c where id = :id)';
      } else {
        throw new RedactionServiceException(
          'Unknown object type for InitiatorObject [' +
          id +
          ']'
        );
      }
      List<Billing_Account__c> baccs = Database.query(soql);
      billingAcc = (baccs != null && !baccs.isEmpty()) ? baccs[0] : null;
    }

    public Boolean isInvestigation() {
      return objType == Case.sObjectType;
    }

    public Boolean isInteractionActivity() {
      return objType == Interaction_Activity__c.sObjectType;
    }

    public Billing_Account__c getBan() {
      return this.billingAcc;
    }

    public Account getCustomer() {
      if (customer == null) {
        List<Account> accs;
        if (isInteractionActivity()) {
          accs = [
            SELECT Id, Name, FirstName, LastName
            FROM Account
            WHERE
              Id IN (
                SELECT Customer__c
                FROM Interaction_Activity__c
                WHERE id = :id
              )
          ];
        } else if (isInvestigation()) {
          accs = [
            SELECT Id, Name, FirstName, LastName
            FROM Account
            WHERE Id IN (SELECT AccountId FROM Case WHERE id = :id)
          ];
        }
        if (accs.isEmpty()) {
          throw new RedactionServiceException(
            'Cannot find customer for the initiator Object id=' + id
          );
        }
        customer = accs[0];
      }
      return customer;
    }
  }

  /**
   * SenderFactory class is reponsible for creating correct
   * BWC_OutboundMessage.Sender instance to communicate with the customer
   */
  private inherited sharing class SenderFactory {
    private MessageType msgType;
    private BWC_OutboundMessage.TemplateDataMerger dataMerger;
    private BWC_OutboundMessage.Sender sender;
    private String lang;

    private SenderFactory() {
    }

    public SenderFactory(
      MessageType msgType,
      String messageTemplateDevName,
      String language,
      List<SObject> data
    ) {
      this.msgType = msgType;
      this.lang = language;
      dataMerger = new BWC_OutboundMessage.TemplateDataMerger(
        messageTemplateDevName,
        language,
        data
      );
    }

    public BWC_OutboundMessage.Sender getSender(
      List<String> toAddresses,
      String replyTo
    ) {
      if (sender == null) {
        if (msgType == MessageType.SMS) {
          sender = new BWC_OutboundMessageMC.SenderMC(
            toAddresses[0],
            dataMerger.getTextBody(),
            BWC_OutboundMessageMC.getLang(lang)
          );
          // sender = new BWC_OutboundMessage.SimplePlatformSmsSender(
          //   toAddresses[0],
          //   dataMerger
          // );
        } else if (msgType == MessageType.EMAIL) {
          sender = new BWC_OutboundMessageMC.SenderMC(
            toAddresses[0],
            dataMerger.getSubject(),
            replyTo,
            dataMerger.getHtmlBody(),
            BWC_OutboundMessageMC.getLang(lang)
          );
          // sender = new BWC_OutboundMessage.SimplePlatformEmailSender(
          //   toAddresses,
          //   replyTo,
          //   dataMerger
          // );
        } else {
          throw new RedactionServiceException(
            'Cannot create BWC_OutputMessage.Sender instance Unknown MessageType "' +
            msgType +
            '"'
          );
        }
      }
      return sender;
    }
  }

  private class SieComparable implements Comparable {

    public SecureInformationExchange__c sie;

    public SieComparable( SecureInformationExchange__c sie ) {
      this.sie = sie;
    }

    public Integer compareTo(Object obj) {
      SieComparable sc = (SieComparable)obj;
      Integer res = 0;
      if ( sc.sie.RecordTypeId != sie.RecordTypeId ) {
        res = ( sie.RecordTypeId == REFUND_RT_ID ) ? 1 : -1;
      }
      return res;
    }
  }

  /**
   * Service class provides Redaction related logic for different clients
   *
   * 1) initiate Redaction Process sending OTP to the Customer
   * 2) Send One Time Limited TTL Url to the Customer
   * 3) Collect payment information entered by the Customer
   */
  public inherited sharing class Service {
    private Integer otpLen;
    private InitiatorObject initiatorObj;
    private List<SecureInformationExchange__c> sieRecs;
    private List<SecureInformationExchangeConfig__mdt> sieCfgs;
    private String siteDomain;
    private List<BWC_PaymentDetails.PaymentDetailsResponse> paymentDetails;
    private String callId;
    private ID interactionId;

    public Service(ID initiatorObj) {
      init(initiatorObj, OTP_LEN);
    }

    public Service(ID initiatorObj, Integer otpLen) {
      init(initiatorObj, otpLen);
    }

    public Service(String oneWayHash) {
      System.debug('--->>> Got hash request [' + oneWayHash + ']');
      if ( crudeIsOneWayHashBad(oneWayHash) ) { //(String.isBlank(oneWayHash)) {
        throw new RedactionServiceException('Hash is empty');
      }
      getsieRecs(oneWayHash);
      if (sieRecs == null || sieRecs.isEmpty()) {
        throw new RedactionServiceException('Hash not found');
      }
      // Last case sensetive hash check, since SOQL is not case sensetive
      if (!oneWayHash.equals(sieRecs[0].RequestID__c)) {
        throw new RedactionServiceException('Hash not found. CS.');
      }

      getSeiConfigs();
      siteDomain = sieCfgs[0].ExternalSiteName__c;

      ID initiatorId = (sieRecs[0].Case__c != null)
        ? sieRecs[0].Case__c
        : sieRecs[0].InteractionActivity__c;
      this.initiatorObj = new InitiatorObject(initiatorId);
      System.debug('--->>> hash init this.initiatorObj' + initiatorObj);

      reordersieRecs();

      //  getMulePaymentDetails();
    }

    private void init(ID initiatorObjId, Integer otpLen) {
      getSeiConfigs();
      siteDomain = sieCfgs[0].ExternalSiteName__c;

      this.initiatorObj = new InitiatorObject(initiatorObjId);
      this.otpLen = otpLen;

      getsieRecs();

      if (sieRecs == null || sieRecs.isEmpty()) {
        sieRecs.add(
          new SecureInformationExchange__c(
            RecordTypeId = (initiatorObj.isInvestigation()
              ? INVEST_RT_ID
              : PAYMENT_RT_ID)
          )
        );
        linkSeiRec();
      }

      reordersieRecs();
    }

    private void getsieRecs(String oneWayHash) {
      if ( crudeIsOneWayHashBad(oneWayHash) ) {
//      if ( String.isBlank( oneWayHash ) || oneWayHash.length() < 40 ) {
        throw new RedactionServiceException( 'Hash is too short' );
      }
      String hash = String.escapeSingleQuotes( oneWayHash ) + '%';
      String soql = SEI_SOQL + ' where RequestID__c like \'' + hash + '\'';
      System.debug( '--->>> soql ' + soql );
      sieRecs = Database.query(soql);
      initInvestigationSpecificData();
    }

    private void getsieRecs() {
      ID initiatorId = initiatorObj.id;
      String soql =
        SEI_SOQL +
        ' where Case__c = :initiatorId or InteractionActivity__c = :initiatorId';
      sieRecs = Database.query(soql);
      System.debug( '--->>> getSIERecs sieRecs ' + sieRecs );
      initInvestigationSpecificData();
    }

    private void initInvestigationSpecificData() {
      if (sieRecs == null || sieRecs.isEmpty()) {
        return;
      }
      if (sieRecs[0].InteractionActivity__c != null) {
        interactionId = sieRecs[0].InteractionActivity__r.Interaction__c;
        callId = String.valueOf(
          sieRecs[0].InteractionActivity__r.Interaction__r.CTI_Call_Identifier__c
        );
      } else if (sieRecs[0].Case__c != null) {
        List<Interaction__c> interactions = [
          SELECT Id, CTI_Call_Identifier__c
          FROM Interaction__c
          WHERE
            Id IN (
              SELECT Interaction__c
              FROM Case_Interaction__c
              WHERE Case__c = :sieRecs[0].Case__c
            )
        ];
        if (interactions.isEmpty()) {
          throw new RedactionServiceException(
            'Cannot find Callid for Case ' + sieRecs[0].Case__c
          );
        }
        callId = interactions[0].CTI_Call_Identifier__c;
        interactionId = interactions[0].Id;
      }
      System.debug(
        '--->>> Got CallId ' +
        callId +
        ' where Case ' +
        sieRecs[0].Case__c +
        ' or InteractionActivity__c ' +
        sieRecs[0].InteractionActivity__c +
        ' interactionId = ' +
        interactionId
      );
    }

    // In case of the payment flow we will have only one sie Record in the Array.
    // But in case of Investigation we can have up to two records:
    //  1) sie.RecordType.Name = SEI_RT_INVESTIGATION_XCHG
    //  2) sie.RecordType.Name = SEI_RT_REFUND_XCHG
    //  or just one
    //  1) 
    //  1) sie.RecordType.Name = SEI_RT_REFUND_XCHG
    private void reordersieRecs() {
      List<SieComparable> tmpSies = new List<SieComparable>();
      for ( SecureInformationExchange__c sie : sieRecs ) {
        if ( sie != null ) {
          tmpSies.add( new SieComparable( sie ) );
        }
      }
      System.debug( LoggingLevel.DEBUG, '--->>> SIEs before sorting: ' + tmpSies );
      tmpSies.sort();
      System.debug( LoggingLevel.DEBUG, '--->>> SIEs AFTER sorting: ' + tmpSies );
      sieRecs = new List<SecureInformationExchange__c>();
      for (SieComparable sieComp : tmpSies ) {
          sieRecs.add( sieComp.sie );
      }
    }

    public Billing_Account__c getBillingAccount() {
      if (this.initiatorObj != null) {
        return this.initiatorObj.billingAcc;    
      }
      return null;
    }

    public Date getDueDate() {
      Date res = null;
      if (paymentDetails != null && !paymentDetails.isEmpty()) {
        BWC_PaymentDetails.PaymentDetailsResponse pdr = this.paymentDetails[0];
        System.debug(
          '--->>> account balance summary ' + pdr.accountBalanceSummary
        );
        String dte = pdr.accountBalanceSummary?.billDueDate;
        if (!String.isBlank(dte)) {
          return Date.valueOf(dte);
        }
      }
      return res;
    }

    private SecureInformationExchange__c hidePaymentData( SecureInformationExchange__c sie ) {
      sie.PaymentMethodToken__c = null;
      sie.NameOnBankAccount__c = null;
      sie.RoutingBankNumber__c = null;    
      sie.BankAccountNumber__c = null;
      // sie.CheckNumber__c = null;
      return sie;
    }

    public List<SecureInformationExchange__c> getSIERecords() {
      System.debug( '--->>> before FLS cleanup ' + sieRecs );
      System.debug( '--->>> User Id ' + UserInfo.getUserId() );

      // Temporary code to check that "super" Permission Set is assigned to the Agent
      // Should be removed once we figure out why Security.stripInaccessible is not working correctly
      //
      List<PermissionSetAssignment> pms = [SELECT Id FROM PermissionSetAssignment WHERE 
        AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = :VIEW_SECURE_PAYMENT_INFO_PS];
      if ( pms.isEmpty() ) {
        // we need to filter out data 
        hidePaymentData( sieRecs[ 0 ] );
        if ( sieRecs.size() == 2 ) {
          hidePaymentData( sieRecs[ 1 ] );
        }
      }

      System.debug( '--->>> getSIERecords() ' + sieRecs );

      // SObjectAccessDecision securityDecision = 
      //    Security.stripInaccessible( AccessType.READABLE, sieRecs );
      // System.debug( '--->>> securityDecision ' + securityDecision );
      // System.debug( '--->>> after FLS cleanup ' + sieRecs );

      return sieRecs;
    }

    private void getSeiConfigs() {
      sieCfgs = [
        SELECT
          HashAlgorithmName__c,
          OTPEmailTemplateName__c,
          OTPsmsTemplate__c,
          OTUrlEmailTemplateName__c,
          OTUrlSMSTemplateName__c,
          RecordTypeID__c,
          TTLInSeconds__c,
          URLBase__c,
          ReplyTo__c,
          ExternalSiteName__c
        FROM SecureInformationExchangeConfig__mdt
        WHERE URLBase__c = :URLPATH
      ];
    }

    public Boolean startSecureXchangeCVV( 
      MessageType msgType, 
      String targetAddress, 
      String language,
      String paymentProfileId
    ) {
      Boolean res = false;

      SecureInformationExchangeConfig__mdt cfg = getCfg(sieRecs[0]);
      String digest = generateDigest(cfg);
      Map<String,Object> fld2Val = new Map<String,Object>();
      fld2Val.put( 'Id', sieRecs[ 0 ].Id );
      fld2Val.put( 'RecordTypeId', PAYMENT_RT_ID );
      fld2Val.put( 'OneTimeText__c', randomString(otpLen) );
      fld2Val.put( 'RequestorATTUID__c', getAttUidForCurrUser() );
      fld2Val.put( 'RequestID__c', getOneTimeUrl( cfg.URLBase__c, digest, language ) );
      fld2Val.put( 'RequestPublishedAt__c', System.now() );
      fld2Val.put( 'Capabilities__c', PaymentCapability.CREDCARD_CVV_ONLY );
      fld2Val.put( 'PaymentProfileName__c', paymentProfileId );
      fld2Val.put( 'Case__c', sieRecs[ 0 ].Case__c );
      fld2Val.put( 'InteractionActivity__c', sieRecs[ 0 ].InteractionActivity__c );

      System.debug( LoggingLevel.DEBUG, 'fld2Val=' + fld2Val );      
      SecureInformationExchange__c sie = sieFactory( fld2Val );
      System.debug( LoggingLevel.DEBUG, 'sie=' + sie );      
      
      res = notifyCustomer(msgType, sie, targetAddress, language);

      // Finally save only digest without URL.
      sieRecs[0] = sie;
      sieRecs[0].RequestID__c = digest;

      upsert sieRecs;
      System.debug('--->>> startSecureXchange sieRec[ 0 ] ' + sieRecs[0]);

      return res;
    }

    public Boolean startSecureXchange(
      MessageType msgType,
      String targetAddress,
      String language
    ) {
      List<String> methods = INITIATOR_OBJ_2_DEFAULT_CAPABILITIES.get(
        initiatorObj.objType
      );
      return startSecureXchange(msgType, targetAddress, methods, language);
    }

    public List<String> requestedCapabilities() {
      return processRequestedCapabilities(sieRecs[0].Capabilities__c);
    }

    public String getRefundPaymentMethodName() {
      return ( sieRecs.size() > 1 && String.isBlank( sieRecs[ 1 ]?.PaymentProfileName__c ) 
        ? '' : sieRecs[ 1 ]?.PaymentProfileName__c);
    }

    private List<String> processRequestedCapabilities(
      String csvCapabilitiesList
    ) {
      System.debug(
        '--->>> processingCapabilities from string [' +
        csvCapabilitiesList +
        ']'
      );
      List<String> requestedCapabilities;
      if (!String.isBlank(csvCapabilitiesList)) {
        requestedCapabilities = csvCapabilitiesList.split(',');
        for (Integer i = 0, sz = requestedCapabilities.size(); i < sz; i++) {
          requestedCapabilities[i] = requestedCapabilities[i].trim();
        }
      }

      return processRequestedCapabilities(requestedCapabilities);
    }

    private List<String> processRequestedCapabilities(
      List<String> requestedCapabilities
    ) {
      System.debug(
        '--->>> processingCapabilities from array [' +
        requestedCapabilities +
        ']'
      );
      List<String> checkedCapabilities;
      if (requestedCapabilities == null || requestedCapabilities.isEmpty()) {
        checkedCapabilities = INITIATOR_OBJ_2_DEFAULT_CAPABILITIES.get(
          initiatorObj.objType
        );
        System.debug(
          '--->>> requestedCapabilites null or empty. objType ' +
          initiatorObj.objType +
          '; checkedCapabilities ' +
          checkedCapabilities
        );
      } else {
        if (DEFINED_CAPABILITIES.containsAll(requestedCapabilities)) {
          checkedCapabilities = requestedCapabilities;
          System.debug(
            '--->>> requestedCapabilites subset of the DEFINED_CAPABILITIES ' +
            initiatorObj.objType +
            '; checkedCapabilities ' +
            checkedCapabilities
          );
        } else {
          checkedCapabilities = INITIATOR_OBJ_2_DEFAULT_CAPABILITIES.get(
            initiatorObj.objType
          );
          System.debug(
            '--->>> requestedCapabilites has errors. Fallback for DEFAULT ' +
            initiatorObj.objType +
            '; checkedCapabilities ' +
            checkedCapabilities
          );
        }
      }
      System.debug(
        '--->>> processingCapabilities checkedCapabilities ' +
        checkedCapabilities
      );
      return checkedCapabilities;
    }

    private SecureInformationExchange__c sieFactory( Map<String,Object> fld2valMap ) {
      SecureInformationExchange__c sie = new SecureInformationExchange__c();
      Set<String> lowerCaseFlds = new Set<String>();
      for ( String fld : fld2valMap.keySet() ) {
        lowerCaseFlds.add( fld.toLowerCase() );
        Object o = fld2valMap.get( fld );
        if ( o instanceOf PaymentCapability ) {
          o = ((PaymentCapability)o).name();
        }
        sie.put( fld, o );
      }

      Set<String> protectedFlds = new Set<String>{
        'ownerid', 'recordtypeid', 'interactionactivity__c', 'case__c',
        'requestid__c'
      };
      Map<String, Schema.SObjectField> flds = SecureInformationExchange__c.sObjectType.getDescribe().fields.getMap();
      for ( String fnm : flds.keySet() ) {
        if ( !lowerCaseFlds.contains( fnm ) ) {
          Schema.SObjectField f = flds.get( fnm );
          Schema.DescribeFieldResult dfr = f.getDescribe();
          if ( dfr.isUpdateable() && !protectedFlds.contains( fnm ) ) {
            System.debug( LoggingLevel.DEBUG, '--->>> sieFactory field [' + fnm + '] ' + dfr );
            sie.put( fnm, dfr.defaultvalue ); 
          }
        }
      }
      return sie;
    }

    private String getAttUidForCurrUser() {
      User usr = [select id, ATTUID__c from User where id = :UserInfo.getUserId()][ 0 ];
      return usr.ATTUID__c;
    }

    private String getOneTimeUrl( String urlBase, String digest, String language ) {
      // First save url with digest, so email can be composed and send
      String oturl =
        'https://' +
        siteDomain +
        '/' +
        urlBase +
        '?OTID=' +
        digest +
        '&LANG=' +
        EncodingUtil.urlEncode(language, 'UTF-8');

      return oturl;
    }

    private Boolean notifyCustomer(
      MessageType msgType,
      SecureInformationExchange__c sie,
      String targetAddress,
      String language
    ) {
      BWC_OutboundMessage.Sender sender = getSender(
        msgType,
        RedactionStep.OTURL,
        sie,
        targetAddress,
        language
      );
      return sender.send();
    }

    public Boolean startSecureXchange(
      MessageType msgType,
      String targetAddress,
      List<String> requestedCapabilities,
      String language
    ) {
      Boolean res = false;

      // User usr = [select id, ATTUID__c from User where id = :UserInfo.getUserId()][ 0 ];

      // SecureInformationExchangeConfig__mdt cfg = getCfg(sieRecs[0]);

      // String digest = generateDigest(cfg);

      // // First save url with digest, so email can be composed and send
      // String oturl =
      //   'https://' +
      //   siteDomain +
      //   '/' +
      //   cfg.URLBase__c +
      //   '?OTID=' +
      //   digest +
      //   '&LANG=' +
      //   EncodingUtil.urlEncode(language, 'UTF-8');

      System.debug(
        '--->>> need to check capabilities ' + requestedCapabilities
      );
      requestedCapabilities = processRequestedCapabilities(
        requestedCapabilities
      );

      SecureInformationExchangeConfig__mdt cfg = getCfg(sieRecs[0]);
      String digest = generateDigest(cfg);

      Map<String,Object> fld2Val = new Map<String,Object>();
      if ( 
        requestedCapabilities.indexOf( 
          PaymentCapability.REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT.name() 
        ) >= 0 
      ) {
        fld2Val.put( 'RecordTypeId', REFUND_RT_ID );
      }
      else {
        fld2Val.put( 'RecordTypeId', sieRecs[0].RecordTypeId );
      }
      fld2Val.put( 'Id', sieRecs[ 0 ].Id );
      fld2Val.put( 'OneTimeText__c', randomString(otpLen) );
      fld2Val.put( 'RequestorATTUID__c', getAttUidForCurrUser() );
      fld2Val.put( 'RequestID__c', getOneTimeUrl( cfg.URLBase__c, digest, language ) );
      fld2Val.put( 'RequestPublishedAt__c', System.now() );
      fld2Val.put( 'Capabilities__c', String.join(requestedCapabilities, ',') );
      fld2Val.put( 'Case__c', sieRecs[ 0 ].Case__c );
      fld2Val.put( 'InteractionActivity__c', sieRecs[ 0 ].InteractionActivity__c );

      System.debug(LoggingLevel.DEBUG, '--->>> startSecureXchange fld2Val ' + fld2Val );
      SecureInformationExchange__c sie = sieFactory( fld2Val );

      // BWC_OutboundMessage.Sender sender = getSender(
      //   msgType,
      //   RedactionStep.OTURL,
      //   sie,
      //   targetAddress,
      //   language
      // );
      // res = sender.send();

      res = notifyCustomer(msgType, sie, targetAddress, language);

      // Finally save only digest without URL.
      sieRecs[0] = sie;
      sieRecs[0].RequestID__c = digest;

      System.debug(LoggingLevel.DEBUG, '--->>> startSecureXchange sieRecs ' + sieRecs );
      upsert sieRecs;
      System.debug('--->>> startSecureXchange sieRec[ 0 ] ' + sieRecs[0]);

      return res;
    }

    public Boolean verifyOTP(String otp) {
      checkRecordAccess(
        SecureInformationExchange__c.RequestAccessedAt__c
          .getDescribe()
          .getSObjectField(),
        null // Payment method is not saved yet. We just checking OTP
      );

      Boolean res = sieRecs[0].OneTimeText__c.equalsIgnoreCase(otp);

      sieRecs[0].IsOtpVerified__c = res;
      System.debug(
        System.LoggingLevel.DEBUG,
        'Verify OTP [' +
        otp +
        '] with [' +
        sieRecs[0].OneTimeText__c +
        '] result = ' +
        sieRecs[0].IsOtpVerified__c
      );
      // sieRecs[ 0 ].RequestAccessedAt__c = System.now();  // ??? We do not extend time for negotiation here
      upsert sieRecs[0];

      return res;
    }

    public Boolean checkOTPVerificationStatus() {
      checkRecordAccess(
        SecureInformationExchange__c.RequestAccessedAt__c
          .getDescribe()
          .getSObjectField(),
        null // Payment method is not saved yet. We just checking OTP
      );
      return sieRecs[0].IsOtpVerified__c;
    }

    private void checkRecordAccess(
      Schema.sObjectField expiredFieldToCheck,
      Schema.sObjectField alreadyAccessedFieldToCheck
    ) {
      System.debug(
        '--->>> checkRecordAccess called ' +
        expiredFieldToCheck +
        '; alreadyAccessed ' +
        alreadyAccessedFieldToCheck
      );
      // Check for access expiration
      Long published =
        ((DateTime) sieRecs[0].get(expiredFieldToCheck)).getTime() / 1000;
      Long now = System.now().getTime() / 1000;
      SecureInformationExchangeConfig__mdt cfg = getCfg(sieRecs[0]);
      Long ttl = cfg.TTLInSeconds__c.longValue();
      if (ttl < (now - published)) {
        throw new RedactionServiceException('Expired');
      }

      // Check one time access
      if (
        alreadyAccessedFieldToCheck != null &&
        sieRecs[0].get(alreadyAccessedFieldToCheck) != null
      ) {
        throw new RedactionServiceException('Already Accessed');
      }
    }

    public SecureInformationExchange__c startCustomerEntry() {
      System.debug('--->>> startCustomerEntry sieRecs ' + sieRecs);
      if (sieRecs == null || sieRecs.isEmpty()) {
        throw new RedactionServiceException('No such record');
      }

      checkRecordAccess(
        SecureInformationExchange__C.RequestPublishedAt__c
          .getDescribe()
          .getSObjectField(),
        SecureInformationExchange__C.RequestAccessedAt__c
          .getDescribe()
          .getSObjectField()
      );

      getMulePaymentDetails( sieRecs[0] );

      sieRecs[0].RequestAccessedAt__c = System.now();
      upsert sieRecs;

      return sieRecs[0];
    }

    public String getRedactionType() {
      Schema.DescribeSObjectResult res = SecureInformationExchange__c.SObjectType.getDescribe();
      Map<Id, Schema.RecordTypeInfo> id2rti = res.getRecordTypeInfosById();
      return id2rti.get(sieRecs[0].RecordTypeId).getDeveloperName();
    }

    private String getCallId() {
      return callId;
    }

    @testVisible
    private String mask( String src ) {
      final String s = src.trim();
      String mstr = s;
      if ( !String.isBlank( s ) ) {
        mstr = s.right( MASK_VIS_CHARS_NUM );
        mstr = mstr.leftPad( s.length(), MASK_CHAR );
      }
      return mstr;
    }

    private Boolean adjustSFdataBeforeSave(
      SecureInformationExchange__c sie,
      BWC_RedactionPaymentMethod.RequestResponseWrapper rrw
    ) {
      Boolean res = true;
      if (rrw != null && rrw.response != null) {
        if (rrw.response.error != null) {
          BWC_ExceptionUtils.handleException(
            new RedactionServiceException(
              'Failed to save payment method: ' + JSON.serialize(rrw)
            ),
            true
          );
          res = false;
        }
        if (rrw.response.content != null) {
          sie.PaymentProfileName__c = rrw.request.profileName;
          if (initiatorObj.isInvestigation()) {
            sie.PaymentMethodToken__c = (String.isBlank(
                rrw.response.content.cardToken
              ))
              ? null
              : rrw.response.content.cardToken;
            BWC_PaymentProfile.BankAccount bi = rrw.request?.paymentMethod?.bankAccount; 
            if ( bi != null ) {
              sie.NameOnBankAccount__c = bi.accountHolderName;
              sie.NameOnBankAccountMasked__c = mask( sie.NameOnBankAccount__c ); 
              sie.RoutingBankNumber__c = bi.routingNumber;
              sie.RoutingBankNumberMasked__c = mask( sie.RoutingBankNumber__c );
              sie.BankAccountNumber__c = bi.bankAccountNumber;
              sie.BankAccountNumberMasked__c = mask( sie.BankAccountNumber__c );
              sie.CheckNumber__c = bi.checkNumber;
            }  
          }
        }
      }
      return res;
    }

    public Boolean savePaymentMethod(
      BWC_RedactionPaymentMethod.PaymentMethod pm
    ) {
      System.debug('--->>> got savePaymentMethod request ' + pm);
      if (sieRecs == null || sieRecs.isEmpty()) {
        throw new RedactionServiceException('Wrong URL');
      }

      if (!sieRecs[0].IsOtpVerified__c) {
        throw new RedactionServiceException('OTP is not verified');
      }

      checkRecordAccess(
        SecureInformationExchange__c.RequestAccessedAt__c
          .getDescribe()
          .getSObjectField(),
        SecureInformationExchange__c.PaymentMethodToken__c
          .getDescribe()
          .getSObjectField()
      );

      System.debug( LoggingLevel.DEBUG, '--->>> SAVING payment: ' + pm );
      if ( pm.primary != null && pm.secondary == null ) {
        // CVV capability or Case->REFUND ONLY Use case
        if ( 
          pm.primary.creditCard?.ccNumber == null 
          && pm.primary.creditCard?.ccSecurityCode != null
        ) {
          BWC_PaymentDetails.PaymentProfile pprofile = getProfileForSIE( sieRecs[ 0 ], PaymentProfileType.paymentProfiles ); // getTempPaymentProfile( sieRecs[ 0 ] );
          pm.primary.creditCard.ccName = pprofile.card.cardHolderName;
          pm.primary.creditCard.ccNumber = pprofile.card.cardNumber;
          pm.primary.creditCard.ccExpiration = 
            pprofile.card.expireMonth + '/' + pprofile.card.expireYear;
          pm.primary.creditCard.ccZip = pprofile.card.zipCode;
          pm.primary.creditCard.existingPaymentProfile = sieRecs[ 0 ].PaymentProfileName__c; 
        }       
      }
      System.debug( LoggingLevel.DEBUG, '--->>> SAVING AFTER CC ADJUSTMENT payment: ' + pm );
      System.debug( LoggingLevel.DEBUG, '--->>> SAVING sieRecs: ' + sieRecs );

      if ( 
          sieRecs[ 0 ].Capabilities__c.contains( 
            PaymentCapability.REFUND_BANK_NOCHECK_CREDCARD_NO_PAYMENT.name() 
          )
      ) {
        // REFUND ONLY 
        pm.secondary = null; // make sure that we have one record for the initiatorObj only
      }

      BWC_RedactionPaymentMethod.RequestResponseWrapper primaryRes = pm.primary.save(
        sieRecs[0].RequestorATTUID__c,
        initiatorObj.getBan(),
        initiatorObj.getCustomer(),
        getCallId()
      );
      System.debug('--->>> primaryRes ' + primaryRes);
      BWC_RedactionPaymentMethod.RequestResponseWrapper secondaryRes = pm.secondary
        ?.save(
          sieRecs[0].RequestorATTUID__c,
          initiatorObj.getBan(),
          initiatorObj.getCustomer(),
          getCallId()
        );
      System.debug('--->>> secondaryRes ' + secondaryRes);

      adjustSFdataBeforeSave(sieRecs[0], primaryRes);

      if (pm.secondary != null) {
        SecureInformationExchange__c refundSei = sieRecs[0]
          .clone(false, true, true, false);
        refundSei.RecordTypeId = REFUND_RT_ID;
        System.debug( LoggingLevel.DEBUG, '--->>> refund Record ID : ' + REFUND_RT_ID );
        System.debug( LoggingLevel.DEBUG, '--->>> refund (second SIE) : ' + refundSei );
        if (sieRecs != null && sieRecs.size() == 1) {
          sieRecs.add(null);
        }
        sieRecs[1] = refundSei;
        sieRecs[1].RequestID__c = sieRecs[1].RequestID__c + '-2';
        adjustSFdataBeforeSave(sieRecs[1], secondaryRes);
        System.debug('--->>> sieRecs ' + sieRecs);
      }
      else { // No refund or only refund
        if ( sieRecs.size() == 2 ) {
          sieRecs.remove( 1 );
        }
      }
      System.debug( LoggingLevel.DEBUG, '--->>> sieRecs before cleanUpPreviousRedactions : ' + sieRecs );

      cleanUpPreviousRedactions();

      upsert sieRecs;

      return true;
    }

    private void cleanUpPreviousRedactions() {
      String req = sieRecs[ 0 ].RequestID__c + '%';
      List<SecureInformationExchange__c> sies = [select id from SecureInformationExchange__c where RequestID__c like :req];
      System.debug(LoggingLevel.DEBUG, '--->>> SIEs in the database: ' + sies );
      System.debug(LoggingLevel.DEBUG, '--->>> SIEs in the CURRENT session: ' + sieRecs );

      Set<ID> goodSeis = new Set<ID>();
      for ( SecureInformationExchange__c sie : sieRecs ) {
        goodSeis.add( sie.Id );
      }

      List<SecureInformationExchange__c> recsToBeDeleted = new List<SecureInformationExchange__c>();
      for ( SecureInformationExchange__c sie : sies ) {
        if ( !goodSeis.contains( sie.Id ) ) {
          recsToBeDeleted.add( sie );
        }
      }
      if ( !recsToBeDeleted.isEmpty() ) {
        delete recsToBeDeleted;
      }
    }

    public void getMulePaymentDetails( SecureInformationExchange__c sie ) {
      System.debug('--->>> sie ' + sie);
      SObject so = sie.getSobject('InteractionActivity__r');
      ID interactionRecordId = (so != null)
        ? ID.valueOf((String) so.get('Interaction__c'))
        : interactionId;
      System.debug('--->>> interactionRecordId ' + interactionRecordId);

      String ban = this.initiatorObj.billingAcc.Billing_Account_Number__c;
      System.debug('--->>> ban ' + ban);

      if ( !System.Test.isRunningTest() ) {
        if (ban != null) {
          paymentDetails = BWC_PaymentDetailsService.getPaymentDetails(
            interactionRecordId,
            new List<String>{ ban },
            sie.RequestorATTUID__c,
            getCallId(),
            new List<String>{ 
              PaymentProfileType.temporaryPaymentProfiles.name(), 
              PaymentProfileType.paymentProfiles.name(),
              'accountBalanceSummary'
            }
          );
        } else {
          paymentDetails = BWC_PaymentDetailsService.getPaymentDetails(
            interactionRecordId,
            null,
            sie.RequestorATTUID__c,
            getCallId(),
            new List<String>{ 
              PaymentProfileType.paymentProfiles.name(),
              PaymentProfileType.temporaryPaymentProfiles.name(),
              'accountBalanceSummary'
            }
          );
        }
        
        System.debug(
          '--->>> GOT paymentDetails:' + JSON.serialize(paymentDetails, true)
        );  
      }
    }

    private BWC_PaymentDetails.PaymentProfile getProfileForSIE( 
      SecureInformationExchange__c sie, 
      PaymentProfileType pptype 
    ) {
      getMulePaymentDetails( sie );
      BWC_PaymentDetails.PaymentProfile res = null;
      System.debug( '--->>> paymentDetails: ' + paymentDetails );
      if (paymentDetails == null || paymentDetails.isEmpty()) {
        return res;
      }
      BWC_PaymentDetails.PaymentDetailsResponse pdr = paymentDetails[0];
      BWC_PaymentDetails.PaymentProfiles pps;
      if (pptype == PaymentProfileType.paymentProfiles ) {
        pps = pdr.paymentProfiles;
      }
      else {
        pps = pdr.temporaryPaymentProfiles;
      }
      System.debug( '--->>> SIE DATA: ' + sie );
      if (pps != null) {
        for (BWC_PaymentDetails.PaymentProfile pp : pps.paymentProfileList) {
          System.debug( '--->>> SIE profile name   [' + sie.PaymentProfileName__c + ']' );
          System.debug( '--->>> Compare to profile [' + pp.profileName + ']' );
          if (pp.profileName == sie.PaymentProfileName__c) {
            res = pp;
            break;
          }
        }
      }
      return res;
    } 

    public BWC_PaymentDetails.PaymentProfile getTempPaymentProfile( SecureInformationExchange__c sie ) {
      return getProfileForSIE(sie, PaymentProfileType.temporaryPaymentProfiles );
      // getMulePaymentDetails( sie );
      // BWC_PaymentDetails.PaymentProfile res = null;
      // System.debug( '--->>> paymentDetails: ' + paymentDetails );
      // if (paymentDetails == null || paymentDetails.isEmpty()) {
      //   return res;
      // }
      // BWC_PaymentDetails.PaymentDetailsResponse pdr = paymentDetails[0];
      // BWC_PaymentDetails.PaymentProfiles pps = pdr.temporaryPaymentProfiles;
      // System.debug( '--->>> SIE DATA: ' + sie );
      // if (pps != null) {
      //   for (BWC_PaymentDetails.PaymentProfile pp : pps.paymentProfileList) {
      //     System.debug( '--->>> SIE profile name   [' + sie.PaymentProfileName__c + ']' );
      //     System.debug( '--->>> Compare to profile [' + pp.profileName + ']' );
      //     if (pp.profileName == sie.PaymentProfileName__c) {
      //       res = pp;
      //       break;
      //     }
      //   }
      // }
      // return res;
    }
  
    public BWC_PaymentDetails.PaymentProfile getRefundPaymentProfile() {
      final Boolean isRefundOnly = (sieRecs.size() == 1 && sieRecs[ 0 ].RecordTypeId == REFUND_RT_ID );
      SecureInformationExchange__c trgSie = 
        ( isRefundOnly ) ? 
          sieRecs[ 0 ] 
          : 
          (sieRecs.size() > 1 && sieRecs[ 1 ] != null) 
            ? sieRecs[ 1 ] : null;
      
      return (trgSie != null) ? 
        getTempPaymentProfile( trgSie ) : null; 
    }

    public BWC_PaymentDetails.PaymentProfile getNewTempPaymentProfile() {
      BWC_PaymentDetails.PaymentProfile res = null;
      if ( sieRecs[ 0 ] != null ) {

        if ( sieRecs[ 0 ].Capabilities__c != null && sieRecs[ 0 ].Capabilities__c.contains( PaymentCapability.CREDCARD_CVV_ONLY.name() ) ) {

          res = getProfileForSIE(sieRecs[ 0 ], PaymentProfileType.paymentProfiles );

        } else {

          res = getTempPaymentProfile( sieRecs[ 0 ] );

        }
      }
      return res; 
    }

    private BWC_OutboundMessage.Sender getSender(
      MessageType msgType,
      RedactionStep step,
      SecureInformationExchange__c sie,
      String targetAddress,
      String language
    ) {
      Account customer = initiatorObj.getCustomer();
      System.debug('--->>> customer ' + customer);
      List<SObject> data = new List<SObject>{ sie, customer };

      SenderFactory factory = new SenderFactory(
        msgType,
        getTemplateDevNameFromConfig(msgType, step, sie),
        language,
        data
      );
      BWC_OutboundMessage.Sender sender = factory.getSender(
        new List<String>{ targetAddress },
        getCfg(sie).ReplyTo__c
      );

      return sender;
    }

    private String getTemplateDevNameFromConfig(
      MessageType msgType,
      RedactionStep step,
      SecureInformationExchange__c sie
    ) {
      SecureInformationExchangeConfig__mdt cfg = getCfg(sie);
      String fieldWithTrgTemplateName = channelStepToConfigField.get(msgType)
        .get(step);
      return String.valueOf(cfg.get(fieldWithTrgTemplateName));
    }

    private void linkSeiRec() {
      for (SecureInformationExchange__c sie : sieRecs) {
        sie.put(initiatorObj.fld, initiatorObj.id);
      }
    }

    // Utility method to generate OTP
    private String randomString(Integer len) {
      // final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
      final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      // final String chars = '0123456789';
      String randStr = '';
      while (randStr.length() < len) {
        Integer idx = Math.mod(
          Math.abs(Crypto.getRandomInteger()),
          chars.length()
        );
        randStr += chars.substring(idx, idx + 1);
      }
      System.debug('--->>> randStr ' + randStr);
      return randStr;
    }

    private SecureInformationExchangeConfig__mdt getCfg(
      SecureInformationExchange__c sie
    ) {
      SecureInformationExchangeConfig__mdt cfg = null;
      Map<String, Schema.RecordTypeInfo> rti = RecTypeInfoByDevName;
      for (SecureInformationExchangeConfig__mdt c : sieCfgs) {
        ID rtid = rti.get(c.RecordTypeID__c).getRecordTypeId();
        if (rtid == sie.RecordTypeId) {
          cfg = c;
          break;
        }
      }
      return cfg;
    }

    private String generateDigest(
      SecureInformationExchangeConfig__mdt cfg
    ) {
      // Deterministic per Agent
      String data =
        initiatorObj.id +
        '-' +
        UserInfo.getUserId();
      Blob res = Crypto.generateDigest(
        cfg.HashAlgorithmName__c,
        Blob.valueOf(data)
      );
      return EncodingUtil.convertToHex(res);
    }

    public Billing_Account__c getBAN() {
      return this.initiatorObj.getBan();
    }

    public Account getCustomer() {
      return this.initiatorObj.getCustomer();
    }
  }
}