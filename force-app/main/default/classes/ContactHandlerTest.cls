/****************************************************************************************************
* Class ContactHandlerTest.cls
*
*   Created By  :   Fabian Murk (mindsquare AG)
*   Create Date	:   2022-2-7
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                                            Date                        Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Murk (mindsquare AG)                          2022-2-7     Initial Commit
*****************************************************************************************************/
@IsTest
public with sharing class ContactHandlerTest {
    @TestSetup
    static void makeData(){
        RollupSettings__c rupSetting = new RollupSettings__c(IsEnabled__c = true);
        insert rupSetting;

        Account acc = new Account(Name = 'Test Acc');
        insert acc;
    }
    @IsTest
    public static void testNumberOfContactsRollup() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id);
        
        Test.startTest();
        insert con;
        Test.stopTest();

        Account updatedAcc = [SELECT number_of_contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, updatedAcc.number_of_contacts__c);
    }
}