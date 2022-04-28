/****************************************************************************************************
* Class msKAMDocumentsOverviewControllerTest
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
public without sharing class msKAMDocumentsOverviewControllerTest {
    @TestSetup public static void testSetup() {
        List<KAM_Documents_Link__c> linksToInsert = new List<KAM_Documents_Link__c>();

        KAM_Documents_Link__c doc1 = new KAM_Documents_Link__c();
        doc1.Name = 'My Document 1';
        doc1.Url__c = 'www.google.com';
        doc1.Category__c = 'General Documents';
        doc1.SubCategory__c = 'General';
        linksToInsert.add(doc1);

        KAM_Documents_Link__c doc2 = new KAM_Documents_Link__c();
        doc2.Name = 'My Document 2';
        doc2.Url__c = 'www.sharepoint.com';
        doc2.Category__c = 'Account Documents';
        doc2.SubCategory__c = 'Marketing';
        linksToInsert.add(doc2);

        insert linksToInsert;
    }

    @isTest
    public static void testGetItemsGeneral() {
        msKAMDocumentsOverviewController.KAMDocumentsWrapper items = msKAMDocumentsOverviewController.getItems(null);
        Set<msKAMDocumentsOverviewController.Item> links = new Set<msKAMDocumentsOverviewController.Item>();

        for (msKAMDocumentsOverviewController.Category category : items.files) {
            for (msKAMDocumentsOverviewController.SubCategory subCategory : category.subcategories) {
                for (msKAMDocumentsOverviewController.Item item : subCategory.items) {
                    links.add(item);
                }
            }
        }
        System.assert(links.size() == 2);
    }

    @isTest
    public static void testGetItemsOpp() {
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

        msKAMDocumentsOverviewController.KAMDocumentsWrapper items = msKAMDocumentsOverviewController.getItems(opp.Id);

        Set<msKAMDocumentsOverviewController.Item> links = new Set<msKAMDocumentsOverviewController.Item>();
        for (msKAMDocumentsOverviewController.Category category : items.files) {
            for (msKAMDocumentsOverviewController.SubCategory subCategory : category.subcategories) {
                for (msKAMDocumentsOverviewController.Item item : subCategory.items) {
                    links.add(item);
                }
            }
        }
        System.assert(links.size() == 2);
    }

    @isTest
    public static void testAddLinkToProduct() {
        msKAMProductNeedSelectorControllerTest.testSetup();
        KAM_Documents_Link__c link = [SELECT Id FROM KAM_Documents_Link__c LIMIT 1];
        List<Product_Need__c> pns = [SELECT Id FROM Product_Need__c];

        msKAMDocumentsOverviewController.addProducts(link.Id, pns);
        List<Product_Need_Link__c> pnOfDoc = [SELECT Id FROM Product_Need_Link__c WHERE KAM_Documents_Link__c = :link.Id];
        System.assert(pnOfDoc.size() == pns.size());
    }

    @isTest
    public static void testCountView() {
        KAM_Documents_Link__c link = [SELECT Id, Views__c FROM KAM_Documents_Link__c LIMIT 1];

        System.assert(link.Views__c == 0);
        msKAMDocumentsOverviewController.countView(link.Id);

        link = [SELECT Id, Views__c FROM KAM_Documents_Link__c WHERE Id = :link.id];
        System.assert(link.Views__c == 1);
    }

    @isTest
    public static void testDeleteItem() {
        KAM_Documents_Link__c link = [SELECT Id, Views__c FROM KAM_Documents_Link__c LIMIT 1];

        msKAMDocumentsOverviewController.deleteItem(link.Id);

        List<KAM_Documents_Link__c> links = [SELECT Id, Views__c FROM KAM_Documents_Link__c WHERE Id = :link.id];
        System.assert(links.size() == 0);
    }
}