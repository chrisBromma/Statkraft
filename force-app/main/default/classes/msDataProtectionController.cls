/****************************************************************************************************
* Class msDataProtectionController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   21.04.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   21.04.2020      	    Init version.
*****************************************************************************************************/

public with sharing class msDataProtectionController {

    @AuraEnabled
    public static Map<String, String> getDataProtection() {
        msPortalSystemSetting__mdt systemSetting = msUtility.getPortalSettings();

        Map<String, String> result = new Map<String, String>();
        result.put('language', Label.msLanguage);
        String endpoint;

        switch on Label.msLanguage {
            when 'de' {
                endpoint = systemSetting.DataProtectionDE__c;
            }
            when 'fr' {
                endpoint = systemSetting.DataProtectionFR__c;
            }
            when 'en_US' {
                endpoint = systemSetting.DataProtectionEN__c;
            }
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        HttpResponse response = new Http().send(request);
        if(response.getStatusCode() == 301 || response.getStatusCode() == 302)
        {
            request.setEndpoint(response.getHeader('Location'));
            response = new Http().send(request);
        }

        if (endpoint.endsWith('.pdf') || endpoint.endsWith('.pdf/')) {
            result.put('type', 'pdf');
            result.put('content', EncodingUtil.base64Encode(response.getBodyAsBlob())) ;
        } else {
            result.put('type', 'html');
            result.put('content', response.getBody()) ;
        }

        return result;
    }
}