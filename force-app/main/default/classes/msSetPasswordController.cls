/****************************************************************************************************
* Class msSetPasswordController
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   13.03.2019
*   Description	:	Controller for the msSetPassword Lightning Component
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	    Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)      13.03.2019       	    Init version.
*****************************************************************************************************/
public with sharing class msSetPasswordController {
    /**
     * @description -   This method changes the current Users password to the given String and notifies them via Email
     *                  about this change. If anything goes wrong, it throws an Aura Handled Exception for the Frontend.
     */
    @AuraEnabled
    public static void setUserPassword(String pwd) {
        try{
            System.setPassword(UserInfo.getUserId(), pwd);
            sendEmailChangeNotification();
        } catch(DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        catch(Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static void sendEmailChangeNotification() {
        OrgWideEmailAddress owa  =  [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply-salesforce@statkraft.com'];
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :'Community_Reset_Password_Master' LIMIT 1];
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(template.Id, UserInfo.getUserId(), null);
        mail.setOrgWideEmailAddressId(owa.Id);
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
}