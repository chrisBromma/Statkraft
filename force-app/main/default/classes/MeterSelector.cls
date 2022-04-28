public inherited sharing class MeterSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Meter__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Meter__c.Id,
            Meter__c.Name,
            Meter__c.Parent_Meter__c,
            Meter__c.Portfolio_ID__c,
            Meter__c.Installed_Capacity__c,
            Meter__c.Description__c,
            Meter__c.Site_Location_Postcode__c,
            Meter__c.Country__c,
            Meter__c.Succeeding_Clone__c,
            Meter__c.RecordTypeId
        };
    }

    public fflib_QueryFactory newQueryFactoryWithSubmeters(){
        fflib_QueryFactory meterFactory = newQueryFactory().selectField('RecordType.Name');
        fflib_QueryFactory submeterFactory = addQueryFactorySubselect(meterFactory);
        return meterFactory;
    }

    public fflib_QueryFactory newQueryFactory2(){
        fflib_QueryFactory meterFactory = newQueryFactory().selectField('RecordType.Name');
        return meterFactory;
    }
}