public inherited sharing class CountryContactDetailsSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return CountryContactDetails__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            CountryContactDetails__c.Country__c,
            CountryContactDetails__c.Phone__c
        };
    }
}