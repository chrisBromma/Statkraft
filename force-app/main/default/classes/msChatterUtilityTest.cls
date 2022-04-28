/****************************************************************************************************
* Class msChatterUtilityTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.10.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.10.2018      	    Init version.
*****************************************************************************************************/


@IsTest
private class msChatterUtilityTest {
    @TestSetup
    private static void setup() {
        msTestDataFactory.createTestPortalContext();
    }
    @IsTest private static void getMessageTranslationsTest() {
        msChatterUtility.getMessageTranslations('new_invoice','en_US','subject','body');
        msChatterUtility.getMessageTranslations('new_invoice_by_trigger',null,null,null);
        msChatterUtility.getMessageTranslations('updated_invoice_by_trigger',null,null,null);
        msChatterUtility.getMessageTranslations('downreg_notification', null, null, null);
        msChatterUtility.getMessageTranslations('monthly_submeter_enabled', null, null, null);
        msChatterUtility.getMessageTranslations('monthly_submeter_reminder', null, null, null);
        msChatterUtility.getMessageTranslations('annual_submeter_enabled', null, null, null);
        msChatterUtility.getMessageTranslations('annual_submeter_reminder', null, null, null);
        msChatterUtility.getMessageTranslations('monthly_production_data', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_missing', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_missing_reminder', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_exceeds_capacity', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_exceeds_capacity_reminder', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_constant_values', null, null, null);
        msChatterUtility.getMessageTranslations('live_metering_constant_values_reminder', null, null, null);
        msChatterUtility.getMessageTranslations('masterdata_confirmation', null, null, null);
        msChatterUtility.getMessageTranslations('masterdata_confirmation_reminder', null, null, null);
    }
    @IsTest private static void messageSetupHelperTest() {
        User testUser = [SELECT Id, LastName, ContactId, LanguageLocaleKey, Contact.Salutation FROM User WHERE Username = :'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        msNotificationLogic.messageTypesTranslations wrapper = msChatterUtility.getMessageTranslations('new_invoice_by_trigger',null,null,null);
        msChatterUtility.messageSetupHelper(testUser, 'new_invoice', testUser.LanguageLocaleKey, wrapper.messageTypes.get('new_invoice').languages.get('en'));
    }
    @IsTest private static void getDebugModeTest() {
        msChatterUtility.getDebugMode('new_invoice');
        msChatterUtility.getDebugMode('downreg_notification');
        msChatterUtility.getDebugMode('submeter_enabled');
        msChatterUtility.getDebugMode('monthly_production_data');
    }
    @IsTest private static void getAttachmentTypeTranslationsTest() {
        msChatterUtility.getAttachmentTypeTranslations();
    }
}