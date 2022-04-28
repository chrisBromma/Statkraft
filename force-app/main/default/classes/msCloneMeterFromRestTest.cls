/****************************************************************************************************
* Class msCloneMeterFromRestTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2020-05-28
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2020-05-28       	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msCloneMeterFromRestTest {
    @TestSetup
    static void setup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    static void testClone() {
        Id recordId = [SELECT Id FROM Meter__c LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + recordId + '",' +
                '"clone_date": "' + Date.today().addDays(1) + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(params.containsKey('parent'));
        System.assert(params.get('parent') != null);
    }

    @IsTest
    static void testFailingSetupNoData() {
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        System.assert(response.statusCode == 500);
    }

    @IsTest
    static void testFailingSetupNoMeter() {
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"clone_date":"2020-12-12"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        System.assert(response.statusCode == 500);
    }

    @IsTest
    static void testFailingSetupNoCloneDate() {
        Id recordId = [SELECT Id FROM Meter__c LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter":"' + recordId + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        System.assert(response.statusCode == 500);
    }

    @IsTest
    static void testFailingSetupNotMeterId() {
        Id recordId = [SELECT Id FROM Account LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + recordId + '",' +
                '"clone_date": "' + Date.today().addDays(1) + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        System.assert(response.statusCode == 500);
    }

    @IsTest
    static void testFailingSetupWrongDateFormat() {
        Id recordId = [SELECT Id FROM Meter__c LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + recordId + '",' +
                '"clone_date": "01/01/2020"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());

        System.assert(response.statusCode == 500);
        System.assert(params.get('error') == 'The key clone_date is not a valid Date. Example of a Date: 2020-12-31');

    }

    @IsTest
    static void testFailingMalformedJSON() {
        Id recordId = [SELECT Id FROM Meter__c LIMIT 1].Id;
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter":"' + recordId + '}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();

        System.assert(response.statusCode == 500);
    }

    @IsTest
    static void testCloneSingleMeter() {
        Id recordId = [SELECT Id FROM Meter__c LIMIT 1].Id;
        List<Meter2GenerationUnitRelationship__c> mGURs = [
                SELECT Id, Valid_to__c
                FROM Meter2GenerationUnitRelationship__c
                WHERE Meter__c = :recordId
        ];
        for (Meter2GenerationUnitRelationship__c mGUR : mGURs) {
            mGUR.Valid_to__c = null;
        }
        update mGURs;

        Date cloneDate = Date.today().addDays(1);
        Date dateBeforeCloneDate = Date.today();
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + recordId + '",' +
                '"clone_date": "' + cloneDate + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();

        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(params.containsKey('parent'));
        System.assert(params.get('parent') != null);
        Id newRecordId = (Id) params.get('parent');

        Map<Id, Meter__c> metersAfterCloning = new Map<Id, Meter__c>([
                SELECT Id, Scheduled_for_Activation_on__c, Scheduled_Cloning_Date__c, Succeeding_Clone__c, Data_Migration_ID__c, Portfolio_ID__c, (SELECT Id, Data_Migration_ID__c, Valid_from__c, Valid_to__c FROM Meter_Registrations__r), (SELECT Id, Data_Migration_ID__c, Valid_from__c, Valid_to__c FROM Meter_Generator_Relationships__r), (SELECT Id, Data_Migration_ID__c, Start_Date__c FROM Site_Roles__r)
                FROM Meter__c
                WHERE Id IN (:recordId, :newRecordId)
        ]);
        Meter__c meterToClone = metersAfterCloning.get(recordId);
        Meter__c resultMeter = metersAfterCloning.get(newRecordId);
        System.assert(!resultMeter.Meter_Registrations__r.isEmpty());
        System.assert(!resultMeter.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultMeter.Site_Roles__r.isEmpty());
        System.assertEquals(null, resultMeter.Data_Migration_ID__c);
        System.assertEquals(null, resultMeter.Portfolio_ID__c);
        System.assertEquals(cloneDate, meterToClone.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultMeter.Scheduled_for_Activation_on__c);
        System.assertEquals(resultMeter.Id, meterToClone.Succeeding_Clone__c);
        for (MeterRegistration__c meterRegistration : meterToClone.Meter_Registrations__r) {
            System.assertEquals(dateBeforeCloneDate, meterRegistration.Valid_to__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : meterToClone.Meter_Generator_Relationships__r) {
            System.assertEquals(dateBeforeCloneDate, mGUR.Valid_to__c);
        }
        for (MeterRegistration__c meterRegistration : resultMeter.Meter_Registrations__r) {
            System.assertEquals(cloneDate, meterRegistration.Valid_from__c);
            System.assertEquals(null, meterRegistration.Data_Migration_ID__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : resultMeter.Meter_Generator_Relationships__r) {
            System.assertEquals(cloneDate, mGUR.Valid_from__c);
            System.assertEquals(null, mGUR.Data_Migration_ID__c);
        }
        for (Site_Role__c siteRole : resultMeter.Site_Roles__r) {
            System.assertEquals(cloneDate, siteRole.Start_Date__c);
            System.assertEquals(null, siteRole.Data_Migration_ID__c);
        }
    }

    @IsTest
    static void testCloneSharedMeterChild() {

        Meter__c parentMeter = new Meter__c();
        parentMeter.Data_Migration_ID__c = 'test';
        parentMeter.Sandbox_Migration_Id__c = 'test';
        insert parentMeter;

        Meter__c childMeter = new Meter__c();
        childMeter.Parent_Meter__c = parentMeter.Id;
        childMeter.Data_Migration_ID__c = 'test2';
        childMeter.Sandbox_Migration_Id__c = 'test2';
        insert childMeter;

        Meter__c preChildMeter = new Meter__c();
        preChildMeter.Data_Migration_ID__c = 'test2_CC2_cloned';
        preChildMeter.Succeeding_Clone__c = childMeter.Id;
        insert preChildMeter;

        Meter__c prePreChildMeter = new Meter__c();
        prePreChildMeter.Data_Migration_ID__c = 'test2_cloned';
        prePreChildMeter.Succeeding_Clone__c = preChildMeter.Id;
        insert prePreChildMeter;

        Meter__c childMeter2 = new Meter__c();
        childMeter2.Parent_Meter__c = parentMeter.Id;
        childMeter2.Data_Migration_ID__c = 'test2.1';
        childMeter2.Sandbox_Migration_Id__c = 'test2.1';
        insert childMeter2;

        Meter__c preChildMeter2 = new Meter__c();
        preChildMeter2.Data_Migration_ID__c = 'test2.1_cloned';
        preChildMeter2.Succeeding_Clone__c = childMeter2.Id;
        insert preChildMeter2;

        Meter__c childMeter3 = new Meter__c();
        childMeter3.Parent_Meter__c = parentMeter.Id;
        childMeter3.Data_Migration_ID__c = 'test2.2';
        childMeter3.Sandbox_Migration_Id__c = 'test2.2';
        insert childMeter3;


        List<Generation_Unit__c> turbines = [SELECT Id FROM Generation_Unit__c LIMIT 3];

        List<Meter2GenerationUnitRelationship__c> mGURs = new List<Meter2GenerationUnitRelationship__c>();
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3',
                Sandbox_Migration_Id__c = 'test3',
                Meter__c = childMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3_CC2_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = preChildMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = prePreChildMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.1',
                Sandbox_Migration_Id__c = 'test3.1',
                Meter__c = childMeter2.Id,
                Generator_Unit__c = turbines[1].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.1_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = preChildMeter2.Id,
                Generator_Unit__c = turbines[1].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.2',
                Sandbox_Migration_Id__c = 'test3.2',
                Meter__c = childMeter3.Id,
                Generator_Unit__c = turbines[2].Id));
        insert mGURs;


        List<Contact> randomContacts = [SELECT Id FROM Contact LIMIT 3];
        List<Site_Role__c> siteRoles = new List<Site_Role__c>();

        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = childMeter.Id,
                Data_Migration_ID__c = 'test4'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = preChildMeter.Id,
                Data_Migration_ID__c = 'test4_CC2_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = prePreChildMeter.Id,
                Data_Migration_ID__c = 'test4_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[1].Id,
                Meter__c = childMeter2.Id,
                Data_Migration_ID__c = 'test4.1'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[1].Id,
                Meter__c = preChildMeter2.Id,
                Data_Migration_ID__c = 'test4.1_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[2].Id,
                Meter__c = childMeter3.Id,
                Data_Migration_ID__c = 'test4.2'
        ));
        Site_Role__c roleToDelete = new Site_Role__c(
                Contact__c = randomContacts[2].Id,
                Meter__c = childMeter3.Id,
                Data_Migration_ID__c = 'test4.3',
                Start_Date__c = Date.today().addYears(1),
                Role__c = 'Customer Portal'
        );
        siteRoles.add(roleToDelete);
        insert siteRoles;


        Contract__c randomContract = [SELECT Id FROM Contract__c LIMIT 1];

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5',
                Sandbox_Migration_Id__c = 'test5'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = preChildMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5_CC2_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = prePreChildMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter2.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.1',
                Sandbox_Migration_Id__c = 'test5.1'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = preChildMeter2.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.1_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter3.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.2',
                Sandbox_Migration_Id__c = 'test5.2'
        ));
        insert meterRegs;

        Date cloneDate = Date.today().addDays(1);
        Date dateBeforeCloneDate = Date.today();
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + childMeter.Id + '",' +
                '"clone_date": "' + cloneDate + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();

        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(params.containsKey('parent'));
        System.assert(params.get('parent') != null);
        System.assert(params.get('children') != null);
        Id clonedMeterParentId = (Id) params.get('parent');
        List<Id> clonedMeterIds = new List<Id>();
        for (Object idItem : (List<Object>) params.get('children')) {
            clonedMeterIds.add((Id) idItem);
        }
        Map<Id, Meter__c> metersAfterCloning = new Map<Id, Meter__c>([
                SELECT
                        Id,
                        Scheduled_for_Activation_on__c,
                        Scheduled_Cloning_Date__c,
                        Succeeding_Clone__c,
                        Data_Migration_ID__c,
                        Portfolio_ID__c,
                        Sandbox_Migration_Id__c, (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Valid_from__c,
                                Valid_to__c,
                                Sandbox_Migration_Id__c
                        FROM Meter_Registrations__r
                ), (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Valid_from__c,
                                Valid_to__c,
                                Sandbox_Migration_Id__c
                        FROM Meter_Generator_Relationships__r
                ), (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Start_Date__c,
                                Sandbox_Migration_Id__c
                        FROM Site_Roles__r
                )
                FROM Meter__c
                WHERE Id IN (:childMeter.Id, :childMeter2.Id, :childMeter3.Id, :clonedMeterParentId, :parentMeter.Id)
                OR Id IN :clonedMeterIds
        ]);
        childMeter = metersAfterCloning.get(childMeter.Id);
        childMeter2 = metersAfterCloning.get(childMeter2.Id);
        childMeter3 = metersAfterCloning.get(childMeter3.Id);
        Meter__c resultChildMeter1 = metersAfterCloning.get(metersAfterCloning.get(childMeter.Id).Succeeding_Clone__c);
        Meter__c resultChildMeter2 = metersAfterCloning.get(metersAfterCloning.get(childMeter2.Id).Succeeding_Clone__c);
        Meter__c resultChildMeter3 = metersAfterCloning.get(metersAfterCloning.get(childMeter3.Id).Succeeding_Clone__c);
        parentMeter = metersAfterCloning.get(parentMeter.Id);
        Meter__c resultMeterParent = metersAfterCloning.get(clonedMeterParentId);
        System.assert(!resultChildMeter1.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter1.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter1.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter2.Scheduled_for_Activation_on__c);
        System.assert(!resultChildMeter2.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter2.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter2.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter2.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter2.Scheduled_for_Activation_on__c);
        System.assert(!resultChildMeter3.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter3.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter3.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter3.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter3.Scheduled_for_Activation_on__c);
        System.assertEquals(null, resultChildMeter3.Sandbox_Migration_Id__c);
        System.assertEquals('test2_CC3_cloned', childMeter.Data_Migration_ID__c);
        System.assertEquals('test2.1_CC2_cloned', childMeter2.Data_Migration_ID__c);
        System.assertEquals('test2.2_cloned', childMeter3.Data_Migration_ID__c);
        System.assertEquals('test2', resultChildMeter1.Data_Migration_ID__c);
        System.assertEquals('test2.1', resultChildMeter2.Data_Migration_ID__c);
        System.assertEquals('test2.2', resultChildMeter3.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter1.Portfolio_ID__c);
        System.assertEquals(null, resultChildMeter2.Portfolio_ID__c);
        System.assertEquals(null, resultChildMeter3.Portfolio_ID__c);
        System.assertEquals(resultMeterParent.Id, parentMeter.Succeeding_Clone__c);
        System.assertEquals(null, resultMeterParent.Sandbox_Migration_Id__c);
        System.assertEquals('test', resultMeterParent.Data_Migration_ID__c);
        System.assertEquals('test_cloned', parentMeter.Data_Migration_ID__c);
        System.assertEquals(null, resultMeterParent.Portfolio_ID__c);
        for (MeterRegistration__c meterRegistration : childMeter.Meter_Registrations__r) {
            System.assertEquals(dateBeforeCloneDate, meterRegistration.Valid_to__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : childMeter.Meter_Generator_Relationships__r) {
            System.assertEquals(dateBeforeCloneDate, mGUR.Valid_to__c);
        }
        for (MeterRegistration__c meterRegistration : resultChildMeter1.Meter_Registrations__r) {
            System.assertEquals(cloneDate, meterRegistration.Valid_from__c);
            System.assertEquals(null, meterRegistration.Sandbox_Migration_Id__c);
        }
        for (Meter2GenerationUnitRelationship__c resultmGUR : resultChildMeter1.Meter_Generator_Relationships__r) {
            System.assertEquals(cloneDate, resultmGUR.Valid_from__c);
            System.assertEquals(null, resultmGUR.Sandbox_Migration_Id__c);
        }
        for (Site_Role__c resultSiteRole : resultChildMeter1.Site_Roles__r) {
            System.assertEquals(cloneDate, resultSiteRole.Start_Date__c);
            System.assertEquals(null, resultSiteRole.Sandbox_Migration_Id__c);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Site_Role__c WHERE Id = :roleToDelete.Id]);
    }
    @IsTest
    static void testCloneSharedMeterChildWithoutCopyDataMigrationId() {

        Meter__c parentMeter = new Meter__c();
        parentMeter.Data_Migration_ID__c = 'test';
        parentMeter.Sandbox_Migration_Id__c = 'test';
        insert parentMeter;

        Meter__c childMeter = new Meter__c();
        childMeter.Parent_Meter__c = parentMeter.Id;
        childMeter.Data_Migration_ID__c = 'test2';
        childMeter.Sandbox_Migration_Id__c = 'test2';
        insert childMeter;

        Meter__c preChildMeter = new Meter__c();
        preChildMeter.Data_Migration_ID__c = 'test2_CC2_cloned';
        preChildMeter.Succeeding_Clone__c = childMeter.Id;
        insert preChildMeter;

        Meter__c prePreChildMeter = new Meter__c();
        prePreChildMeter.Data_Migration_ID__c = 'test2_cloned';
        prePreChildMeter.Succeeding_Clone__c = preChildMeter.Id;
        insert prePreChildMeter;

        Meter__c childMeter2 = new Meter__c();
        childMeter2.Parent_Meter__c = parentMeter.Id;
        childMeter2.Data_Migration_ID__c = 'test2.1';
        childMeter2.Sandbox_Migration_Id__c = 'test2.1';
        insert childMeter2;

        Meter__c preChildMeter2 = new Meter__c();
        preChildMeter2.Data_Migration_ID__c = 'test2.1_cloned';
        preChildMeter2.Succeeding_Clone__c = childMeter2.Id;
        insert preChildMeter2;

        Meter__c childMeter3 = new Meter__c();
        childMeter3.Parent_Meter__c = parentMeter.Id;
        childMeter3.Data_Migration_ID__c = 'test2.2';
        childMeter3.Sandbox_Migration_Id__c = 'test2.2';
        insert childMeter3;


        List<Generation_Unit__c> turbines = [SELECT Id FROM Generation_Unit__c LIMIT 3];

        List<Meter2GenerationUnitRelationship__c> mGURs = new List<Meter2GenerationUnitRelationship__c>();
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3',
                Sandbox_Migration_Id__c = 'test3',
                Meter__c = childMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3_CC2_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = preChildMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = prePreChildMeter.Id,
                Generator_Unit__c = turbines[0].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.1',
                Sandbox_Migration_Id__c = 'test3.1',
                Meter__c = childMeter2.Id,
                Generator_Unit__c = turbines[1].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.1_cloned',
                Sandbox_Migration_Id__c = null,
                Meter__c = preChildMeter2.Id,
                Generator_Unit__c = turbines[1].Id));
        mGURs.add(new Meter2GenerationUnitRelationship__c(
                Valid_from__c = Date.today(),
                Valid_to__c = null,
                Data_Migration_ID__c = 'test3.2',
                Sandbox_Migration_Id__c = 'test3.2',
                Meter__c = childMeter3.Id,
                Generator_Unit__c = turbines[2].Id));
        insert mGURs;


        List<Contact> randomContacts = [SELECT Id FROM Contact LIMIT 3];
        List<Site_Role__c> siteRoles = new List<Site_Role__c>();

        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = childMeter.Id,
                Data_Migration_ID__c = 'test4'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = preChildMeter.Id,
                Data_Migration_ID__c = 'test4_CC2_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[0].Id,
                Meter__c = prePreChildMeter.Id,
                Data_Migration_ID__c = 'test4_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[1].Id,
                Meter__c = childMeter2.Id,
                Data_Migration_ID__c = 'test4.1'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[1].Id,
                Meter__c = preChildMeter2.Id,
                Data_Migration_ID__c = 'test4.1_cloned'
        ));
        siteRoles.add(new Site_Role__c(
                Contact__c = randomContacts[2].Id,
                Meter__c = childMeter3.Id,
                Data_Migration_ID__c = 'test4.2'
        ));
        Site_Role__c roleToDelete = new Site_Role__c(
                Contact__c = randomContacts[2].Id,
                Meter__c = childMeter3.Id,
                Data_Migration_ID__c = 'test4.3',
                Start_Date__c = Date.today().addYears(1),
                Role__c = 'Customer Portal'
        );
        siteRoles.add(roleToDelete);
        insert siteRoles;


        Contract__c randomContract = [SELECT Id FROM Contract__c LIMIT 1];

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5',
                Sandbox_Migration_Id__c = 'test5'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = preChildMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5_CC2_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = prePreChildMeter.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter2.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.1',
                Sandbox_Migration_Id__c = 'test5.1'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = preChildMeter2.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.1_cloned'
        ));
        meterRegs.add(new MeterRegistration__c(
                Meter__c = childMeter3.Id,
                Contract__c = randomContract.Id,
                Valid_from__c = Date.today(),
                Data_Migration_ID__c = 'test5.2',
                Sandbox_Migration_Id__c = 'test5.2'
        ));
        insert meterRegs;

        Date cloneDate = Date.today().addDays(1);
        Date dateBeforeCloneDate = Date.today();
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + childMeter.Id + '",' +
                '"clone_date": "' + cloneDate + '","copy_Data_Migration_Id":"false"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();

        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(params.containsKey('parent'));
        System.assert(params.get('parent') != null);
        System.assert(params.get('children') != null);
        Id clonedMeterParentId = (Id) params.get('parent');
        List<Id> clonedMeterIds = new List<Id>();
        for (Object idItem : (List<Object>) params.get('children')) {
            clonedMeterIds.add((Id) idItem);
        }
        Map<Id, Meter__c> metersAfterCloning = new Map<Id, Meter__c>([
                SELECT
                        Id,
                        Scheduled_for_Activation_on__c,
                        Scheduled_Cloning_Date__c,
                        Succeeding_Clone__c,
                        Data_Migration_ID__c,
                        Portfolio_ID__c,
                        Sandbox_Migration_Id__c, (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Valid_from__c,
                                Valid_to__c,
                                Sandbox_Migration_Id__c
                        FROM Meter_Registrations__r
                ), (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Valid_from__c,
                                Valid_to__c,
                                Sandbox_Migration_Id__c
                        FROM Meter_Generator_Relationships__r
                ), (
                        SELECT
                                Id,
                                Data_Migration_ID__c,
                                Start_Date__c,
                                Sandbox_Migration_Id__c
                        FROM Site_Roles__r
                )
                FROM Meter__c
                WHERE Id IN (:childMeter.Id, :childMeter2.Id, :childMeter3.Id, :clonedMeterParentId, :parentMeter.Id)
                OR Id IN :clonedMeterIds
        ]);
        childMeter = metersAfterCloning.get(childMeter.Id);
        childMeter2 = metersAfterCloning.get(childMeter2.Id);
        childMeter3 = metersAfterCloning.get(childMeter3.Id);
        Meter__c resultChildMeter1 = metersAfterCloning.get(metersAfterCloning.get(childMeter.Id).Succeeding_Clone__c);
        Meter__c resultChildMeter2 = metersAfterCloning.get(metersAfterCloning.get(childMeter2.Id).Succeeding_Clone__c);
        Meter__c resultChildMeter3 = metersAfterCloning.get(metersAfterCloning.get(childMeter3.Id).Succeeding_Clone__c);
        parentMeter = metersAfterCloning.get(parentMeter.Id);
        Meter__c resultMeterParent = metersAfterCloning.get(clonedMeterParentId);
        System.assert(!resultChildMeter1.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter1.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter1.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter2.Scheduled_for_Activation_on__c);
        System.assert(!resultChildMeter2.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter2.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter2.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter2.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter2.Scheduled_for_Activation_on__c);
        System.assert(!resultChildMeter3.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter3.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter3.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter3.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter3.Scheduled_for_Activation_on__c);
        System.assertEquals(null, resultChildMeter3.Sandbox_Migration_Id__c);
        System.assertEquals('test2', childMeter.Data_Migration_ID__c);
        System.assertEquals('test2.1', childMeter2.Data_Migration_ID__c);
        System.assertEquals('test2.2', childMeter3.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter1.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter2.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter3.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter1.Portfolio_ID__c);
        System.assertEquals(null, resultChildMeter2.Portfolio_ID__c);
        System.assertEquals(null, resultChildMeter3.Portfolio_ID__c);
        System.assertEquals(resultMeterParent.Id, parentMeter.Succeeding_Clone__c);
        System.assertEquals(null, resultMeterParent.Sandbox_Migration_Id__c);
        System.assertEquals(null, resultMeterParent.Data_Migration_ID__c);
        System.assertEquals('test', parentMeter.Data_Migration_ID__c);
        System.assertEquals(null, resultMeterParent.Portfolio_ID__c);
        for (MeterRegistration__c meterRegistration : childMeter.Meter_Registrations__r) {
            System.assertEquals(dateBeforeCloneDate, meterRegistration.Valid_to__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : childMeter.Meter_Generator_Relationships__r) {
            System.assertEquals(dateBeforeCloneDate, mGUR.Valid_to__c);
        }
        for (MeterRegistration__c meterRegistration : resultChildMeter1.Meter_Registrations__r) {
            System.assertEquals(cloneDate, meterRegistration.Valid_from__c);
            System.assertEquals(null, meterRegistration.Sandbox_Migration_Id__c);
        }
        for (Meter2GenerationUnitRelationship__c resultmGUR : resultChildMeter1.Meter_Generator_Relationships__r) {
            System.assertEquals(cloneDate, resultmGUR.Valid_from__c);
            System.assertEquals(null, resultmGUR.Sandbox_Migration_Id__c);
        }
        for (Site_Role__c resultSiteRole : resultChildMeter1.Site_Roles__r) {
            System.assertEquals(cloneDate, resultSiteRole.Start_Date__c);
            System.assertEquals(null, resultSiteRole.Sandbox_Migration_Id__c);
        }
        System.assertEquals(0, [SELECT COUNT() FROM Site_Role__c WHERE Id = :roleToDelete.Id]);
    }

    @IsTest
    static void testCloneSharedMeterParent() {
        Meter__c childMeter = [SELECT Id FROM Meter__c LIMIT 1];
        Meter__c parentMeter = new Meter__c();
        insert parentMeter;
        childMeter.Parent_Meter__c = parentMeter.Id;
        update childMeter;

        List<Meter2GenerationUnitRelationship__c> mGURs = [SELECT Id, Valid_to__c FROM Meter2GenerationUnitRelationship__c WHERE Meter__c = :childMeter.Id];
        for (Meter2GenerationUnitRelationship__c mGUR : mGURs) {
            mGUR.Valid_to__c = null;
        }
        update mGURs;

        Date cloneDate = Date.today().addDays(1);
        Date dateBeforeCloneDate = Date.today();
        RestRequest request = new RestRequest();
        request.requestURI = Url.getSalesforceBaseUrl().toExternalForm() +
                '/Meter__c/Clone';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"meter": "' + parentMeter.Id + '",' +
                '"clone_date": "' + cloneDate + '"}');
        RestContext.request = request;
        RestContext.response = new RestResponse();

        Test.startTest();
        msCloneMeterFromRest.cloneMeter();
        RestResponse response = RestContext.response;
        Test.stopTest();

        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody.toString());
        System.assert(params.containsKey('parent'));
        System.assert(params.get('parent') != null);
        System.assert(params.get('children') != null);
        Id clonedMeterParentId = (Id) params.get('parent');
        List<Object> clonedMeterIds = (List<Object>) params.get('children');
        Id clonedMeterId = Id.valueOf((String) clonedMeterIds[0]);
        Map<Id, Meter__c> metersAfterCloning = new Map<Id, Meter__c>([
                SELECT Id, Scheduled_for_Activation_on__c, Scheduled_Cloning_Date__c, Succeeding_Clone__c, Data_Migration_ID__c, Portfolio_ID__c, (SELECT Id, Data_Migration_ID__c, Valid_from__c, Valid_to__c FROM Meter_Registrations__r), (SELECT Id, Data_Migration_ID__c, Valid_from__c, Valid_to__c FROM Meter_Generator_Relationships__r), (SELECT Id, Data_Migration_ID__c, Start_Date__c FROM Site_Roles__r)
                FROM Meter__c
                WHERE Id IN (:childMeter.Id, :clonedMeterId, :clonedMeterParentId, :parentMeter.Id)
        ]);
        childMeter = metersAfterCloning.get(childMeter.Id);
        Meter__c resultChildMeter = metersAfterCloning.get(clonedMeterId);
        parentMeter = metersAfterCloning.get(parentMeter.Id);
        Meter__c resultMeterParent = metersAfterCloning.get(clonedMeterParentId);
        System.assert(!resultChildMeter.Meter_Registrations__r.isEmpty());
        System.assert(!resultChildMeter.Meter_Generator_Relationships__r.isEmpty());
        System.assert(!resultChildMeter.Site_Roles__r.isEmpty());
        System.assertEquals(cloneDate, childMeter.Scheduled_Cloning_Date__c);
        System.assertEquals(cloneDate, resultChildMeter.Scheduled_for_Activation_on__c);
        System.assertEquals(resultChildMeter.Id, childMeter.Succeeding_Clone__c);
        System.assertEquals(null, resultChildMeter.Data_Migration_ID__c);
        System.assertEquals(null, resultChildMeter.Portfolio_ID__c);
        System.assertEquals(resultMeterParent.Id, parentMeter.Succeeding_Clone__c);
        System.assertEquals(null, resultMeterParent.Data_Migration_ID__c);
        System.assertEquals(null, resultMeterParent.Portfolio_ID__c);
        for (MeterRegistration__c meterRegistration : childMeter.Meter_Registrations__r) {
            System.assertEquals(dateBeforeCloneDate, meterRegistration.Valid_to__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : childMeter.Meter_Generator_Relationships__r) {
            System.assertEquals(dateBeforeCloneDate, mGUR.Valid_to__c);
        }
        for (MeterRegistration__c meterRegistration : resultChildMeter.Meter_Registrations__r) {
            System.assertEquals(cloneDate, meterRegistration.Valid_from__c);
            System.assertEquals(null, meterRegistration.Data_Migration_ID__c);
        }
        for (Meter2GenerationUnitRelationship__c mGUR : resultChildMeter.Meter_Generator_Relationships__r) {
            System.assertEquals(cloneDate, mGUR.Valid_from__c);
            System.assertEquals(null, mGUR.Data_Migration_ID__c);
        }
        for (Site_Role__c siteRole : resultChildMeter.Site_Roles__r) {
            System.assertEquals(cloneDate, siteRole.Start_Date__c);
            System.assertEquals(null, siteRole.Data_Migration_ID__c);
        }
    }
}