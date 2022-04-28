public inherited sharing class OrgWideEmailAddressSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return OrgWideEmailAddress.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            OrgWideEmailAddress.Id
        };
    }

    public OrgWideEmailAddress selectByAddress(String address){
        return Database.query(newQueryFactory().setCondition('Address = :address').setLimit(1).toSOQL());
    }
}