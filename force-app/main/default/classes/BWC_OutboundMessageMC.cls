public inherited sharing abstract class BWC_OutboundMessageMC {
  private static final String MOTSID = '30685';

  private inherited sharing class Message {
    public String subject;
    public String fromAlias; // "orders@accounttest.att-mail.com",
    public String msgContent;

    public Message(String content) {
      msgContent = content;
    }

    public Message(String subject, String fromAlias, String msgContent) {
      this.subject = subject;
      this.fromAlias = fromAlias;
      this.msgContent = msgContent;
    }
  }

  private enum MessageType {
    SMS,
    EMAIL
  }
  private enum SubCategory {
    SMS_Redaction,
    Email_Redaction
  }
  private enum Priority {
    HIGH,
    MEDIUM,
    LOW
  }
  public enum Language {
    EN,
    ES
  }

  private static final Map<MessageType, SubCategory> msgTypeToSubCat = new Map<MessageType, SubCategory>{
    MessageType.SMS => SubCategory.SMS_Redaction,
    MessageType.EMAIL => SubCategory.Email_Redaction
  };

  private final static String DATE_TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\''; // 'yyyy-MM-dd\'T\'HH:mm:ssZ'; //'yyyy-MM-dd\'T\'HH:mm:ss.SSSZ';
  private final static String TRG_TIMEZONE = 'CST6CDT';

  private inherited sharing class Customer {
    public SubCategory subCategory;
    public List<String> ctn;
    public List<String> emailId;
    public MessageType mode;
    public Priority priority;
    public String eventSentTime;
    public Language langPreference;
    public List<Message> notificationInfo;

    public Customer(String to, String payload, Language lang) {
      mode = MessageType.SMS;
      String phone = to.replaceAll('[^\\d]', '');
      if ( !phone.startsWith( '1' ) ) {
        phone = '1' + phone;
      }
      ctn = new List<String>{ phone };
      init(new Message(payload), lang);
    }

    public Customer(String to, Message msg, Language lang) {
      mode = MessageType.EMAIL;
      emailId = new List<String>{ to };
      init(msg, lang);
    }

    private void setSentTime() {
      DateTime ts = System.now();
      eventSentTime = ts.format(DATE_TIME_FORMAT, TRG_TIMEZONE);
    }

    private void init(Message msg, Language lang) {
      subCategory = msgTypeToSubCat.get(mode);
      priority = BWC_OutboundMessageMC.Priority.HIGH;
      setSentTime();
      langPreference = lang;
      notificationInfo = new List<Message>{ msg };
    }
  }

  private inherited sharing class Request {
    public String sourceId { get; private set; }
    public List<Customer> customers { get; private set; }

    public Request(Customer customer) {
      sourceId = MOTSID;
      customers = new List<Customer>{ customer };
    }
  }

  private inherited sharing class Communication {
    public List<Request> communication { get; private set; }

    public Communication(Request req) {
      communication = new List<Request>{ req };
    }
  }

  public class OutboundMessageMCException extends Exception {
  }

  public static Language getLang(String lang) {
    Language res = Language.EN;

    if (!String.isBlank(lang)) {
      for (Language l : Language.values()) {
        if (lang.startsWithIgnoreCase(l.name())) {
          res = l;
          break;
        }
      }
    }

    return res;
  }

  public inherited sharing class SenderMC implements BWC_OutboundMessage.Sender {
    private Communication communication;

    public SenderMC(String phone, String payload, Language lang) {
      communication = new Communication(
        new Request(new Customer(phone, payload, lang))
      );
    }

    public SenderMC(
      String email,
      String subject,
      String fromAlias,
      String payload,
      Language lang
    ) {
      communication = new Communication(
        new Request(
          new Customer(email, new Message(subject, fromAlias, payload), lang)
        )
      );
    }

    public Boolean send() {
      Boolean res = false;

      final String payload = JSON.serialize(communication, true);
      System.debug('--->>> payload ' + payload);

      HTTPResponse resp;
      
      if (Test.isRunningTest()){
        resp = new HttpResponse();
        resp.setStatusCode(200);
      }
      else {
        resp = BWC_IntegrationUtility.makeHTTPCallout(
          BWC_Constants.API_MULTI_CLOUD_INTEGRATION,
          payload
        );
      }
      if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {
        res = true;
      } else {
        System.debug(
          System.LoggingLevel.ERROR,
          'Request ' +
          payload +
          ' Failed ' +
          resp
        );
      }

      return res;
    }
  }
}