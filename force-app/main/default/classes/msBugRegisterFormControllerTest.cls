/****************************************************************************************************
* Class msBugRegisterFormControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   25.03.2020
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   25.03.2020      	    Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msBugRegisterFormControllerTest {
    private static Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Portal_Bug').getRecordTypeId();

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();

        List<Group> testGroups = new List<Group>();
        testGroups.add(new Group(Name = 'Sales_Coordinators_EEG', Type = 'Queue'));
        testGroups.add(new Group(Name = 'France', Type = 'Queue'));
        testGroups.add(new Group(Name = 'UK_Flex', Type = 'Queue'));
        insert testGroups;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<QueuesObject> queues = new List<QueueSobject>();
            queues.add(new QueueSObject(QueueID = testGroups[0].id, SObjectType = 'Case'));
            queues.add(new QueueSObject(QueueID = testGroups[1].id, SObjectType = 'Case'));
            queues.add(new QueueSObject(QueueID = testGroups[2].id, SObjectType = 'Case'));
            insert queues;
        }
    }
    @IsTest
    private static void testRegisterGermanBug() {
        Case newCase = new Case();
        newCase.Subject = 'Hey Germany, I found a bug';
        newCase.Description += 'Tried Action:\n Some Action \n\n\nObserved Error:\nEverything chrashed';

        String systemInformation = '{}';
        QueueSobject queue = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = 'Sales_Coordinators_EEG' LIMIT 1];


        List<Case> foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assertEquals(0, foundCases.size(), 'There are already cases for this queue');

        msBugRegisterFormController.enterCase(JSON.serialize(newCase), systemInformation, 'Germany');

        foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assert(foundCases.size() == 1, 'More or less cases were created');
        System.assertEquals(foundCases[0].Subject, 'Hey Germany, I found a bug');
    }
    @IsTest
    private static void testRegisterGermanBugLong() {
        Case newCase = new Case();
        newCase.Subject = 'Hey Germany, I found a bug';
        newCase.Description += 'Tried Action:\n Some Action \n\n\nObserved Error:\nEverything chrashed';

        //generate very long random string. It might be possible that we collected to much data from customer, that the field would overflow
        String systemInformation = '{"randomString":"';
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        while (systemInformation.length() < 30000) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            systemInformation += chars.substring(idx, idx + 1);
        }
        systemInformation += '"}';

        QueueSobject queue = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = 'Sales_Coordinators_EEG' LIMIT 1];


        List<Case> foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assertEquals(0, foundCases.size(), 'There are already cases for this queue');

        msBugRegisterFormController.enterCase(JSON.serialize(newCase), systemInformation, 'Germany');

        foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assert(foundCases.size() == 1, 'More or less cases were created');
        System.assertEquals(foundCases[0].Subject, 'Hey Germany, I found a bug');
    }

    @IsTest
    private static void testRegisterFranceBug() {
        Case newCase = new Case();
        newCase.Subject = 'Hey France, I found a bug';
        newCase.Description += 'Tried Action:\n Some Action \n\n\nObserved Error:\nEverything chrashed';

        String systemInformation = '{}';
        QueueSobject queue = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = 'France' LIMIT 1];


        List<Case> foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assertEquals(0, foundCases.size(), 'There are already cases for this queue');

        msBugRegisterFormController.enterCase(JSON.serialize(newCase), systemInformation, 'France');

        foundCases = [SELECT Id, Subject FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assert(foundCases.size() == 1, 'More or less cases were created');
        System.assertEquals(foundCases[0].Subject, 'Hey France, I found a bug');
    }

    @IsTest
    private static void testRegisterFlexBug() {
        Case newCase = new Case();
        newCase.Subject = 'Hey Flex, I found a bug';
        newCase.Description += 'Tried Action:\n Some Action \n\n\nObserved Error:\nEverything chrashed';

        String systemInformation = '{}';
        QueueSobject queue = [SELECT Id, QueueId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.DeveloperName = 'UK_Flex' LIMIT 1];


        List<Case> foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assertEquals(0, foundCases.size(), 'There are already cases for this queue');

        msBugRegisterFormController.enterCase(JSON.serialize(newCase), systemInformation, 'Flex');

        foundCases = [SELECT Id, Subject  FROM Case WHERE OwnerId = :queue.QueueId AND RecordTypeId = :caseRecordTypeId];
        System.debug(foundCases);
        System.assert(foundCases.size() == 1, 'More or less cases were created');
        System.assertEquals(foundCases[0].Subject, 'Hey Flex, I found a bug');
    }
}