public class GenerationUnitSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Generation_Unit__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Generation_Unit__c.Id,
            Generation_Unit__c.Description__c,
            Generation_Unit__c.Site_Location_Postcode__c,
            Generation_Unit__c.Installed_Capacity__c,
            Generation_Unit__c.Annual_Production__c
        };
    }
}