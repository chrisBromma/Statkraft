/**************************************************************************************************** 
* Class BatchUpdateTriggerCallerTest 
* 
*   Created By :   Fabian Murk (mindsquare AG) 
*   Create Date :   17.06.2021 
*   Description : 
* 
*   Modification Log: 
*   ------------------------------------------------------------------------------------------------- 
*   * Developer                        Date             Description 
*   * -----------------------------------------------------------------------------------------------                  
*   * Fabian Murk (mindsquare AG)      17.06.2021         Init version. 
*****************************************************************************************************/
@IsTest
public with sharing class BatchUpdateTriggerCallerTest {
    @TestSetup
    public static void testSetup(){
        User user = [SELECT Id FROM User WHERE IsActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 1];
        System.runAs(user){
            Account acc = new Account(Name = 'TestAccount', Customer_Type__c = 'C - Single country, single product owner');
            insert acc;
        }
    }
    @IsTest
    public static void testUpdate(){

        Account acc = [SELECT LastModifiedById FROM Account LIMIT 1];

        Test.startTest();
        Database.executeBatch(new BatchUpdateTriggerCaller('Account'));
        Test.stopTest();

        Account updatedAcc = [SELECT LastModifiedById FROM Account WHERE Id = :acc.Id];

        System.assertNotEquals(UserInfo.getUserId(), acc.LastModifiedById);
        System.assertEquals(UserInfo.getUserId(), updatedAcc.LastModifiedById);
    }
}