/****************************************************************************************************
* Class msTwitterFeedController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.09.2018      	    Init version.
*****************************************************************************************************/

public without sharing class msTwitterFeedController {
    @AuraEnabled
    public static String getTwitterFeed() {
        String languageLocaleKey = [SELECT LanguageLocaleKey FROM User WHERE Id = :UserInfo.getUserId()].LanguageLocaleKey;
        String portalSettingNameOfAccount = 'Twitter - Account Name - ' + languageLocaleKey;
        String twitterAccount = 'Statkraft';

        List<PortalSettings__c> setting = [SELECT String__c FROM PortalSettings__c WHERE Name = :portalSettingNameOfAccount];
        if (setting.size() > 0) {
            twitterAccount = setting[0].String__c;
        }
        return twitterAccount;
    }
}