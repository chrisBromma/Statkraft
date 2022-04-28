public inherited sharing class NPAIAssessmentSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return NPC_Assessment__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            NPC_Assessment__c.Id,
            NPC_Assessment__c.Colors__c
        };
    }
}