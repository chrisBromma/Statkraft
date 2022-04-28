/****************************************************************************************************
 * Class BatchUpdateGenerationUnitDetailsTest
 *
 *   Create By	:   Christian Gottlieb (mindsquare AG)
 *   Create Date	:   2021-07-08
 *   Description	:	---
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare AG)	            2021-07-08       	Init version.
 *****************************************************************************************************/

@IsTest
private class BatchUpdateGenerationUnitDetailsTest {
    private static final Id x_51_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName(
            'Generation_Unit_Details__c',
            'x_51_Details'
        )
        .Id;
    private static final Id Redispatch_Details_RECORD_TYPE_ID = Application.RecordTypes.byDeveloperName(
            'Generation_Unit_Details__c',
            'Redispatch_Details'
        )
        .Id;

    @IsTest
    static void activateGenerationUnitDetails_batchTest() {
        TriggerHandlerExtension.disableObject(Generation_Unit_Details__c.SObjectType);

        Integer BATCH_SIZE = 200;
        Date TODAY = Date.today();

        List<Generation_Unit__c> testGenerationUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            testGenerationUnits.add(
                new Generation_Unit__c(
                    Name = 'testGenerationUnit_' + i,
                    Status__c = 'Active',
                    Portfolio_ID__c = 'mt_de_an_11210_windpark_hohenseefeld' + i,
                    GU_X51_Compensation_3_1__c = true,
                    GU_X51_Compensation_4_2__c = false
                )
            );
        }
        insert testGenerationUnits;

        List<Generation_Unit_Details__c> generationUnitDetailsOld = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsNew = new List<Generation_Unit_Details__c>();
        List<Generation_Unit_Details__c> generationUnitDetailsFuture = new List<Generation_Unit_Details__c>();
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            generationUnitDetailsOld.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    TR_ID__c = 'TR1' + i,
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
            generationUnitDetailsNew.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    TR_ID__c = 'TR2' + i,
                    MaStR_ID__c = 'MASTR2',
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
            generationUnitDetailsFuture.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = Redispatch_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    TR_ID__c = 'TR3' + i,
                    MaStR_ID__c = 'MASTR1',
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
            generationUnitDetailsOld.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(-20),
                    End_Date__c = TODAY.addDays(-1),
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
            generationUnitDetailsNew.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY,
                    End_Date__c = TODAY.addDays(10),
                    X51_Compensation_3_1__c = false,
                    X51_Compensation_4_2__c = true,
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
            generationUnitDetailsFuture.add(
                new Generation_Unit_Details__c(
                    RecordTypeId = x_51_Details_RECORD_TYPE_ID,
                    Start_Date__c = TODAY.addDays(11),
                    End_Date__c = null,
                    X51_Compensation_3_1__c = true,
                    X51_Compensation_4_2__c = false,
                    Generation_Unit__c = testGenerationUnits[i].Id
                )
            );
        }

        List<Generation_Unit_Details__c> insertList = new List<Generation_Unit_Details__c>();
        insertList.addAll(generationUnitDetailsOld);
        insertList.addAll(generationUnitDetailsNew);
        insertList.addAll(generationUnitDetailsFuture);
        insert insertList;
        testGenerationUnits = [
            SELECT GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
            FROM Generation_Unit__c
            WHERE Id IN :testGenerationUnits
        ];

        for (Generation_Unit__c testGenerationUnit : testGenerationUnits) {
            System.assertEquals(true, testGenerationUnit.GU_X51_Compensation_3_1__c);
            System.assertEquals(false, testGenerationUnit.GU_X51_Compensation_4_2__c);
            System.assertEquals(null, testGenerationUnit.TR_ID__c);
            System.assertEquals(null, testGenerationUnit.MaStR_ID__c);
        }

        TriggerHandlerExtension.enableObject(Generation_Unit_Details__c.SObjectType);
        Test.startTest();
        Database.executeBatch(new BatchUpdateGenerationUnitDetails(), 200);
        Test.stopTest();

        testGenerationUnits = [
            SELECT GU_X51_Compensation_3_1__c, GU_X51_Compensation_4_2__c, TR_ID__c, MaStR_ID__c
            FROM Generation_Unit__c
            WHERE Id IN :testGenerationUnits
        ];

        //@TODO fix TR-ID assertion
        for (Integer i = 0; i < BATCH_SIZE; i++) {
            System.assertEquals(false, testGenerationUnits[i].GU_X51_Compensation_3_1__c);
            System.assertEquals(true, testGenerationUnits[i].GU_X51_Compensation_4_2__c);
            System.assertEquals('TR2' + i, testGenerationUnits[i].TR_ID__c);
            System.assertEquals('MASTR2', testGenerationUnits[i].MaStR_ID__c);
        }
    }
}