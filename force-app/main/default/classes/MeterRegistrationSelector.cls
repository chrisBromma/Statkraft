public inherited sharing class MeterRegistrationSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return MeterRegistration__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            MeterRegistration__c.Id,
            MeterRegistration__c.Name,
            MeterRegistration__c.Contract__c,
            MeterRegistration__c.Balancing_Circle__c,
            MeterRegistration__c.Active__c,
            MeterRegistration__c.Valid_to__c,
            MeterRegistration__c.Meter__r.Name,
            MeterRegistration__c.Meter__c,
            MeterRegistration__c.msOldCounterPart__c,
            MeterRegistration__c.Volume_Share__c
        };
    }
}