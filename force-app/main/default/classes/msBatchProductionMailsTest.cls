/****************************************************************************************************
* Class msBatchProductionMailsTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   13.06.2019
*   Description	:	Test class for the batch class msBatchProductionMails
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare GmbH)	            13.06.2019       	Init version.
*****************************************************************************************************/
@IsTest
private with sharing class msBatchProductionMailsTest {

    private static final Integer BULK_SIZE = 1;
    private static final String MONTHLY_EMAIL_NOTIFICATION_TYPE = 'monthly_production_data';
    private static final Id CONTRACT_RECORD_TYPE = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName()
            .get('Contract_PPA').getRecordTypeId();

    @IsTest
    private static void shouldNotifyContacts() {
        msTestDataFactory.createTestPortalContext();
        SetupData setupData = new SetupData();
        setupData.createSettings();
        setupData.createMeters();
        setupData.createTestContracts();
        setupData.createSiteRoles();
        setupData.createMeterRegistration();
        msNotificationLogic.notificationWrapper testWrapper = new msNotificationLogic.notificationWrapper();
        testWrapper.messageType = 'monthly_production_data';
        testWrapper.userId = [SELECT Id, Name, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'].Id;
        testWrapper.subject = 'test Subject';
        testWrapper.body = 'test Body';
        List<msNotificationLogic.notificationWrapper> testList = new List<msNotificationLogic.notificationWrapper>{testWrapper};
        msNotificationLogic.debugModeWrapper debugModeTest = new msNotificationLogic.debugModeWrapper();
        msBatchProductionMails testBatch = new msBatchProductionMails(testList, debugModeTest);
        testBatch.portfolioIdToErrorLogMessage.put('test_portfolioID', 'test Error Message');
        debugModeTest.messageType = 'monthly_production_data';
        debugModeTest.userTargetId = testWrapper.userId;
        Test.startTest();
        HttpResponse responseSuccess = new HttpResponse();
        responseSuccess.setStatus('Ok');
        responseSuccess.setStatusCode(200);
        responseSuccess.setBody('blob');
        Map<String,HttpResponse> endpointToResponsesMap = new Map<String, HttpResponse>();
        Statkraft_API_Settings__mdt apiSettings = msUtility.getMetadata();
        endpointToResponsesMap.put(apiSettings.Production_Files_Endpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponsesMap));
        Database.executeBatch(testBatch);
        
        Test.stopTest();

    }

    private class SetupData {
        private Account acc = null;
        private List<Contact> contacts;
        private List<Meter__c> meters;
        private List<Site_Role__c> siteRoles;
        private List<Contract__c> contracts;
        private List<MeterRegistration__c> meterRegistrations;
        private List<msUserNotificationSetting__c> settings;

        private SetupData() {
            acc = [SELECT Id FROM Account LIMIT 1];
            contacts = [SELECT Id FROM Contact];
        }

        private void createMeters() {
            meters = new List<Meter__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                meters.add(createTestMeter(i));
            }
            insert meters;
        }

        private Meter__c createTestMeter(Integer index) {
            Meter__c meter = new Meter__c();
            meter.Name = 'Meter' + index;
            meter.Status__c = 'Active';
            meter.Country__c = 'Germany';
            meter.Portfolio_ID__c = 'as_de2_an_11210_windpark_hohenseefeld' + index + 'test';
            meter.Alternative_Meter_ID__c = 'ABCDEFGHIJK';
            return meter;
        }

        private void createSiteRoles() {
            siteRoles = new List<Site_Role__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                siteRoles.add(createSiteRole(i));
            }
            insert siteRoles;
        }

        private Site_Role__c createSiteRole(Integer index) {
            Site_Role__c siteRole = new Site_Role__c();
            siteRole.Meter__c = meters[index].Id;
            siteRole.Role__c = 'Customer Portal';
            siteRole.Start_Date__c = Date.today().addDays(-2);
            siteRole.End_Date__c = Date.today().addDays(2);
            siteRole.Contact__c = contacts[index].Id;
            return siteRole;
        }

        private void createTestContracts() {
            contracts = new List<Contract__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                contracts.add(createContract(i));
            }
            insert contracts;
        }

        private Contract__c createContract(Integer index) {
            Contract__c contract = new Contract__c();
            contract.Contract_Holder__c = acc.Id;
            contract.Name = 'TestName' + index;
            contract.RED_Contract_ID__c = 'TestContract' + index;
            contract.Approved__c = true;
            contract.Start_Date__c = Date.today().addDays(-10);
            contract.End_Date__c = Date.today().addDays(10);
            contract.Status__c = 'Active';
            contract.Country__c = 'Germany';
            contract.RecordTypeId = CONTRACT_RECORD_TYPE;
            return contract;
        }

        private void createMeterRegistration() {
            meterRegistrations = new List<MeterRegistration__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                meterRegistrations.add(createMeterRegistration(i));
            }
            insert meterRegistrations;
        }

        private MeterRegistration__c createMeterRegistration(Integer index) {
            MeterRegistration__c meterRegistration = new MeterRegistration__c();
            meterRegistration.Name = 'MeterRegistration' + index;
            meterRegistration.Meter__c = meters[index].Id;
            meterRegistration.Contract__c = contracts[index].Id;
            meterRegistration.Valid_from__c = Date.today().addDays(-2);
            meterRegistration.Valid_to__c = Date.today().addDays(2);
            return meterRegistration;
        }

        private void createSettings() {
            settings = new List<msUserNotificationSetting__c>();
            for(Integer i = 0; i < BULK_SIZE; i++) {
                settings.add(createSetting(i));
            }
            insert settings;
        }

        private msUserNotificationSetting__c createSetting(Integer index) {
            msUserNotificationSetting__c setting = new msUserNotificationSetting__c();
            setting.msContact__c = contacts[index].Id;
            setting.msNotificationType__c = MONTHLY_EMAIL_NOTIFICATION_TYPE;
            setting.msFileFormat__c = 'excel';
            setting.msIsEmail__c = true;
            return setting;
        }

    }
}