public inherited sharing class KAMDocumentsLinkSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return KAM_Documents_Link__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            KAM_Documents_Link__c.Id,
            KAM_Documents_Link__c.Views__c
        };
    }
}