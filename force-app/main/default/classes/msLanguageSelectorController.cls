/****************************************************************************************************
* Class msLanguageSelectorController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   13.08.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   13.08.2018      	    Init version.
*****************************************************************************************************/

public with sharing class msLanguageSelectorController {
    @AuraEnabled
    public static void setLanguage(String language) {
        Id userId = UserInfo.getUserId();
        User me = new User(Id = userId);

        switch on language {
            when 'de' {
                me.LocaleSidKey = 'de_DE_EURO';
                me.LanguageLocaleKey = 'de';
            }
            when 'fr' {
                me.LocaleSidKey = 'fr_FR_EURO';
                me.LanguageLocaleKey = 'fr';
            }
            when else {
                me.LocaleSidKey = 'en_GB';
                me.LanguageLocaleKey = 'en_US';
            }
        }
        update me;
    }
}