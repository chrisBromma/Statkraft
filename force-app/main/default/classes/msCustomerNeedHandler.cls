/**
 * Created by Naundorf on 12.05.2021.
 * @testedBy msKAMProductNeedSelectorControllerTest
 */

public with sharing class msCustomerNeedHandler extends TriggerHandlerExtension {
    Map<Id, List<Product_Need_Link__c>> cnToCNLinkMap = new Map<Id, List<Product_Need_Link__c>>();
    List<Product_Need_Link__c>cnLinksToUpdate = new List<Product_Need_Link__c>();

    public msCustomerNeedHandler() {
        super();
    }

    public override void bulkBefore() { 
        if (Trigger.isInsert) {
            SandboxMigrationIdGenerator.populate((List<Product_need__c>) Trigger.new, false);
        }
    }

    public override void bulkAfter() {
        if (Trigger.isUpdate) {
            List<Product_Need_Link__c> cnLinks = [SELECT Id, Product_Need__c FROM Product_Need_Link__c WHERE Product_Need__c IN:Trigger.new];
            for (Product_Need_Link__c cnLink : cnLinks) {

                List<Product_Need_Link__c>cnLinksOfCN = cnToCNLinkMap.get(cnLink.Product_Need__c);
                if (cnLinksOfCN == null)cnLinksOfCN = new List<Product_Need_Link__c>();

                cnLinksOfCN.add(cnLink);
                cnToCNLinkMap.put(cnLink.Product_Need__c, cnLinksOfCN);
            }
        }

    }


    //public override void beforeInsert(SObject obj) { addToLoopCount(); }

    //public override void beforeUpdate(SObject oldObj, SObject obj) { addToLoopCount(); }

    //public override void beforeDelete(SObject obj) { addToLoopCount();}


    //public override void afterInsert(SObject obj) { addToLoopCount(); }

    public override void afterUpdate(SObject oldObj, SObject obj) {
        addToLoopCount();
        Product_Need__c newProductNeed = (Product_Need__c) obj;

        List<Product_Need_Link__c>cnLinksOfCN = cnToCNLinkMap.get(newProductNeed.Id);
        if (cnLinksOfCN != null) {
           for(Product_Need_Link__c cnLink:cnLinksOfCN){
               cnLink.Product_Category_Description__c=newProductNeed.Product_Category_Description__c;
               cnLink.Comments__c=newProductNeed.Comments__c;
               cnLink.KAM_Product_Marketing_material__c=newProductNeed.KAM_Product_Marketing_material__c;
               cnLinksToUpdate.add(cnLink);
           }
        }
    }

    //public override void afterDelete(SObject obj) { addToLoopCount();}


    public override void andFinally() {
        if(cnLinksToUpdate.isEmpty()==false){
            update cnLinksToUpdate;
        }
    }
}