public inherited sharing class ProductNeedLinkSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Product_Need_Link__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Product_Need_Link__c.Id,
            Product_Need_Link__c.Product_Need__c,
            Product_Need_Link__c.KAM_Documents_Link__c,
            Product_Need_Link__c.Comment__c,
            Product_Need_Link__c.Account__c,	
            Product_Need_Link__c.Opportunity__c	
        };
    }
}