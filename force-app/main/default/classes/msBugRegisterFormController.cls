/****************************************************************************************************
* Class msBugRegisterFormController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   25.02.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   25.02.2020      	    Init version.
*****************************************************************************************************/

public without sharing class msBugRegisterFormController {


    @AuraEnabled
    public static Case enterCase(String newCaseString, String systemInformation, String market) {
        User user = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        String queueName;
        switch on market {
            when 'Germany' {
                queueName = 'Sales_Coordinators_EEG';
            }
            when 'Flex' {
                queueName = 'UK_Flex';
            }
            when 'France' {
                queueName = 'France';
            }
        }
        if (systemInformation.length() > 30000) {
            Map<String, Object> systemInformationMap = (Map<String, Object>) JSON.deserializeUntyped(systemInformation);
            systemInformationMap.remove('userDetails');
            systemInformation= JSON.serialize(systemInformationMap);
        }
        QueueSobject queue = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = :queueName LIMIT 1];

        Case newCase = (Case) System.JSON.deserializeStrict(newCaseString, Case.class);
        newCase.ContactId = user.ContactId;
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Portal_Bug').getRecordTypeId();
        newCase.Origin = 'Web';
        newCase.OwnerId = queue.QueueId;
        insert newCase;

        Activity_log__c activityLog = new Activity_log__c();
        activityLog.Name = 'Systeminformation for case: ' + newCase.Subject;
        activityLog.data_json__c = systemInformation;
        activityLog.Case__c = newCase.Id;
        insert activityLog;

        return newCase;
    }
}