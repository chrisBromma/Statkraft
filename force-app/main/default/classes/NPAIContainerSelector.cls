public inherited sharing class NPAIContainerSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return NPAI_Container__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            NPAI_Container__c.Id,
            NPAI_Container__c.NPAI_Case__c,
            NPAI_Container__c.Approval_Status__c
        };
    }
}