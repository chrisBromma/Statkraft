/****************************************************************************************************
* Class msKAMProductNeedSelectorControllerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   28.10.2020
*   Description	:
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Steffen Naundorf (mindsquare GmbH)   28.10.2020      	    Init version.
*****************************************************************************************************/
@isTest
public without sharing class msKAMProductNeedSelectorControllerTest {
    @TestSetup public static void testSetup() {
        List<Product_Need__c> productsToInsert = new List<Product_Need__c>();

        Product_Need__c pn1 = new Product_Need__c();
        pn1.Name = 'Pn1';
        pn1.Country__c = 'Germany';
        pn1.Product_Line__c = 'Physical route-to-market services [Market Access]';
        pn1.Product_Category__c = 'Real-time asset dispatch';
        pn1.Product_Owner__c = 'MAN';
        pn1.Contact_Person__c = UserInfo.getUserId();
        productsToInsert.add(pn1);

        Product_Need__c pn2 = new Product_Need__c();
        pn2.Name = 'Pn2';
        pn2.Country__c = 'France';
        pn2.Product_Line__c = 'Upstream Origination';
        pn2.Product_Category__c = 'Upstream GoOs';
        pn2.Product_Owner__c = 'MEN';
        productsToInsert.add(pn2);
        insert productsToInsert;

        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Customer_Type__c = 'A - Multi-country';
        acc.Customer_Segment_industry__c = 'Large industrials';
        acc.BillingCountry = 'France';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addMonths(1);
        opp.StageName = 'Proposal';
        opp.Name = 'My Opp1';
        insert opp;

    }

    @isTest
    public static void testGetProductMatrix() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        msKAMProductNeedSelectorController.getProductMatrix(opp.Id);
    }

    @isTest
    public static void testSaveLink() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product_Need__c pn = [SELECT Id FROM Product_Need__c LIMIT 1];

        msKAMProductNeedSelectorController.saveLink(opp.Id, pn.Id, '');
    }

    @isTest
    public static void testDeleteLink() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product_Need__c pn = [SELECT Id FROM Product_Need__c LIMIT 1];
        msKAMProductNeedSelectorController.saveLink(opp.Id, pn.Id, '');

        Product_Need_Link__c pnl = [SELECT Id FROM Product_Need_Link__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        msKAMProductNeedSelectorController.deleteLink(opp.Id, pnl.Id);
    }

    @isTest
    public static void testChangePrimaryCN() {
        Opportunity opp = [SELECT Id, Name, StageName, CloseDate, Customer_Need_in_scope_primary__c, AccountId FROM Opportunity LIMIT 1];
        opp.Customer_Need_in_scope_primary__c = null;
        update opp;

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Copy of ' + opp.Name;
        opp2.StageName = opp.StageName;
        opp2.CloseDate = opp.CloseDate;
        opp2.AccountId = opp.AccountId;
        insert opp2;

        Product_Need__c pn = [SELECT Id FROM Product_Need__c LIMIT 1];
        msKAMProductNeedSelectorController.saveLink(opp2.Id, pn.Id, '');

        List<Product_Need_Link__c> pnLinkOfOpp = [SELECT Id FROM Product_Need_Link__c WHERE Opportunity__c = :opp.Id];
        Product_Need_Link__c pnLinkOfOpp2 = [SELECT Id FROM Product_Need_Link__c WHERE Account__c = :opp.AccountId AND Opportunity__c != :opp.Id LIMIT 1];
        System.debug(pnLinkOfOpp2.Id);
        System.debug(opp.Customer_Need_in_scope_primary__c);

        opp.Customer_Need_in_scope_primary__c = pnLinkOfOpp2.Id;
        System.debug(opp.Customer_Need_in_scope_primary__c);


        Test.startTest();
        msKAMProductNeedSelectorController.disableOpportunityTriggerToUpdateLinks = false;
        update opp;
        Test.stopTest();


        System.debug(opp.Customer_Need_in_scope_primary__c);
        List<Product_Need_Link__c> pnLinkOfOppAgain = [SELECT Id FROM Product_Need_Link__c WHERE Opportunity__c = :opp.Id];
        System.assertNotEquals(pnLinkOfOpp.size(), pnLinkOfOppAgain.size());
    }

    @isTest
    public static void testSaveLinkOther() {
        Opportunity opp = [SELECT Id, Customer_Need_in_scope_primary__c, AccountId FROM Opportunity LIMIT 1];
        List<Product_Need_Link__c> pnLinkOfOpp = [SELECT Id FROM Product_Need_Link__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        msKAMProductNeedSelectorController.saveLinkOther(opp.Id, 'Germany', 'Upstream Origination', 'Upstream GoOs', 'my very good comment');
        Test.stopTest();

        List<Product_Need_Link__c> pnLinkOfOppAgain = [SELECT Id FROM Product_Need_Link__c WHERE Opportunity__c = :opp.Id];
        System.assertNotEquals(pnLinkOfOpp.size(), pnLinkOfOppAgain.size());
    }

    @isTest
    public static void testUpdateCNData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product_Need__c pn = [SELECT Id, KAM_Product_Marketing_material__c, Comments__c FROM Product_Need__c LIMIT 1];
        msKAMProductNeedSelectorController.saveLink(opp.Id, pn.Id, '');
        Product_Need_Link__c pnLink = [SELECT Id, KAM_Product_Marketing_material__c, Comments__c FROM Product_Need_Link__c WHERE Product_Need__c = :pn.Id AND Opportunity__c = :opp.Id LIMIT 1];

        Test.startTest();
        pn.KAM_Product_Marketing_material__c = 'Test';
        pn.Comments__c = 'Test';
        update pn;
        Test.stopTest();

        Product_Need_Link__c pnLinkAgain = [SELECT Id, KAM_Product_Marketing_material__c, Comments__c FROM Product_Need_Link__c WHERE Product_Need__c = :pn.Id AND Opportunity__c = :opp.Id LIMIT 1];
        System.assertNotEquals(pnLink.KAM_Product_Marketing_material__c, pnLinkAgain.KAM_Product_Marketing_material__c);
        System.assertNotEquals(pnLink.Comments__c, pnLinkAgain.Comments__c);
        System.assertEquals('Test', pnLinkAgain.KAM_Product_Marketing_material__c);
        System.assertEquals('Test', pnLinkAgain.Comments__c);
    }

    @IsTest
    public static void testMarketPresenceAutomationEmptyMarketPresence() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product_Need__c pn = [SELECT Id FROM Product_Need__c WHERE Country__c = 'Germany' LIMIT 1];
        Account acc = [SELECT Market_Presence__c FROM Account WHERE Id = :opp.AccountId];
        acc.BillingCountry = null;
        acc.BillingCountryCode = null;
        acc.Market_Presence__c = null;
        update acc;


        Account accBeforeCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        Test.startTest();
        msKAMProductNeedSelectorController.saveLink(opp.Id, pn.Id, '');
        Test.stopTest();

        Account accAfterCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        System.assertEquals(null, accBeforeCustomerNeed.Market_Presence__c, 'Market Presence field should be empty.');
        System.assertEquals('Germany', accAfterCustomerNeed.Market_Presence__c, 'Market Presence should be Germany');    
    }
    @IsTest
    public static void testMarketPresenceAutomationFilledMarketPresence() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product_Need__c pn = [SELECT Id FROM Product_Need__c WHERE Country__c = 'Germany' LIMIT 1];
        Account acc = [SELECT Market_Presence__c FROM Account WHERE Id = :opp.AccountId];

        Account accBeforeCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        Test.startTest();
        msKAMProductNeedSelectorController.saveLink(opp.Id, pn.Id, '');
        Test.stopTest();

        Account accAfterCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        System.assertEquals('France', accBeforeCustomerNeed.Market_Presence__c, 'Market Presence field should only include France.');
        System.assert(accAfterCustomerNeed.Market_Presence__c.split(';').contains('France'), 'Market Presence should include France');
        System.assert(accAfterCustomerNeed.Market_Presence__c.split(';').contains('Germany'), 'Market Presence should include Germany');
    }
    @IsTest
    public static void testMarketPresenceAutomationSaveOther() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account acc = [SELECT Market_Presence__c FROM Account WHERE Id = :opp.AccountId];

        Account accBeforeCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        Test.startTest();
        msKAMProductNeedSelectorController.saveLinkOther(opp.Id, 'Germany', 'Upstream Origination', 'Upstream GoOs', 'my very good comment');
        Test.stopTest();

        Account accAfterCustomerNeed = [SELECT Market_Presence__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        System.assertEquals('France', accBeforeCustomerNeed.Market_Presence__c, 'Market Presence field should only include France.');
        System.assert(accAfterCustomerNeed.Market_Presence__c.split(';').contains('France'), 'Market Presence should include France');
        System.assert(accAfterCustomerNeed.Market_Presence__c.split(';').contains('Germany'), 'Market Presence should include Germany');
    }
}