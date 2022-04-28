/****************************************************************************************************
* Class msSendSMSController
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	This class manages the sending out of SMS Messages via the SMS Partner service.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)	                06.03.2019       	Init version.
*****************************************************************************************************/
public with sharing class msSendSMSController {

    public static HttpResponse sendSms(String to, String text, String sender, Statkraft_API_Settings__mdt apiSettings) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        text = EncodingUtil.urlEncode(text,'UTF-8');

        String konto = apiSettings.Lox24_SMS_Account__c;
        String password = apiSettings.Lox24_API_Key__c;
        String service = apiSettings.Lox24_SMS_Service__c;
        String encoding = '0'; // 0 = GSM encoding; 1 = Unicode
        String httphead = '1'; // 1 = get State when Post fails 0 = no State return
        String timestamp = '0'; // 0 = send directly (Unix Timestamp)
        String action = 'send'; // send = send real sms; info = show preview and costs when you want to send that message
        String returnType = 'text';

        String url = apiSettings.Lox24_SMS_Endpoint__c;
        String endpoint = url + '?konto=' + konto + '&password=' + password + '&service=' + service + '&encoding=' + encoding + '&timestamp=' + timestamp + '&httphead=' + httphead + '&action=' + action + '&to=' + to + '&text=' + text + '&from=' + sender + '&return=' + returnType;

        req.setEndpoint(endpoint);
        req.setMethod('POST');

        if(Test.isRunningTest()) {
            return null;
        }else {
            return http.send(req);
        }
    }
    public static HttpResponse sendSms(String to, String text, String sender) {
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        text = EncodingUtil.urlEncode(text,'UTF-8');

        String konto = apiSettings.Lox24_SMS_Account__c;
        String password = apiSettings.Lox24_API_Key__c;
        String service = apiSettings.Lox24_SMS_Service__c;
        String encoding = '0'; // 0 = GSM encoding; 1 = Unicode
        String httphead = '1'; // 1 = get State when Post fails 0 = no State return
        String timestamp = '0'; // 0 = send directly (Unix Timestamp)
        String action = 'send'; // send = send real sms; info = show preview and costs when you want to send that message
        String returnType = 'text';

        String url = apiSettings.Lox24_SMS_Endpoint__c;
        String endpoint = url + '?konto=' + konto + '&password=' + password + '&service=' + service + '&encoding=' + encoding + '&timestamp=' + timestamp + '&httphead=' + httphead + '&action=' + action + '&to=' + to + '&text=' + text + '&from=' + sender + '&return=' + returnType;

        req.setEndpoint(endpoint);
        req.setMethod('POST');

        if(Test.isRunningTest()) {
            return null;
        } else {
            return http.send(req);
        }
    }
}