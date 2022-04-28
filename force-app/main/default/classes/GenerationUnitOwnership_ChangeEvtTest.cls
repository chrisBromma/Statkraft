/****************************************************************************************************
* Class GenerationUnitOwnership_ChangeEvtTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-08-18
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-08-18       	Init version.
*****************************************************************************************************/
@IsTest
private without sharing class GenerationUnitOwnership_ChangeEvtTest {
    static final Date today = Date.today();
    static final Date twoYearsAgoEnd = today.addYears(-2).addMonths(1);
    static final Date inOneYearStart = today.addYears(1).toStartOfMonth();
    /**
     * WARNING: If the Batch Size is too high, this results in high run time.
     *          If the run time is too high, the execution of the events will be skipped and the assertions will simply fail.
     *          This can be noticed by the code coverage not even showing the Trigger to have passed.
      */
    static final Integer BATCH_SIZE = 75;


    @IsTest
    private static void assignmentCreationTest_Insert() {
        disableTriggers();
        AssignmentTestData testData = test_Setup(BATCH_SIZE, true);
        Test.enableChangeDataCapture();
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);

        Test.startTest();
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    today,
                    null));
        }
        insert ownerships;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Generation_Unit__c> genUnitsWithAssignments = [
                SELECT Id, (SELECT Id FROM Generation_Unit_Assignments__r)
                FROM Generation_Unit__c
                WHERE Id IN :testData.genUnitIds
        ];
        for (Generation_Unit__c genUnit : genUnitsWithAssignments) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size());
        }
    }

    @IsTest
    private static void assignmentCreationTest_Update() {
        disableTriggers();
        AssignmentTestData testData = test_Setup(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;
        Test.enableChangeDataCapture();
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);

        Test.startTest();
        for (Generation_Unit_Ownership__c ownership : ownerships) {
            ownership.Start_Date__c = testData.currentContract.Start_Date__c;
            ownership.End_Date__c = testData.currentContract.End_Date__c;
        }
        update ownerships;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Generation_Unit__c> genUnitsWithAssignments = [
                SELECT Id, (SELECT Id FROM Generation_Unit_Assignments__r)
                FROM Generation_Unit__c
                WHERE Id IN :testData.genUnitIds
        ];
        for (Generation_Unit__c genUnit : genUnitsWithAssignments) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size());
        }
    }

    @IsTest
    private static void assignmentCreationTest_Delete() {
        disableTriggers();
        AssignmentTestData testData = test_Setup(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;
        Test.enableChangeDataCapture();
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);

        Test.startTest();
        delete ownerships;
        Test.getEventBus().deliver();
        Test.stopTest();
        List<Generation_Unit__c> genUnitsWithAssignments = [
                SELECT Id, (SELECT Id FROM Generation_Unit_Assignments__r)
                FROM Generation_Unit__c
                WHERE Id IN :testData.genUnitIds
        ];
        for (Generation_Unit__c genUnit : genUnitsWithAssignments) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size());
        }
    }

    @IsTest
    private static void assignmentCreationTest_Undelete() {
        disableTriggers();
        AssignmentTestData testData = test_Setup(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    today,
                    null));
        }
        insert ownerships;
        delete ownerships;
        Test.enableChangeDataCapture();
        Test.getEventBus().deliver();
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);

        Test.startTest();
        undelete ownerships;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Generation_Unit__c> genUnitsWithAssignments = [
                SELECT Id, (SELECT Id FROM Generation_Unit_Assignments__r)
                FROM Generation_Unit__c
                WHERE Id IN :testData.genUnitIds
        ];
        for (Generation_Unit__c genUnit : genUnitsWithAssignments) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size());
        }
    }

    private class AssignmentTestData {
        Account currentOwner { get; set; }
        Contract__c currentContract { get; set; }
        Meter__c currentMeterBeforeClone { get; set; }
        Set<Id> genUnitIds { get; set; }

        public AssignmentTestData() {
            genUnitIds = new Set<Id>();
        }

        public List<Generation_Unit__c> getGenUnits() {
            return [
                    SELECT Id, (
                            SELECT Id, Generation_Unit_Ownership__r.Asset_Owner__c, Start_Date__c, End_Date__c, Contract__c
                            FROM Generation_Unit_Assignments__r
                            ORDER BY Start_Date__c ASC
                    )
                    FROM Generation_Unit__c
                    WHERE Id IN :this.genUnitIds
            ];
        }
    }

    private static AssignmentTestData test_Setup(Integer batchSize, Boolean closed) {
        AssignmentTestData testData = new AssignmentTestData();

        testData.currentOwner = createAccount('current Owner');
        insert testData.currentOwner;

        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnits.add(createGenerationUnit('Unit ' + i));
        }
        insert gUnits;

        for (Generation_Unit__c genUnitItem : gUnits) {
            testData.genUnitIds.add(genUnitItem.Id);
        }

        List<Contract__c> contracts = new List<Contract__c>();
        testData.currentContract = createContract(twoYearsAgoEnd, inOneYearStart, testData.currentOwner.Id);
        contracts.add(testData.currentContract);
        insert contracts;

        Date endDate = null;
        if (closed) {
            endDate = testData.currentContract.End_Date__c;
        }

        List<Meter__c> meters = new List<Meter__c>();
        testData.currentMeterBeforeClone = createMeter('current before cloning Meter');
        meters.add(testData.currentMeterBeforeClone);
        insert meters;

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        meterRegs.add(createRegistration(
                testData.currentContract.Id,
                testData.currentMeterBeforeClone.Id,
                testData.currentContract.Start_Date__c,
                endDate,
                true));
        insert meterRegs;

        List<Meter2GenerationUnitRelationship__c> m2Gs = new List<Meter2GenerationUnitRelationship__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            m2Gs.add(createM2G(
                    testData.currentMeterBeforeClone.Id,
                    genUnitItem.Id,
                    testData.currentContract.Start_Date__c,
                    endDate,
                    false));
        }
        insert m2Gs;

        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
    }

    private static Generation_Unit__c createGenerationUnit(String nameEntry) {
        return new Generation_Unit__c(
                Name = nameEntry,
                Annual_Production__c = 0,
                Installed_Capacity__c = 0,
                Country__c = 'Germany'
        );
    }

    private static Generation_Unit_Ownership__c createOwnership(Id accountId, Id genUnitId, Date startDate, Date endDate) {
        return new Generation_Unit_Ownership__c(
                Asset_Owner__c = accountId,
                Generation_Unit__c = genUnitId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder) {
        String status = 'Active';
        if (endDate < today) {
            status = 'Expired';
        } else if (today < startDate) {
            status = 'Draft';
        }
        return new Contract__c(
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = 'Will be overwritten',
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0
        );
    }

    private static Meter__c createMeter(String nameEntry) {
        return new Meter__c(
                Name = nameEntry,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'Germany'
        );
    }

    private static MeterRegistration__c createRegistration(Id contractId, Id meterId, Date startDate, Date endDate, Boolean active) {
        return new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contractId,
                Meter__c = meterId,
                Volume_Share__c = 100,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private static Meter2GenerationUnitRelationship__c createM2G(Id meterId, Id genUnitId, Date startDate, Date endDate, Boolean active) {
        return new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name Over 10',
                Generator_Unit__c = genUnitId,
                Meter__c = meterId,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__ChangeEvent.SObjectType);
    }
}