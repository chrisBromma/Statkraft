/****************************************************************************************************
* Class msSMSControllerBatch
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   28.05.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   28.05.2019      	    Init version.
*****************************************************************************************************/


public with sharing class msSMSControllerBatch implements Database.Batchable<msNotificationLogic.notificationWrapper>,Database.AllowsCallouts, Database.Stateful {
    private String messageListString;
    private Statkraft_API_Settings__mdt ApiSettings;

    public msSMSControllerBatch(String messageListStringParam) {
        messageListString = messageListStringParam;
        ApiSettings = msUtility.getMetadata();
    }

    public List<msNotificationLogic.notificationWrapper> start(Database.BatchableContext bc) {
        List<msNotificationLogic.notificationWrapper> objectList = (List<msNotificationLogic.notificationWrapper>) JSON.deserializeStrict(messageListString, List<msNotificationLogic.notificationWrapper>.class);

        return objectList;
    }

    public void execute(Database.BatchableContext bc, List<msNotificationLogic.notificationWrapper> records) {

        for(msNotificationLogic.notificationWrapper messageWrapper: records){
            if(messageWrapper.user.MobilePhone!=null) {
                msSendSMSController.sendSms(messageWrapper.user.MobilePhone, messageWrapper.body, 'Statkraft', ApiSettings);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // execute any post-processing operations
    }
}