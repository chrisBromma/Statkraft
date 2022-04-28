/**
 * Created by Steffen Naundorf on 07.09.2021.
 */

@isTest
public without sharing class GuaranteeHandlerTest {
    @testSetup
    static void setup() {
        RollupSettings__c rupSetting = new RollupSettings__c(IsEnabled__c = true);
        insert rupSetting;

        Account testAccount = new Account();
        testAccount.Name = 'Test Account for Treasury';
        insert testAccount;

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
        //insert testLimit;

        Security_Limits__c parentLimit = new Security_Limits__c(
            Name = 'parent',
            Usage_BGs_EUR__c = 0,
            Usage_PCGs_EUR__c = 0,
            Total_Limit__c = 1000000000,
            Limit_BG__c = 10000000,
            Limit_PCG__C = 10000000
        );
        insert parentLimit;
        Security_Limits__c childLimit = new Security_Limits__c(
            Name = 'parent',
            Usage_BGs_EUR__c = 0,
            Usage_PCGs_EUR__c = 0,
            Limit_BG__c = 10000000,
            Limit_PCG__c = 10000000,
            Total_Limit__c = 1000000000,
            Parent_Limit__c = parentLimit.Id
        );
        insert childLimit;

        List<SK_Security__c> testGuarantees = new List<SK_Security__c>();
        for (Integer i = 0; i < 25; i++) {
            SK_Security__c testGuarantee = new SK_Security__c();
            testGuarantee.SK_On_behalf_of_Lookup__c = testAccount.Id;
            testGuarantee.SK_Issuing_Entity_Lookup__c = testAccount.Id;
            testGuarantee.SK_End_Date__c = Date.today().addYears(5);
            testGuarantee.SK_Initial_Start_date__c = Date.today();
            testGuarantee.SK_Guarantee_Limits__c = testLimit.Id;
            testGuarantee.SK_Notional_Amount__c = 10000;
            testGuarantee.CurrencyIsoCode = 'EUR';
            testGuarantee.SK_Guarantee_Record_Type__c = 'Bank Guarantee';
            testGuarantee.SK_Status__c = 'Expiring';
            testGuarantee.SK_Approved__c = true;
            testGuarantee.Security_Limits__c = childLimit.Id;
            //  testGuarantee.SK_Bank__c =testAccount.Id;
            testGuarantees.add(testGuarantee);
        }
        insert testGuarantees;
    }

    @isTest
    static void testInsert() {
        List<Security_Limits__c> limits = [SELECT Id, Usage_BGs_EUR__c, Usage_PCGs_EUR__c FROM Security_Limits__c];
        for (Security_Limits__c tempLimit : limits) {
            System.assertEquals(tempLimit.Usage_BGs_EUR__c, 250000);
        }
    }

    @isTest
    static void testUpdate() {
        SK_Security__c guaranteeBG = [
            SELECT Id, SK_Notional_Amount__c, Security_Limits__c
            FROM SK_Security__c
            WHERE SK_Guarantee_Record_Type__c = 'Bank Guarantee'
            LIMIT 1
        ];

        guaranteeBG.SK_Notional_Amount__c = 20000;
        Test.startTest();
        update guaranteeBG;
        Test.stopTest();

        List<Security_Limits__c> limits = [SELECT Id, Usage_BGs_EUR__c, Usage_PCGs_EUR__c FROM Security_Limits__c];
        for (Security_Limits__c tempLimit : limits) {
            System.assertEquals(tempLimit.Usage_BGs_EUR__c, 260000);
        }
    }

    @isTest
    static void testDelete() {
        SK_Security__c guaranteeBG = [
            SELECT Id, SK_Notional_Amount__c
            FROM SK_Security__c
            WHERE SK_Guarantee_Record_Type__c = 'Bank Guarantee'
            LIMIT 1
        ];

        Test.startTest();
        delete guaranteeBG;
        Test.stopTest();

        List<Security_Limits__c> limits = [SELECT Id, Usage_BGs_EUR__c, Usage_PCGs_EUR__c FROM Security_Limits__c];
        for (Security_Limits__c tempLimit : limits) {
            System.assertEquals(tempLimit.Usage_BGs_EUR__c, 240000);
        }
    }
}