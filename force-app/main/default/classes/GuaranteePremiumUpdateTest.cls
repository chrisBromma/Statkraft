/**
 * Created by Steffen Naundorf on 07.07.2021.
 */

@isTest
public with sharing class GuaranteePremiumUpdateTest {
    @testSetup
    static void setup() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account for Treasury';
        insert testAccount;


        SK_Security_Premium__c premium = new SK_Security_Premium__c();
        premium.On_behalf_of_Entity__c = testAccount.Id;
        premium.Issuing_Entity__c = testAccount.Id;
        premium.Duration_lower_range__c = 3;
        premium.Validity_start_date__c = Date.today().addDays(-50);
        premium.Guarantee_Premium__c = 5;
        insert premium;

        SK_Guarantee_Limits__c testLimit = new SK_Guarantee_Limits__c();
        testLimit.SK_M_Limit__c = 2600000000.0;
        testLimit.SK_M_BG_Limit__c = 500000000.0;
        testLimit.SK_MT_Limit__c = 800000000.0;
        testLimit.SK_MT_Usage_PCGs__c = 683928690.58;
        testLimit.SK_MT_BG_Limit__c = 115000000.0;
        testLimit.SK_MT_Usage_BGs__c = 52525028.0;
        testLimit.SK_MC_Limit__c = 1400000000.0;
        testLimit.SK_MC_Usage_PCGs__c = 1025834422.76;
        testLimit.SK_MC_Usage_PCGs__c = 100927998.19;
        testLimit.SK_MC_BG_Limit__c = 235000000.0;
        testLimit.SK_Asset_Usage_PCGs__c = 148761000.0;
        testLimit.SK_Other_Usage_BGs__c = 2308217.03;
        insert testLimit;

        List<SK_Security__c> testGuarantees = new List<SK_Security__c>();
        for (Integer i = 0; i < 50; i++) {
            SK_Security__c testGuarantee = new SK_Security__c();
            testGuarantee.SK_On_behalf_of_Lookup__c = testAccount.Id;
            testGuarantee.SK_Issuing_Entity_Lookup__c = testAccount.Id;
            testGuarantee.SK_End_Date__c = Date.today().addYears(5);
            testGuarantee.SK_Initial_Start_date__c = Date.today();
            testGuarantee.SK_Guarantee_Limits__c = testLimit.Id;
            testGuarantees.add(testGuarantee);
        }
        insert testGuarantees;
    }
    @isTest static void testUpdateOfGuarantees() {
        SK_Security_Premium__c testPremium = [SELECT Id, Guarantee_Premium__c FROM SK_Security_Premium__c LIMIT 1];

        List<GuaranteePremiumUpdate.FlowInputs> inputs = new List<GuaranteePremiumUpdate.FlowInputs>();
        GuaranteePremiumUpdate.FlowInputs input = new GuaranteePremiumUpdate.FlowInputs();
        input.premiumId = testPremium.Id;
        inputs.add(input);
        List<SK_Security__c> testGuarantees = [
                SELECT Id
                FROM SK_Security__c
                WHERE SK_Guarantee_Fee_Percent__c = :testPremium.Guarantee_Premium__c
        ];
        System.assertEquals(0, testGuarantees.size());

        Test.startTest();
        GuaranteePremiumUpdate.updateGuarantees(inputs);
        Test.stopTest();

        List<SK_Security__c> testGuarantees2 = [
                SELECT Id
                FROM SK_Security__c
                WHERE SK_Guarantee_Fee_Percent__c = :testPremium.Guarantee_Premium__c
        ];
        System.assertEquals(50, testGuarantees2.size());


    }
}