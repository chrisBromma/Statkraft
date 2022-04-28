public inherited sharing class PricingComponentSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Pricing_Component__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Pricing_Component__c.Id,
            Pricing_Component__c.Name,
            Pricing_Component__c.Contract__c,
            Pricing_Component__c.Contract__c.Name,
            Pricing_Component__c.CreatedById,
            Pricing_Component__c.CreatedDate,
            Pricing_Component__c.LastModifiedDate,
            Pricing_Component__c.LastModifiedById,
            Pricing_Component__c.Start_Date__c,
            Pricing_Component__c.End_Date__c,
            Pricing_Component__c.Agreement_Date__c,
            Pricing_Component__c.Volume_Share__c,
            Pricing_Component__c.Percentage__c,
            Pricing_Component__c.Value__c,
            Pricing_Component__c.RecordTypeId,
            Pricing_Component__c.Offset__c,
            Pricing_Component__c.Index_Price__c,
            Pricing_Component__c.Estimate__c,
            Pricing_Component__c.Frequency__c,
            Pricing_Component__c.Dimension__c,
            Pricing_Component__c.CurrencyIsoCode,
            Pricing_Component__c.msBrytTransactionType__c,
            Pricing_Component__c.msBrytProduct_Name__c,
            Pricing_Component__c.Fixed_Volume__c

        };
    }

    public List<Pricing_Component__c> selectByContractId(Id contractId){
        return (List<Pricing_Component__c>) Database.query(
            newQueryFactory()
            .selectField('RecordType.Name')
            .setCondition('Contract__c = :contractId')
            .toSOQL()
        );
    }
}