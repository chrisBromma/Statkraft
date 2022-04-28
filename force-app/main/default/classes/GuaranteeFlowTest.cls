/****************************************************************************************************
* Class GuaranteeFlowTest.cls
*
*   Created By  :   Fabian Murk (mindsquare AG)
*   Create Date	:   18-1-2022
*   Description	:	Test Class for "Guarantee - Before Upsert" Flow
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                                            Date                Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Murk (mindsquare AG)                          18-1-2022             Initial Commit
*****************************************************************************************************/

@IsTest
public with sharing class GuaranteeFlowTest {
    private static List<String> generalClassValuesForCallMechanismConditional =
        new List<String>{
            'EEG',
            'FRA PPA',
            'PL PPA',
            'SPA PPA',
            'IRL PPA',
            'UK PPA'
        };

    @TestSetup
    static void makeData(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;

    }
    @IsTest static void testCallMechanismAutomation_Conditional() {
        // Call Mechanism should be set to 'Conditional' for the given General Class values
        Account acc = [SELECT Id FROM Account][0];
        List<SK_Security__c> guaranteesToInsert = new List<SK_Security__c>();
        for (String gcValue : generalClassValuesForCallMechanismConditional) {
            SK_Security__c guarantee = new SK_Security__c(
                SK_Account__c = acc.Id,
                SK_Notional_Amount__c = 1,
                SK_Initial_Start_date__c = Date.today(),
                SK_No_End_Date__c = true,
                SK_General_Class__c = gcValue
            );
            guaranteesToInsert.add(guarantee);
        }

        Test.startTest();
        insert guaranteesToInsert;
        Test.stopTest();

        List<SK_Security__c> insertedGuarantees = [SELECT Call_mechanism__c FROM SK_Security__c];
        for (SK_Security__c insertedGuarantee : insertedGuarantees) {
            System.assertEquals('Conditional', insertedGuarantee.Call_mechanism__c);
        }
    }
    @IsTest static void testCallMechanismAutomation_NoChange() {
        // The Call Mechanism shouldn't be changed if it is already filled in
        Account acc = [SELECT Id FROM Account][0];
        List<SK_Security__c> guaranteesToInsert = new List<SK_Security__c>();
        for (String gcValue : generalClassValuesForCallMechanismConditional) {
            SK_Security__c guarantee = new SK_Security__c(
                SK_Account__c = acc.Id,
                SK_Notional_Amount__c = 1,
                SK_Initial_Start_date__c = Date.today(),
                SK_No_End_Date__c = true,
                SK_General_Class__c = gcValue,
                Call_Mechanism__c = 'On-demand'
            );
            guaranteesToInsert.add(guarantee);
        }

        Test.startTest();
        insert guaranteesToInsert;
        Test.stopTest();

        List<SK_Security__c> insertedGuarantees = [SELECT Call_mechanism__c FROM SK_Security__c];
        for (SK_Security__c insertedGuarantee : insertedGuarantees) {
            System.assertEquals('On-demand', insertedGuarantee.Call_mechanism__c);
        }
    }
}