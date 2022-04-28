public inherited sharing class PortalSettingSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return PortalSettings__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            PortalSettings__c.Integer__c,
            PortalSettings__c.Checkbox__c,
            PortalSettings__c.String__c,
            PortalSettings__c.Name
        };
    }

    public List<PortalSettings__c> selectByName(String name, Boolean firstOne){
        fflib_QueryFactory psFactory = newQueryFactory().setCondition('Name = :name');
        if(firstOne){
            psFactory.setLimit(1);
        }
        return Database.query(psFactory.toSOQL());
    }
}