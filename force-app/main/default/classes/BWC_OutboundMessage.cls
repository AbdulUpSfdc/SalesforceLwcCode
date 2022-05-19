public inherited sharing abstract class BWC_OutboundMessage {
  public class EmailTemplateException extends Exception {
  }

  private static final Pattern mergeFieldsRegExp = Pattern.compile(
    '(?m)\\{!(.*?)\\}'
  );

  private static final String MERGE_FIELD_START_MARK = '{!';
  private static final String MERGE_FIELD_END_MARK = '}';

  /**
   * Naive (RegExp based) version to merge fields from the
   * text/html templates. We assume that templates are using the following
   * syntax for the merge fields:
   *
   * {!NAME_OF_THE_MERGE_FIELD}
   *
   * where NAME_OF_THE_MERGE_FIELD - regular SOQL compatible expression. For example:
   * Contact.Name
   *
   * We assume that template does not use delimiters '{!' and '}' for other purposes
   */
  public inherited sharing class TemplateDataMerger {
    private Set<String> mergeFields;
    private EmailTemplate template;
    private Map<String, SObject> sobjNameToSobj;

    /**
     * Template Data Merger tries to find correct template using language like a suffix
     * added to the input parameter templateDevName and language. Following rules are used:
     *
     * templateDevName,
     * templateDevName + language,
     * templateDevName + '_' + language
     */
    public TemplateDataMerger(
      String templateDevName,
      String language,
      List<SObject> dataObjs
    ) {
      String templateCond = String.escapeSingleQuotes(templateDevName) + '%';
      List<EmailTemplate> templates = [
        SELECT Id, DeveloperName, Subject, HtmlValue, Body
        FROM EmailTemplate
        WHERE DeveloperName LIKE :templateCond
        ORDER BY DeveloperName DESC
      ];
      if (templates.isEmpty()) {
        throw new EmailTemplateException(
          'Cannot find template with Dev Name [' +
          templateDevName +
          ']'
        );
      }
      String lng = language.replaceAll('[^A-Za-z]', '_');
      Set<String> templateNames = new Set<String>{
        templateDevName,
        templateDevName + lng,
        templateDevName +
        '_' +
        lng
      };
      System.debug('--->>> looking for template from: ' + templateNames);
      for (EmailTemplate et : templates) {
        System.debug('--->>> checking template ' + et.DeveloperName);
        if (templateNames.contains(et.DeveloperName)) {
          template = et;
          break;
        }
      }
      if (template == null) {
        // fallback
        template = templates[0];
      }

      sobjNameToSobj = new Map<String, SObject>();
      for (SObject o : dataObjs) {
        if (o != null) {
          String ot = o.getSObjectType().getDescribe().getLocalName();
          sobjNameToSobj.put(ot, o);
        }
      }
    }

    public String getSubject() {
      return mergeData(template.Subject);
    }

    public String getHtmlBody() {
      return mergeData(template.HtmlValue);
    }

    public String getTextBody() {
      return mergeData(template.Body);
    }

    private void initMergeFields(String text) {
      mergeFields = new Set<String>();

      Matcher m = mergeFieldsRegExp.matcher(text);
      while (m.find()) {
        mergeFields.add(
          m.group(0).remove(MERGE_FIELD_START_MARK).remove(MERGE_FIELD_END_MARK)
        );
      }
    }

    private String getFieldValue(String fld) {
      List<String> parts = fld.split('\\.');
      System.debug('--->>> parts ' + parts);
      System.debug(
        '--->>> sobjNameToSobj keys ' + this.sobjNameToSobj.keySet()
      );
      Integer sz = parts.size();
      Integer last = sz - 1;
      SObject so = (sz == 1)
        ? sobjNameToSobj.values()[0]
        : this.sobjNameToSobj.get(parts[0]);
      if (so == null) {
        throw new EmailTemplateException(
          'Cannot get field value "' +
          fld +
          '" because of no corresponding SObject' +
          '; Template "' +
          template.DeveloperName +
          '"'
        );
      }
      System.debug('--->>> so DATA: ' + so);
      Object res = null;
      for (Integer i = (sz == 1) ? 0 : 1; i < sz; i++) {
        if (i == last) {
          res = so.get(parts[i]);
        } else {
          so = so.getSObject(parts[i]);
          if (so == null) {
            break;
          }
        }
      }
      return (res != null) ? String.valueOf(res) : '';
    }

    private String mergeData(String templateText) {
      initMergeFields(templateText);
      String res = templateText;
      System.debug('--->>> text [' + res + ']');
      System.debug('--->>> mergeFields ' + mergeFields);
      for (String fld : mergeFields) {
        String val = getFieldValue(fld);
        System.debug('--->>> fld ' + fld + '; val=' + val);
        res = res.replace(
          MERGE_FIELD_START_MARK +
          fld +
          MERGE_FIELD_END_MARK,
          val
        );
      }
      return res;
    }
  }

  public class SenderException extends Exception {
  }

  public interface Sender {
    // @return true if message has been sent.
    Boolean send();
  }

  public inherited sharing class SimplePlatformSmsSender implements Sender {
    private String phone;
    private TemplateDataMerger template;

    public SimplePlatformSmsSender(String phone, TemplateDataMerger template) {
      this.phone = phone;
      this.template = template;
    }

    public Boolean send() {
      String body = this.template.getTextBody();
      System.debug('--->>> SMS body [' + body + ']');
      Map<String, Object> params = new Map<String, Object>{
        'phone' => this.phone,
        'smsMessage' => body
      };
      Flow.Interview.Generic_SMS_Flow genSmsFlow = new Flow.Interview.Generic_SMS_Flow(
        params
      );
      genSmsFlow.start();
      return true;
    }
  }

  public inherited sharing class SimplePlatformEmailSender implements Sender {
    private List<String> toAddresses;
    private List<String> ccAddresses;
    private List<String> bccAddresses;
    private String replyTo;
    private TemplateDataMerger template;

    public SimplePlatformEmailSender(
      List<String> toAddresses,
      String replyTo,
      TemplateDataMerger template
    ) {
      init(toAddresses, null, null, replyTo, template);
    }

    public SimplePlatformEmailSender(
      List<String> toAddresses,
      List<String> ccAddresses,
      List<String> bccAddresses,
      String replyTo,
      TemplateDataMerger template
    ) {
      init(toAddresses, ccAddresses, bccAddresses, replyTo, template);
    }

    private void init(
      List<String> toAddresses,
      List<String> ccAddresses,
      List<String> bccAddresses,
      String replyTo,
      TemplateDataMerger template
    ) {
      this.toAddresses = toAddresses;
      System.assert(
        this.toAddresses != null && !this.toAddresses.isEmpty(),
        'toAddresses array is null or empty'
      );
      this.ccAddresses = ccAddresses;
      this.bccAddresses = bccAddresses;
      this.replyTo = replyTo;
      System.assert(
        !String.isBlank(this.replyTo),
        'replyTo cannot be null or blank'
      );
      this.template = template;
    }

    public Boolean send() {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSubject(template.getSubject());
      mail.setReplyTo(replyTo);
      mail.setToAddresses(toAddresses);
      if (ccAddresses != null && !ccAddresses.isEmpty()) {
        mail.setCcAddresses(ccAddresses);
      }
      if (bccAddresses != null && !bccAddresses.isEmpty()) {
        mail.setBccSender(true);
        mail.setBccAddresses(bccAddresses);
      }
      mail.setPlainTextBody(template.getTextBody());
      mail.setHtmlBody(template.getHtmlBody());

      Messaging.SendEmailResult[] results = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ mail }
      );
      Boolean isGood = true;
      for (Messaging.SendEmailResult r : results) {
        if (!r.isSuccess()) {
          isGood = false;
          break;
        }
      }
      return isGood;
    }
  }
}