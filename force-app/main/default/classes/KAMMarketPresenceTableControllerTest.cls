@IsTest
public with sharing class KAMMarketPresenceTableControllerTest {
    @TestSetup
    public static void testSetup() {
        Account account = new Account(Name = 'TestAcc', Market_Presence__c = 'Germany;France;Italy');
        insert account;
    }
    @IsTest
    public static void testGetMarketPresence() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Object> marketPresences = KAMMarketPresenceTableController.getMarketPresence(acc.Id);
        Test.stopTest();

        // Should be 3 records, because for each country in Market_Presence__c one record is created by the trigger.
        System.assertEquals(3, marketPresences.size());
    }
    @IsTest
    public static void testUpdateMarketPresenceCountry() {
        Integer electricityConsumptionToSet = 100;
        Market_Presence__c marketPresence = [SELECT Id, Name FROM Market_Presence__c LIMIT 1];
        marketPresence.Electricity_consumption_generation_p_a__c = electricityConsumptionToSet;
        
        KAMMarketPresenceTableController.MarketPresenceWrapper mpWrapper = 
            new KAMMarketPresenceTableController.MarketPresenceWrapper(marketPresence);
        Test.startTest();
        KAMMarketPresenceTableController.updateMarketPresenceCountry(JSON.serialize(mpWrapper));
        Test.stopTest();

        Market_Presence__c marketPresenceUpdated = [
            SELECT Electricity_consumption_generation_p_a__c
            FROM Market_Presence__c
            WHERE Id = :marketPresence.Id
        ];
        System.assertEquals(
            electricityConsumptionToSet,
            marketPresenceUpdated.Electricity_consumption_generation_p_a__c
        );
    }
}