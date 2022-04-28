@isTest
public with sharing class msEmailMessageHandlerTest {
    
    public static final Id ACC_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Account', 'Account').Id;
    public static final Id CONTRACT_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Contract__c', 'Contract_PPA').Id;
    public static final Id CASE_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Case', 'Legal_Case').Id;

    @testSetup static void setup(){
        fflib_SObjectUnitOfWork uow = (fflib_SObjectUnitOfWork) Application.UnitOfWork.newInstance();
        
        Account testAccount = msGranularTestDataFactory.createTestAccounts(1, 'Germany', ACC_RECORD_TYPE_ID)[0];
        Contact testContact = msGranularTestDataFactory.createTestContacts(1)[0];
        Contract__c testContract = msGranularTestDataFactory.createTestContracts(1, CONTRACT_RECORD_TYPE_ID, 'Germany', 'Long Term PPA',
        'Merchant PPA', null, '12345', 'RPI')[0];
        Case testCase = msGranularTestDataFactory.createTestCases(1, CASE_RECORD_TYPE_ID)[0];

        uow.registerNew(testAccount);
        uow.registerNew(testContact, Contact.AccountId, testAccount);
        uow.registerNew(testContract, Contract__c.Contract_Holder__c, testAccount);
        uow.registerNew(testCase, Case.AccountId, testAccount);
        uow.registerRelationship(testCase, Case.Contract__c, testContract);
        uow.registerRelationship(testCase, Case.ContactId, testContact);

        uow.commitWork();

        
    }

    @isTest static void testDeletionOfEmailFeedItems(){
        Case testCase = [SELECT Id FROM Case];

        //This is normally created after an Email Message is inserted via Outlook, however for a manual insert this does not trigger.
        FeedItem fi = new FeedItem (ParentId = testCase.Id, Type = 'EmailMessageEvent');
        insert fi;

        Test.startTest();

        EmailMessage em = new EmailMessage(ParentId = testCase.Id, Subject = 'testSubject',  fromAddress = 'test@test.com', ToIds = new List<Id>{UserInfo.getUserId()}, HtmlBody = 'this', Incoming = true);
        insert em;

    
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem WHERE ParentId = :testCase.Id], 'The EmailMessage Feed Item was not deleted.');
    }

    @isTest static void testNormalFeedItemNotDeleted(){
        Case testCase = [SELECT Id FROM Case];

        //This is normally created after an Email Message is inserted via Outlook, however for a manual insert this does not trigger.
        FeedItem fi = new FeedItem (ParentId = testCase.Id, Type = 'EmailMessageEvent');
        insert fi;

        //This is normally created after an Email Message is inserted via Outlook, however for a manual insert this does not trigger.
        FeedItem fiNotDeleted = new FeedItem (ParentId = testCase.Id, Body = 'Test 123');
        insert fiNotDeleted;

        Test.startTest();

        EmailMessage em = new EmailMessage(ParentId = testCase.Id, Subject = 'testSubject',  fromAddress = 'test@test.com', ToIds = new List<Id>{UserInfo.getUserId()}, HtmlBody = 'this', Incoming = true);
        insert em;

        

        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM FeedItem WHERE ParentId = :testCase.Id], 'The normal Feed Item was not the only remaining Feed Item on the Case.');

    }

}