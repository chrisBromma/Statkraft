/**
 * Created by Steffen Naundorf on 17.03.2021.
 * @testedBy msKAMProductNeedSelectorControllerTest
 */

public with sharing class msCustomerNeedLinkHandler extends TriggerHandlerExtension {
    Map<Id, Product_Need__c> productNeedMap;

    msCustomerNeedLinkHelper Helper;

    public msCustomerNeedLinkHandler() {
        super();
        Helper = new msCustomerNeedLinkHelper(
                (List<Product_need_Link__c>) Trigger.old,
                (List<Product_need_Link__c>) Trigger.new,
                (Map<Id, Product_need_Link__c>) Trigger.oldMap,
                (Map<Id, Product_need_Link__c>) Trigger.newMap
        );
    }

    public override void bulkBefore() {
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate((List<Product_need_Link__c>) Trigger.new, false);
            
            List<Product_Need_Link__c>links = (List<Product_Need_Link__c>) Trigger.new;
            List<Id>productNeedIds = new List<Id>();
            for (Product_Need_Link__c tempLink : links) {
                productNeedIds.add(tempLink.Product_Need__c);
            }
            productNeedMap = new Map<Id, Product_Need__c>([
                    Select Id, Name, Product__c, Product_Category__c, Product_Line__c, Country__c, Product_Category_Description__c, Comments__c, KAM_Product_Marketing_material__c
                    FROM Product_Need__c
                    WHERE Id IN:productNeedIds
            ]);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isInsert) {
            List<Product_Need_Link__c>links = (List<Product_Need_Link__c>) Trigger.new;
            List<Id>opportunityIds = new List<Id>();
            for (Product_Need_Link__c tempLink : links) {
                if (tempLink.Opportunity__c != null) {
                    opportunityIds.add(tempLink.Opportunity__c);
                }
            }
            Helper.mpa_indentifyCustomerNeedAccounts();
            Helper.load_Accounts();
        }
    }


    public override void beforeInsert(SObject obj) {
        addToLoopCount();

        Product_Need_Link__c tempLink = (Product_Need_Link__c) obj;
        Product_Need__c linkedProductNeed = productNeedMap.get(tempLink.Product_Need__c);
        if (linkedProductNeed != null) {
            tempLink.Name = linkedProductNeed.Name;
            tempLink.Country__c = linkedProductNeed.Country__c;
            tempLink.Product_Line__c = linkedProductNeed.Product_Line__c;
            tempLink.Product_Category__c = linkedProductNeed.Product_Category__c;
            tempLink.Product__c = linkedProductNeed.Product__c;
            tempLink.Product_Information__c = linkedProductNeed.Country__c + ', ' + linkedProductNeed.Product_Line__c + ', ' + linkedProductNeed.Product_Category__c + ', ' + linkedProductNeed.Product__c;
            tempLink.Name=linkedProductNeed.Name;
            tempLink.KAM_Product_Marketing_material__c=linkedProductNeed.KAM_Product_Marketing_material__c;
            tempLink.Product_Category_Description__c = linkedProductNeed.Product_Category_Description__c;
            tempLink.Comments__c = linkedProductNeed.Comments__c;
        }
    }

    //public override void beforeUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

    //public override void beforeDelete(SObject obj) { addToLoopCount();}


    public override void afterInsert(SObject obj) {
        Product_Need_Link__c newProductNeedLink = (Product_need_Link__c) obj; 
        Helper.mpa_addCountryToMarketPresenceIfNeeded(newProductNeedLink); 
    }

    //public override void afterUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

    //public override void afterDelete(SObject obj) { addToLoopCount();}


    public override void andFinally() {
        if (!Helper.accountsToUpdate.isEmpty()) {
            update Helper.accountsToUpdate;
        }
    }

}