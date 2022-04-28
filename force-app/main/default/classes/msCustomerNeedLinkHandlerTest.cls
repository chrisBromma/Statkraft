/****************************************************************************************************
* Class msCustomerNeedLinkHandlerTest.cls
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
public with sharing class msCustomerNeedLinkHandlerTest {
    @TestSetup
    static void makeData(){
        RollupSettings__c rupSetting = new RollupSettings__c(IsEnabled__c = true);
        insert rupSetting;

        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Product_Need__c pn1 = new Product_Need__c();
        pn1.Name = 'Pn1';
        pn1.Country__c = 'Germany';
        pn1.Product_Line__c = 'Physical route-to-market services [Market Access]';
        pn1.Product_Category__c = 'Real-time asset dispatch';
        pn1.Product_Owner__c = 'MAN';
        pn1.Contact_Person__c = UserInfo.getUserId();
        insert pn1;
    }
    @IsTest
    static void testCustomerNeedLinkRollup(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Need__c pn = [SELECT Id FROM Product_Need__c LIMIT 1];
        Product_Need_Link__c newProductNeedLink = new Product_Need_Link__c(Product_Need__c = pn.Id, Account__c = acc.Id);
        
        Test.startTest();
        insert newProductNeedLink;
        Test.stopTest();

        Account updatedAcc = [SELECT number_of_Customer_Needs__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, updatedAcc.number_of_Customer_Needs__c);
    }
}