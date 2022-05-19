/*
    Utility methods to  be used by other classes
*/
public with sharing class BWC_Utils {

    /*
        Helper to set StaticResourceCalloutMock. Creates mock instance and sets it.
    */
    public static StaticResourceCalloutMock setStaticResourceMock(String staticResourceName, Integer statusCode) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(staticResourceName);
        mock.setStatusCode(statusCode);
        Test.setMock(HttpCalloutMock.class, mock); 
        return mock;
    }

    /*
        Do smart append of a string.
    */
    public static String appendString(String baseString, String stringToAppend, String separator) {

        String result = baseString == null ? '' : baseString;

        if (String.isEmpty(stringToAppend)) {
            return baseString;
        }

        if (String.isEmpty(baseString)) {
            return stringToAppend;
        }

        return baseString + separator + stringToAppend;

    }

    /*
        Good enough for random GUID for trace ID or other use.
    */
	public static String newGuid() {

		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
		return guid;

	}

    // Parses the string input as Date
    public static Date parseDate(String input) {
        Date retVal = null;
        if (input != null) {
            retVal = Date.valueOf(input);
        }

        return retVal;
    }

    // If the parameter recordId is of Interaction__c record, then find the corresponding Person Account and return it.
    // Else return the same recordId.
    public static Id getAccountIdFromInteractionId(Id recordId) {
        if (recordId != null) {
            if (recordId.getSobjectType().getDescribe().getName() == 'Interaction__c') {
                Interaction__c interaction = [SELECT Id, Customer__c FROM Interaction__c WHERE Id = :recordId];
                return interaction.Customer__c;
            }
        }
        return recordId;

    }

    public static Boolean getBoolean(String str){
        if(str != null && str == 'true'){
            return true;
        } else if(str != null && str == 'Y') {
            return true;
        } else {
            return false;
        }
    }

    public static String getDayOfMonthOrdinal(Date dateValue) {

        Integer day = dateValue.day();
        switch on dateValue.day() {
            when 1, 21, 31 {
                return String.valueOf(day) + 'st';
            }
            when 2, 22 {
                return String.valueOf(day) + 'nd';
            }
            when 3, 23 {
                return String.valueOf(day) + 'rd';
            }
            when else {
                return String.valueOf(day) + 'th';
            }
        }

    }

    /*
        Returns ATT ID for the current user.
    */
    private static User currentUser;
    public static String getCurrentUserAttId() {

        if (currentUser == null) {
            currentUser = [SELECT Id, ATTUID__c FROM User WHERE Id = :UserInfo.getUserId()];
        }

        if (String.isEmpty(currentUser.ATTUID__c) && !Test.isRunningTest()) {
            throw new BWC_Exception('Salesforce User.ATTUID is not set, required for API call.');
        }

        return currentUser.ATTUID__c;

    }

    // Mask the input string
    // After removing  space, - and /, 
    // 1) if the input is all numeric and size is 15 or more return xxxxxxxxxxx9999
    // 2) if the input is all numeric and size is 9 to 14 return xxxx9999
    // 9999 is the last four digits in the dtring.
    public static String mask(String input) {

        String output = input;
        if (input != null) {
            System.debug('mask input:' + input);
            // remove space, - and /
            input = input.replaceAll('[ /-]', '');
            Integer length = input.length();
            // After removing space, - and /, the string is all numeric
            if (input.isNumeric() && length > 8) {
                System.debug('mask input length:' + length);
                if (length > 14) {
                    output = 'xxxxxxxxxxx' + input.substring(length - 4);
                }
                else {
                    output = 'xxxxx' + input.substring(length - 4);
                }
            }
        }

        return output;
    }

    private static String ccPrefix = '(?i)((CC|CC:|Credit Card|Credit Card:|Credit Cards:|Credit|Credit:|VISA|Mastercard|Master Card|MC|Amex|American Express|Discover|Bank Account|Bank Account:))';
    private static String ssnPrefix = '((SSN|SSN:|Social|Social:|Social Security|Social Security:|Social Security Number|Social Security Number:|Tax ID|Tax ID:) )';
    private static Pattern maskPattern = Pattern.compile('([0-9][0-9 \\-/]{7,}[0-9])' + '|'+ '(' + ccPrefix + '[0-9 \\-/]{8,}[0-9]' + ')' + '|' + '(' +  ssnPrefix + '[0-9 \\-/]{8,}[0-9]' + ')');
    
    private static Pattern numberPattern = Pattern.compile('([0-9]{4}[ \\-][0-9]{6}[ \\-][0-9]{5})|([0-9]{4}[ \\-][0-9]{4}[ \\-][0-9]{4}[ \\-][0-9]{4})|([0-9]{3}[ \\-/][0-9]{2}[ \\-/][0-9]{4})');
   
    // The pattern that matches string starting with CC etc.
    private static Pattern ccPrefixPattern = Pattern.compile(ccPrefix + '.*');
    // The pattern that matches string starting with SSN etc.
    private static Pattern ssnPrefixPattern = Pattern.compile(ssnPrefix + '.*');
    

    // This method masks a para with numbers matching certain critria (See method BWC_Utils.mask()).
    // It ignores masking numbers that has prefix BAN, Account Number etc.
    public static String maskSentence(String sentence) {

        Matcher myMatcher = maskPattern.matcher(sentence);

        // For debug purpose, keep track of count.
        Integer count = 0;

        // Keep track of the index of the last character in the previous match
        Integer lastEnd = 0;
        String result = '';

        // Loop through each match
        while(myMatcher.find()) {
            count++;
            System.debug('found: ' + count + ' : ' + myMatcher.group() + ' # '
                        + myMatcher.start() + ' - ' + myMatcher.end());

            String matchedString = myMatcher.group();

            // Copy from last match to the start of current match
            result += sentence.substring(lastEnd, myMatcher.start());
            
            // When the matched string doesn't start with the prefix
            if (ccPrefixPattern.matcher(matchedString).matches()) {
                Integer idx = matchedString.indexOfAny('0123456789');
                String stringToMask = matchedString.substring(idx);

                String cleanString = stringToMask.replaceAll('[ /-]', '');
                Integer len = cleanString.length();
                String maskedString = stringToMask;
                if (len >= 9) {
                    maskedString = BWC_Utils.mask(stringToMask);
                }

                result += matchedString.substring(0,idx) + maskedString;                
            }
            else if (ssnPrefixPattern.matcher(matchedString).matches()) {
                Integer idx = matchedString.indexOfAny('0123456789');
                String stringToMask = matchedString.substring(idx);

                String cleanString = stringToMask.replaceAll('[ /-]', '');
                Integer len = cleanString.length();
                String maskedString = stringToMask;
                if (len >= 9 && len <= 12) {
                    maskedString = BWC_Utils.mask(stringToMask);
                }

                result += matchedString.substring(0,idx) + maskedString;                
            }
            else if (numberPattern.matcher(matchedString).matches()) {
                // Append the masked number
                result += BWC_Utils.mask(matchedString);
            }
            else {
                // Append string as it is.
                result += myMatcher.group();
            }

            // Store the index of the last character in the current match.
            lastEnd = myMatcher.end();
        }

        // Append the remaining string.
        result += sentence.substring(lastEnd);

        System.debug(result);

        return result;
    }

    /*
        Retrieve body of a named static resource as a string.
    */
    public static String getStaticResourceBody(String resourceName) {

        List<StaticResource> resources = [SELECT Body FROM StaticResource WHERE Name = :resourceName];
        if (resources.isEmpty()) {
            throw new BWC_Exception('Resource not found: ' + resourceName);
        }

        StaticResource resource = resources[0];

        String body = resource.Body.toString();

        return body;

    }

    public static final String DATE_TIME_FORMAT_CTI_IDENT='yMdHm';
    public static final String CTI_IDENT_FORMAT = 'Automated_{0}_{1}';
    public static String getAutoCTIIdent(){

        List<Object> formatArguments = new List<Object>();
        String dateTimeStr = System.now().format(DATE_TIME_FORMAT_CTI_IDENT);
        Integer randNum = Integer.valueof((Math.random() * 1000000));
        String randNumStr = generateRandomString(8);

        formatArguments.add(dateTimeStr);
        formatArguments.add(randNumStr);

        return String.format(CTI_IDENT_FORMAT, formatArguments);
    }

    public static String generateRandomString(Integer len) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    public static String generateDynamicQuery(String SObjectType, List<String> fields){
        String queryTemplate = 'SELECT {0} FROM {1}';
        
        String fieldsString= String.join(fields, ', ');
        List<Object> params = new List<Object>{fieldsString, SObjectType};

        return String.format(queryTemplate, params);
    }

    /*
        Return masked version of a phone number.
    */
    public static String maskPhoneNumber(String valueToMask) {

        if (String.isEmpty(valueToMask)) {
            return valueToMask;
        }

        String fifthValue = valueToMask.right(5);
		fifthValue = fifthValue.substring(0,1);
		return '(***) **' + fifthValue + '-' + valueToMask.right(4);
        
    }

    /*
        Return masked version of an email address.
    */
    public static String maskEmailAddress(String valueToMask) {

        if (String.isEmpty(valueToMask)) {
            return valueToMask;
        }

        return valueToMask.left(1) + '****@' + valueToMask.substringAfter('@');

    }

    /*
        Return hashed version of a contact method (phone number, email address)
    */
    public static String hashContactMethod(String valueToMask) {

        if (String.isEmpty(valueToMask)) {
            return valueToMask;
        }

        Blob valueStrBlob = Blob.valueOf(valueToMask);
        Blob valueHash = Crypto.generateDigest('MD5', valueStrBlob); 

        return EncodingUtil.base64Encode(valueHash);

    }

    public static String formatPhone(String phone) {
        string nondigits = '[^0-9]';
        string phoneDigits;
        
        // remove all non numeric
        phoneDigits = phone.replaceAll(nondigits,'');
        
        // 10 digit phone
        if (phoneDigits.length() == 10) 
            return '(' + phoneDigits.substring(0,3) + ') ' +
                    phoneDigits.substring(3,6) + '-' +
                    phoneDigits.substring(6,10);
        // 11 digit phone: if starts with 1, +1 and format as 10 digit 
        if (phoneDigits.length() == 11) {
            if (phoneDigits.substring(0,1) == '1') {
                return  '+' + phoneDigits.substring(0,1) + ' ' +
                        '(' + phoneDigits.substring(1,4) + ') ' +
                        phoneDigits.substring(4,7) + '-' +
                        phoneDigits.substring(7,11);
            }
        }
      
        // if it isn't a 10 or 11 digit number, return the original because
        // it may contain an extension or special information
        return phone;
      }

    /*
        Returns a random integer between min and max.
    */
    public static Integer getRandomInteger(Integer min, Integer max) {

        Double randomDouble = Math.random();
        Integer result = (Integer)Math.floor(randomDouble * (max - min + 1) + min);
        return result;

    }

    // Check if user can edit record
    public static boolean checkRecordEditability(Id recordId) {
        UserRecordAccess userRecordAccess = [
            SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
        ];

        return userRecordAccess.HasEditAccess ? true : false;
    }

    public static String toProperCase(String text){

        if(text == null){
            return text;
        }

        return text.substring(0,1).toUpperCase()+text.substring(1).toLowerCase();

    }

}