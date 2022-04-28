@IsTest
public with sharing class MarketPresenceHandlerTest {
    private static MarketPresenceHelper Helper = new MarketPresenceHelper();

    @TestSetup
    static void makeData(){
        Account acc = new Account(Name = 'TestAcc');
        insert acc;
        List<Market_Presence__c> marketPresences = new List<Market_Presence__c>{
            new Market_Presence__c(Name = 'Germany', Electricity_consumption_generation_p_a__c = 0, Account__c = acc.Id),
            new Market_Presence__c(Name = 'France', Electricity_consumption_generation_p_a__c = 0, Account__c = acc.Id),
            new Market_Presence__c(Name = 'Norway', Electricity_consumption_generation_p_a__c = null, Account__c = acc.Id)
        };
        insert marketPresences;
    }
    @IsTest()
    static void testElectricityGenerationCategorizationGWH300(){
        Market_Presence__c mp = [SELECT Id, Account__c FROM Market_Presence__c LIMIT 1];
        mp.Electricity_consumption_generation_p_a__c = Helper.GWH_300 + 1.0;
        
        Test.startTest();
        update mp;
        Test.stopTest();

        Account acc = [SELECT YearlyElectricityConsumption__c FROM Account WHERE Id = :mp.Account__c];
        System.assertEquals(Helper.GWH_CATEGORY_GREATER_300, acc.YearlyElectricityConsumption__c);
    }
    @IsTest
    static void testElectricityGenerationCategorizationGWH100(){
        Market_Presence__c mp = [SELECT Id, Account__c FROM Market_Presence__c LIMIT 1];
        mp.Electricity_consumption_generation_p_a__c = Helper.GWH_100;
        
        Test.startTest();
        update mp;
        Test.stopTest();

        Account acc = [SELECT YearlyElectricityConsumption__c FROM Account WHERE Id = :mp.Account__c];
        System.assertEquals(Helper.GWH_CATEGORY_100_TO_300, acc.YearlyElectricityConsumption__c);
    }
    @IsTest
    static void testElectricityGenerationCategorizationGWH50(){
        Market_Presence__c mp = [SELECT Id, Account__c FROM Market_Presence__c LIMIT 1];
        mp.Electricity_consumption_generation_p_a__c = Helper.GWH_50;
        
        Test.startTest();
        update mp;
        Test.stopTest();

        Account acc = [SELECT YearlyElectricityConsumption__c FROM Account WHERE Id = :mp.Account__c];
        System.assertEquals(Helper.GWH_CATEGORY_50_TO_100, acc.YearlyElectricityConsumption__c);
    }
    @IsTest
    static void testElectricityGenerationCategorizationGWH0(){
        Market_Presence__c mp = [SELECT Id, Account__c FROM Market_Presence__c LIMIT 1];
        mp.Electricity_consumption_generation_p_a__c = Helper.GWH_0+1;
        
        Test.startTest();
        update mp;
        Test.stopTest();

        Account acc = [SELECT YearlyElectricityConsumption__c FROM Account WHERE Id = :mp.Account__c];
        System.assertEquals(Helper.GWH_CATEGORY_0_TO_49, acc.YearlyElectricityConsumption__c);
    }
    @IsTest
    static void testElectricityGenerationCategorizationNull(){
        Market_Presence__c mp = [SELECT Id, Account__c FROM Market_Presence__c LIMIT 1];
        mp.Electricity_consumption_generation_p_a__c = Helper.GWH_0;
        
        Test.startTest();
        update mp;
        Test.stopTest();

        Account acc = [SELECT YearlyElectricityConsumption__c FROM Account WHERE Id = :mp.Account__c];
        System.assertEquals(null, acc.YearlyElectricityConsumption__c);
    }
}