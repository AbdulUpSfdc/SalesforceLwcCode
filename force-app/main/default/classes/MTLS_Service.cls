@RestResource(urlMapping='/SFA/v1/Mahalo_requests/*')
    Global with sharing class MTLS_Service {
    //@RestResource(urlMapping='/SFA/v1/Customer_Connect_MTLS_requests/*')

		@TestVisible 
        class Ticket {
            String   IP;
            DateTime TIMESTAMP;
            String   FINGERPRINT;
            String   VERIFY;
            String 	 SUBJECT;
			@TestVisible 			
            Ticket (String ip, String verify, String fingerprint, String subject) {
                this.IP = ip;
                this.VERIFY = verify;
                this.TIMESTAMP = dateTime.now();
                this.FINGERPRINT = fingerprint;
                this.SUBJECT = subject;
            }
        }
        @testVisible
        class Response {
            String cypherText  = null;
            String message = null;
            String expect = null;
        }
        public static Map<String,String> getVerify(MTLS_Detail__mdt mahalo, String cypherText) {

            Map<String, String> rtn = new Map<String, String>();
            try {
                Blob privateKey = EncodingUtil.base64Decode(mahalo.KEY256__c);
                ATTCryptoUtil cu = new ATTCryptoUtil();
                Blob cipherTextBlob = EncodingUtil.base64Decode(cu.verifyAndRemoveHMAC(cypherText));
                String decryptedCipherText = Crypto.decryptWithManagedIV('AES256', privateKey, cipherTextBlob).toString();
                MTLS_Service.Ticket ticket = (MTLS_Service.Ticket) JSON.deserialize(decryptedCipherText, MTLS_Service.Ticket.class);
                dateTime now = dateTime.now();


                if (mahalo.Proxy_Endpoint__c.contains(ticket.IP) &&
                        ticket.TIMESTAMP < now &&
                        ticket.TIMESTAMP > now.addMinutes(-3)
                    ) {
                        if (String.isNotBlank(ticket.SUBJECT)) {
                            try {
                                if(isUserValid(ticket.SUBJECT)){
                                    rtn.put('fingerprint', ticket.FINGERPRINT);
                                    rtn.put('verify', ticket.VERIFY);
                                    rtn.put('subject',ticket.SUBJECT);
                                }else{
                                    rtn.put('message', MTLS_Constants.NO_VALID_USER_ERROR);
                                }

                            } catch(Exception e) { }
                        }
                    } else {
                        rtn.put('message', MTLS_Constants.NO_VALID_TICKET_ERROR);
                    }

                } catch (System.Exception e) {
                    rtn.put('message', 'ERROR: ' + e.getMessage());
                    Logger.error('MTLS_Service getVerify Error: ',e);
                } finally {
                    Logger.saveLog();
                }
                return rtn;
        }
        @HttpGet
        global static void doGet() {
            MTLS_Service.Response MSR = new MTLS_Service.Response();

            String X_ALOHA_SIP          = RestContext.request.headers.get('X-ALOHA-SIP');
            String X_ALOHA_PROXY_UUID   = RestContext.request.headers.get('X-ALOHA-PROXY-UUID');
            String X_ALOHA_PROXY        = RestContext.request.headers.get('X-ALOHA-PROXY');
            String X_ALOHA_mTLS_CLIENT  = RestContext.request.headers.get('X-ALOHA-mTLS-CLIENT');
            String X_ALOHA_mTLS_SUBJECT = RestContext.request.headers.get('X-ALOHA-mTLS-SUBJECT');
            String X_Salesforce_SIP     = RestContext.request.headers.get('X-Salesforce-SIP');
            String action = RestContext.request.requestURI.substring(RestContext.request.requestURI.lastIndexOf('/') + 1);
            list<string> headerList = RestContext.request.headers.toString().split(',');
           
            
            /*for(String key:RestContext.request.headers.keySet()){
                System.debug('key: ' +key+ ' value: '+ RestContext.request.headers.get(key));
            }
            System.debug('toString: '+ RestContext.request.headers.toString());
            System.debug('From Proxy X_ALOHA_SIP: '+ X_ALOHA_SIP);
            System.debug('From Proxy X_ALOHA_PROXY_UUID: '+ X_ALOHA_PROXY_UUID);
            System.debug('From Proxy X_ALOHA_PROXY: '+ X_ALOHA_PROXY);
            System.debug('From Proxy X_ALOHA_mTLS_CLIENT: '+ X_ALOHA_mTLS_CLIENT);
            System.debug('From Proxy X_ALOHA_mTLS_SUBJECT: '+ X_ALOHA_mTLS_SUBJECT);
            System.debug('From Proxy X_Salesforce_SIP: '+ X_Salesforce_SIP);
            System.debug('From Proxy request: '+  RestContext.request);*/

            RestContext.response.addHeader('Content-Type', 'application/javascript');
            RestContext.response.addHeader('Cache-Control', 'no-cache, no-store');
            RestContext.response.addHeader('Pragma', 'no-cache');



            if (action.equalsIgnoreCase('jsonp')) {
                MTLS_Detail__mdt MDT_Record = MTLS_Detail__mdt.getInstance('Default');

                if (String.isNotBlank(X_ALOHA_PROXY_UUID) &&
                MTLS_Constants.UUIDv4Pattern.matcher(X_ALOHA_PROXY_UUID).matches()
                ) {

                    if (MDT_Record.Proxy_Endpoint__c.contains(X_ALOHA_SIP))
                    {
                        try {

                            MTLS_Service.Ticket ServiceTicket = new MTLS_Service.Ticket(X_ALOHA_SIP, X_ALOHA_PROXY, X_ALOHA_mTLS_CLIENT, X_ALOHA_mTLS_SUBJECT);

                            if (X_ALOHA_PROXY_UUID.equals(MDT_Record.UUID__c)) {

                                MSR = handleEncrypt(ServiceTicket, MSR, X_ALOHA_PROXY,MDT_Record);

                            } else {
                                MSR.message = MTLS_Constants.PROXY_UUID_MISSMATCH_ERROR;
                            }

                        } catch (System.Exception e) {
                          //  System.debug('ERROR: '+e.getMessage() + ' Stack Info: '+ e.getStackTraceString());
                            MSR.message = 'ERROR: ' + e.getMessage();
                            Logger.error('MTLS_Service Error: ',e);
                        } finally {
                            Logger.saveLog();
                        }

                    } else {
                        MSR.message = MTLS_Constants.NO_VALID_SIP_ERROR;
                    }

                } else {
                    MSR.message = MTLS_Constants.NO_VALID_UUID_ERROR;
                }

                RestContext.response.responseBody = Blob.valueOf('parseResponse(' + JSON.serialize(MSR, true) + ');');
                RestContext.response.statusCode = 200;

            } else {
                RestContext.response.statusCode = 403;
            }
        }
        public static Boolean isUserValid(string SUBJECT){
            Boolean returnValue=false;

            string ATTUID = SUBJECT.removeStart('CN=').substringBefore(',');

            list<User> userList = [Select Id, IsActive, ATTUID__c from user WHERE id =: UserInfo.getUserId() WITH SECURITY_ENFORCED];


            if( userList != null && !userList.isEmpty() && ATTUID.equalsIgnoreCase(userList[0]?.ATTUID__c) && String.isNotBlank(ATTUID))
            {
                returnValue = true;
            }

            return returnValue;
        }
        public static MTLS_Service.Response  handleEncrypt(MTLS_Service.Ticket Ticket,MTLS_Service.Response res, String proxy,MTLS_Detail__mdt metaRecord){
            Blob privateKey = EncodingUtil.base64Decode(metaRecord.KEY256__c);
            Blob clearText = Blob.valueOf(JSON.serialize(Ticket, true));
            ATTCryptoUtil cu = new ATTCryptoUtil();
            res.cypherText = cu.addHMAC(EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', privateKey, clearText)));
            res.expect = proxy;
            return res;
        }
    }