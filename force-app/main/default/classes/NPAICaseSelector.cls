public inherited sharing class NPAICaseSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return NPC_Cases__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            NPC_Cases__c.Name,
            NPC_Cases__c.Id,
            NPC_Cases__c.DepartmentInvolved__c,
            NPC_Cases__c.Status__c,
            NPC_Cases__c.Department_involved__c
        };
    }
}