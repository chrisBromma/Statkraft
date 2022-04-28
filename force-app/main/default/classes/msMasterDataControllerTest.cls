/****************************************************************************************************
* Class msMasterDataControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   25.09.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   25.09.2018      	    Init version.
*****************************************************************************************************/

@IsTest
private class msMasterDataControllerTest {

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    static void testGetMasterData() {

        Meter__c testMeter = [SELECT Id, Name, Portfolio_ID__c FROM Meter__c WHERE Country__c = 'Germany' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();
        System.runAs(testUser) {
            msMasterDataController.MasterDataWrapper masterData = msMasterDataController.getMasterData(testMeter.Id);
            System.assert(!masterData.gUnits.isEmpty());
        }
        System.Test.stopTest();
    }

    @IsTest
    static void testSaveMasterData() {

        Meter__c testMeter = [SELECT Id, Name, Portfolio_ID__c FROM Meter__c WHERE Country__c = 'Germany' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        String srId = 'S1234567891';
        String trId = 'T1234567891';

        System.Test.startTest();
        System.runAs(testUser) {
            msMasterDataController.MasterDataWrapper masterData = msMasterDataController.getMasterData(testMeter.Id);
            String redispatchBillingModel = masterData.redispatchBillingModelOptions.get(0).value;


            Map<Id, String> guIdToTrIdMap = new Map<Id, String>();
            Map<Id, String> guIdToSrIdMap = new Map<Id, String>();
            for (msMasterDataController.GUnitMasterData gu : masterData.gUnits) {
                guIdToTrIdMap.put(gu.unitId, trId);
                guIdToSrIdMap.put(gu.unitId, srId);
            }
            msMasterDataController.saveMasterData(testMeter.Id, redispatchBillingModel, guIdToTrIdMap, guIdToSrIdMap);
            Meter__c meter = [
                    SELECT Id, Current_Contract__r.Billing_Model_Redispatch__c
                    FROM Meter__c
                    WHERE Id = :testMeter.Id
                    LIMIT 1
            ];
            List<Generation_Unit__c> gUnits = [SELECT TR_ID__c FROM Generation_Unit__c WHERE Id IN :guIdToTrIdMap.keySet()];
            List<Meter2GenerationUnitRelationship__c> meter2GenerationUnitRelationships = [SELECT SR_ID__c FROM Meter2GenerationUnitRelationship__c WHERE Generator_Unit__c IN :guIdToSrIdMap.keySet()];
            System.assertEquals(redispatchBillingModel, meter.Current_Contract__r.Billing_Model_Redispatch__c);
            for(Generation_Unit__c gu : gUnits){
                System.assertEquals(trId, gu.TR_ID__c);
            }
            for (Meter2GenerationUnitRelationship__c m2g : meter2GenerationUnitRelationships) {
                System.assertEquals(trId, m2g.SR_ID__c);
            }
        }
        System.Test.stopTest();
    }

    @IsTest
    static void testSubmitChangeRequest() {
        Meter__c testMeter = [
                SELECT Id, Name, Current_Contract__c, Portfolio_ID__c
                FROM Meter__c
                WHERE Country__c = 'Germany' LIMIT 1
        ];
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        msMasterDataController.MasterDataChangeRequest existingData = new msMasterDataController.MasterDataChangeRequest();
        existingData.btrName = 'Statkraft';
        existingData.btrId = '1234567890';

        msMasterDataController.MasterDataChangeRequest newData = new msMasterDataController.MasterDataChangeRequest();
        newData.btrName = 'Statkraft Markets';
        newData.btrId = '12345678905523523';

        System.Test.startTest();
        System.runAs(testUser) {
            msMasterDataController.submitChangeRequest(testMeter.Id, existingData, newData);
        }
        System.Test.stopTest();

        Id contractId = testMeter.Current_Contract__c != null ? testMeter.Current_Contract__c : testMeter.Meters__r[0].Current_Contract__c;
        Case createdCase = [SELECT Reason FROM Case WHERE Contract__c = :contractId LIMIT 1];
        System.assertEquals(createdCase.Reason, msUtility.CASE_REASON_MASTER_DATA_CHANGE);
    }
}