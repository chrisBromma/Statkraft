/****************************************************************************************************
* Class BalancingCircleHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-02-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-02-16       	Init version.
*****************************************************************************************************/

@IsTest
private class BalancingCircleHandlerTest {

    static List<String> validBalancingCircleNames = new List<String>();
    @TestSetup
    static void setup() {

    }

    static void staticSetup() {
        List<PicklistEntry> picklistEntriesBalancingCircle
                = MeterRegistration__c.Balancing_Circle__c.getDescribe().getSobjectField().getDescribe().getPicklistValues();
        for (PicklistEntry entryItem : picklistEntriesBalancingCircle) {
            validBalancingCircleNames.add(entryItem.value);
        }
    }


    @IsTest
    static void insertTest() {
        staticSetup();
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        Test.startTest();
        insert newCircle;
        Test.stopTest();
        newCircle = [SELECT Name, Deduplication_Id__c FROM Balancing_Circle__c WHERE Id = :newCircle.Id LIMIT 1];
        System.assert(newCircle.Name == validBalancingCircleNames[0]);
        System.assert(newCircle.Deduplication_Id__c == newCircle.Name);
    }
    @IsTest
    static void updateTest() {
        staticSetup();
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        insert newCircle;
        Test.startTest();
        newCircle.Name = validBalancingCircleNames[1];
        update newCircle;
        Test.stopTest();
        newCircle = [SELECT Name, Deduplication_Id__c FROM Balancing_Circle__c WHERE Id = :newCircle.Id LIMIT 1];
        System.assert(newCircle.Name == validBalancingCircleNames[1]);
        System.assert(newCircle.Deduplication_Id__c == newCircle.Name);
    }
    @IsTest
    static void deleteTest() {
        staticSetup();
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        insert newCircle;
        Test.startTest();
        delete newCircle;
        Test.stopTest();
        newCircle = [
                SELECT Name, Deduplication_Id__c, IsDeleted
                FROM Balancing_Circle__c
                WHERE Id = :newCircle.Id LIMIT 1 ALL ROWS
        ];
        System.assert(newCircle.IsDeleted);
    }
    @IsTest
    static void blockDuplicateInsertTest() {
        staticSetup();
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        Balancing_Circle__c duplicateCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        List<Balancing_Circle__c> listToInsert = new List<Balancing_Circle__c>();
        listToInsert.add(newCircle);
        listToInsert.add(duplicateCircle);
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(listToInsert,false);
        Test.stopTest();
        Integer successes = 0;
        Integer failures = 0;
        for(Database.SaveResult result : results) {
            if(result.isSuccess()) {
                successes++;
            } else {
                failures++;
            }
        }
        System.assert(successes == 1);
        System.assert(failures == 1);
    }
    @IsTest
    static void blockDuplicateUpdateTest() {
        staticSetup();
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        Balancing_Circle__c duplicateCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[1]
        );
        List<Balancing_Circle__c> listToInsert = new List<Balancing_Circle__c>();
        listToInsert.add(newCircle);
        listToInsert.add(duplicateCircle);
        insert listToInsert;
        Test.startTest();
        duplicateCircle.Name = validBalancingCircleNames[0];
        Database.SaveResult result = Database.update(duplicateCircle, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
    }

    @IsTest
    static void blockNonSupportedEntryOnInsert() {
        staticSetup();
        String invalidCircleName = 'test';
        while(validBalancingCircleNames.contains(invalidCircleName)) {
            invalidCircleName += 'test';
        }
        Balancing_Circle__c invalidCircle = new Balancing_Circle__c(
                Name = invalidCircleName
        );
        Test.startTest();
        Database.SaveResult result = Database.insert(invalidCircle,false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors()[0].message.contains(Label.validationErrorBalancingCircleNameIncorrect));
    }

    @IsTest
    static void blockNonSupportedEntryOnUpdate() {
        staticSetup();
        String invalidCircleName = 'test';
        while(validBalancingCircleNames.contains(invalidCircleName)) {
            invalidCircleName += 'test';
        }
        Balancing_Circle__c newCircle = new Balancing_Circle__c(
                Name = validBalancingCircleNames[0]
        );
        insert newCircle;
        Test.startTest();
        newCircle.Name = invalidCircleName;
        Database.SaveResult result = Database.update(newCircle,false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors()[0].message.contains(Label.validationErrorBalancingCircleNameIncorrect));
    }
}