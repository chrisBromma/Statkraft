public class AccountSelector extends fflib_SObjectSelector{

    Boolean addOwnerInfo = false;

    public SObjectType getSObjectType(){
        return Account.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Account.Id,
            Account.Name,
            Account.BillingCountry,
            Account.Negotiating_Party__c,
            Account.OwnerId,
            Account.Tax_or_VAT__c,
            Account.Company_Registration__c,
            Account.OwnerId,
            Account.ParentId,
            Account.Country__c,
            Account.Name,
            Account.Comments_from_AMC__c,
            Account.Customer_Segment_Industry__c,
            Account.Customer_Type__c,
            Account.Market_Value_Difference_12M__c 
        };
    }

    public AccountSelector withOwnerInfo(){
        this.addOwnerInfo = true;
        return this;
    }

    public List<Account> selectById(List<Id> idList){
        Set<Id> idSet = new Set<Id>(idList);
        return selectById(idSet);       
    }

    public List<Account> selectById(Set<Id> idSet){
        if(!addOwnerInfo){
            //simple query without additional configuration needed;
            return selectSObjectsById(idSet);
        }else{
            //Additional Relationship fields defined via QueryFactory.
            fflib_QueryFactory accountQuery = newQueryFactory();
            new UserSelector().configureQueryFactoryFields(accountQuery, 'Owner');
            return (List<Account>) Database.query(accountQuery.setCondition('Id IN :idSet').toSOQL());
        }
    }

    public List<Account> selectByTaxAndRegistration(Boolean taxOrVat, Boolean companyRegistration){
        fflib_QueryFactory accountQuery = newQueryFactory();
        return (List<Account>) Database.query(
            accountQuery
                .setCondition('Tax_Or_VAT__c = :taxOrVat AND Company_Registration__c = :companyRegistration')
                .toSOQL()
        );
    }

    
}