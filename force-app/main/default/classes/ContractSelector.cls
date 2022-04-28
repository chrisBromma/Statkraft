public class ContractSelector  extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Contract__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Contract__c.Id,
            Contract__c.Country__c,
            Contract__c.Status__c,
            Contract__c.Name,
            Contract__c.Bryt_Contract_ID__c,
            Contract__c.Single_Signed_Contract__c,
            Contract__c.Double_Signed_Contract__c,
            Contract__c.Global_Portal_Market__c,
            Contract__c.Alternative_Contract_Name__c,
            Contract__c.Commissioning_Status__c,
            Contract__c.Start_Date__c,
            Contract__c.End_Date__c,
            Contract__c.Contracted_Capacity__c,
            Contract__c.Contracted_Annual_Production__c,
            Contract__c.Market_Value_Difference_12M__c,
            Contract__c.Statkraft_Contract_Id__c
        };
    }

    
}