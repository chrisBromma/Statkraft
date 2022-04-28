/**
 * Created by Steffen Naundorf on 08.09.2021.
 */

@IsTest
private class GenerationUnitsDetailsHandlerTest {
    private static final String x_51_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Generation_Unit_Details__c', 'x_51_Details').Id;
    private static final String Redispatch_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName('Generation_Unit_Details__c', 'Redispatch_Details').Id;

    @IsTest
    static void insert_PositiveTest() {
        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = true,
                    GU_X51_Compensation_4_2__c = false
            ));
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsOld = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsFuture = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    X51_Compensation_3_1__c = false,
                    X51_Compensation_4_2__c = true,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    TR_ID__c = 'TR2',
                    MaStR_ID__c = 'MASTR2',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsOld);
        insertList.addAll(generationUnitDetailsNew);
        insertList.addAll(generationUnitDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testGenerationUnits = [
                SELECT  GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals('TR2', testGenerationUnit.TR_ID__c);
            System.assertEquals('MASTR2', testGenerationUnit.MaStR_ID__c);
        }
    }

    @IsTest
    static void insert_NegativeFutureTest() {
        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = false,
                    GU_X51_Compensation_4_2__c = true,
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1'
            ));
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsOld = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsFuture = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsOld);
        insertList.addAll(generationUnitDetailsNew);
        insertList.addAll(generationUnitDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testGenerationUnits = [
                SELECT   GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals('TR1', testGenerationUnit.TR_ID__c);
            System.assertEquals('MASTR1', testGenerationUnit.MaStR_ID__c);
        }
    }

    @IsTest
    static void insert_NegativePastTest() {
        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = true,
                    GU_X51_Compensation_4_2__c = false,
                    TR_ID__c = 'TR2',
                    MaStR_ID__c = 'MASTR2'
            ));
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsOld = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsFuture = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    X51_Compensation_3_1__c = false,
                    X51_Compensation_4_2__c = true,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsOld);
        insertList.addAll(generationUnitDetailsNew);
        insertList.addAll(generationUnitDetailsFuture);

        Test.startTest();

        insert insertList;

        Test.stopTest();

        testGenerationUnits = [
                SELECT GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals('TR2', testGenerationUnit.TR_ID__c);
            System.assertEquals('MASTR2', testGenerationUnit.MaStR_ID__c);
        }
    }

    @IsTest
    static void update_PositivePastTest() {
        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = false,
                    GU_X51_Compensation_4_2__c = true
            ));
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsOld = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    X51_Compensation_3_1__c = false,
                    X51_Compensation_4_2__c = true,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsOld.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    TR_ID__c = 'TR2',
                    MaStR_ID__c = 'MASTR2',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsOld);
        insertList.addAll(generationUnitDetailsNew);
        insert insertList;

        Test.startTest();

        for (Generation_Unit_Details__c detailsItem : generationUnitDetailsNew) {
            detailsItem.Start_Date__c = TODAY.addDays(1);
        }
        for (Generation_Unit_Details__c detailsItem : generationUnitDetailsOld) {
            detailsItem.End_Date__c = TODAY;
        }
        List<Generation_Unit_Details__c> updateList = new List<Generation_Unit_Details__c>();
        updateList.addAll(generationUnitDetailsNew);
        updateList.addAll(generationUnitDetailsOld);

        update updateList;

        Test.stopTest();

        testGenerationUnits = [
                SELECT  GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals('TR1', testGenerationUnit.TR_ID__c);
            System.assertEquals('MASTR1', testGenerationUnit.MaStR_ID__c);
        }
    }

    @IsTest
    static void update_PositiveFutureTest() {
        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = false,
                    GU_X51_Compensation_4_2__c = true
            ));
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsFuture = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    X51_Compensation_3_1__c = false,
                    X51_Compensation_4_2__c = true,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsNew.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    TR_ID__c = 'TR1',
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
            generationUnitDetailsFuture.add(new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    TR_ID__c = 'TR2',
                    MaStR_ID__c = 'MASTR2',
                    Generation_Unit__c = testGenerationUnits[i].Id
            ));
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsNew);
        insertList.addAll(generationUnitDetailsFuture);
        insert insertList;

        Test.startTest();

        for (Generation_Unit_Details__c detailsItem : generationUnitDetailsNew) {
            detailsItem.Start_Date__c = TODAY.addDays(-2);
            detailsItem.End_Date__c = TODAY.addDays(-1);
        }
        for (Generation_Unit_Details__c detailsItem : generationUnitDetailsFuture) {
            detailsItem.Start_Date__c = TODAY;
        }
        List<Generation_Unit_Details__c> updateList = new List<Generation_Unit_Details__c>();
        updateList.addAll(generationUnitDetailsNew);
        updateList.addAll(generationUnitDetailsFuture);

        update updateList;

        Test.stopTest();

        testGenerationUnits = [
                SELECT  GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
                FROM Generation_Unit__c
                WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals('TR2', testGenerationUnit.TR_ID__c);
            System.assertEquals('MASTR2', testGenerationUnit.MaStR_ID__c);
        }
    }

    @IsTest
    static void blockTimeOverlaps_insertTest() {
        Generation_Unit__c testGenerationUnit = new Generation_Unit__c(
                Name = 'testGenerationUnit_',
                Status__c = 'Active'
        );
        insert testGenerationUnit;

        List<Generation_Unit_Details__c> detailsToInsert = new List<Generation_Unit_Details__c>();
        Generation_Unit_Details__c firstDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today()
        );
        Generation_Unit_Details__c overlappingDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today(),
                End_Date__c = null
        );

        detailsToInsert.add(firstDetails);
        detailsToInsert.add(overlappingDetails);

        Test.startTest();

        Boolean error = false;
        try {
            insert detailsToInsert;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_GU_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }

    @IsTest
    static void blockTimeOverlaps_updateTest() {
        Generation_Unit__c testGenerationUnit = new Generation_Unit__c(
                Name = 'testGenerationUnit_',
                Status__c = 'Active'
        );
        insert testGenerationUnit;

        List<Generation_Unit_Details__c> detailsToInsert = new List<Generation_Unit_Details__c>();
        Generation_Unit_Details__c firstDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today().addDays(1)
        );
        Generation_Unit_Details__c overlappingDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today().addDays(2),
                End_Date__c = null
        );
        detailsToInsert.add(firstDetails);
        detailsToInsert.add(overlappingDetails);
        insert detailsToInsert;

        Test.startTest();

        firstDetails.End_Date__c = Date.today().addDays(-1);
        overlappingDetails.Start_Date__c = Date.today().addDays(-1);
        Boolean error = false;

        try {
            update detailsToInsert;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_GU_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }

    @IsTest
    static void blockTimeOverlaps_undeleteTest() {
        Generation_Unit__c testGenerationUnit = new Generation_Unit__c(
                Name = 'testGenerationUnit_',
                Status__c = 'Active'
        );
        insert testGenerationUnit;

        List<Generation_Unit_Details__c> details = new List<Generation_Unit_Details__c>();
        Generation_Unit_Details__c firstDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today().addDays(-1),
                End_Date__c = Date.today().addDays(1)
        );
        Generation_Unit_Details__c overlappingDetails = new Generation_Unit_Details__c(
                Generation_Unit__c = testGenerationUnit.Id,
                Start_Date__c = Date.today().addDays(1),
                End_Date__c = null
        );
        details.add(firstDetails);
        details.add(overlappingDetails);
        insert firstDetails;
        delete firstDetails;
        insert overlappingDetails;
        delete overlappingDetails;

        Test.startTest();

        Boolean error = false;
        try {
            undelete details;
            System.assert(false, 'An Error should have happened');
        } catch (Exception e) {
            error = true;
            System.assert(e.getMessage().contains(Label.Validation_GU_Details_Timeline), 'An unexpected error happened: ' + e.getMessage());
        }

        Test.stopTest();

        System.assert(error, 'An error should have been caught');
    }
}