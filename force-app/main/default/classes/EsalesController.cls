@RestResource(UrlMapping='/Esales/*')
global with sharing class EsalesController {

    public static Set<Id> getContracts() {
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        Set<Id> contractIds = new Set<Id>();
        for (Contract__c contract : contracts) {
            contractIds.add(contract.Id);
        }
        return contractIds;
    }

    public static Map<String, Object> getFromContract(Id ContractId) {
        Contract__c contract = [SELECT Contract_Date__c,Start_Date__c, End_Date__c, Price_fixing_option__c, Self_Billing__c,Inflation_Index__c FROM Contract__c WHERE Id = :ContractId];
        Map<String, Object> result = new Map<String, Object>();
        result.put('AGREEMENT_DATE', contract.Contract_Date__c);
        Date contractStart = Date.valueOf(contract.Start_Date__c);
        Date contractEnd = Date.valueOf(contract.End_Date__c);
        Integer duration = contractStart.daysBetween(contractEnd);
        result.put('CONTRACT_DURATION', String.valueOf(duration));
        Boolean priceFixing = false;
        if (contract.Price_fixing_option__c != null) {
            priceFixing = true;
        }
        result.put('FIXED PRICE OPTION', priceFixing);
        Boolean rpi = false;
        if (contract.Inflation_Index__c == 'RPI') {
            rpi = true;
        }
        result.put('RPI_UPLIFT', rpi);
        Boolean selfBilling = false;
        if (contract.Self_Billing__c != null) {
            selfBilling = true;
        }
        result.put('SELF_BILLING', selfBilling);
        return result;
    }

    public static Map<String, Object> getFromEntity(Id ContractId) {
        Entity_Contract_Relationship__c entities = [SELECT Entity__c FROM Entity_Contract_Relationship__c WHERE Contract__c = :ContractId LIMIT 1];
        Entity__c entitiy = [SELECT ROC_Banding_Factor__c FROM Entity__c WHERE Id = :entities.Entity__c];
        Map<String, Object> result = new Map<String, Object>();
        result.put('ROC_BAND', entitiy.ROC_Banding_Factor__c);
        return result;
    }

    public static Map<String, Object> getPricing(Id ContractId) {
        List<Pricing_Component__c> prices = [SELECT Volume_Share__c, Value__c, SystemModstamp, Start_Date__c, RecordType.Name, Percentage__c, Offset__c, Name, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Index_Price__c, Id, Frequency__c, Estimate__c, End_Date__c, Dimension__c, CurrencyIsoCode, CreatedDate, CreatedById, Contract__c, Agreement_Date__c FROM Pricing_Component__c WHERE Start_Date__c <= TODAY AND End_Date__c >= TODAY AND Contract__c = :ContractId];
        Map<String, Object> result = new Map<String, Object>();
        Boolean ancillary_exists = false;
        for (Pricing_Component__c price : prices) {

            if (price.Dimension__c == 'Admin Charge') {
                result.put('ADMIN_CHARGE', price.Value__c);
            }
            if (price.Dimension__c == 'Metering Charge') {
                result.put('METERING_CHARGE', price.Value__c);
            }
            if (price.Dimension__c == 'Ancillary Services') {
                ancillary_exists = true;
                result.put('AN_SER_SHARING', price.Percentage__c);
            }
            if (price.Dimension__c == 'BMU Registration Charge') {
                result.put('BMU_REG_CHARGE', price.Value__c);
            }
            if (price.Dimension__c == 'Triad') {
                result.put('TRIAD_SHARE_RATIO', price.Percentage__c);
            }
            if (price.Dimension__c == 'ROC Recycling') {
                result.put('RO_LA_PA_FACTOR', price.Percentage__c);
            }
            if (price.Index_Price__c == 'Fixed Price') {
                result.put('FIXED_PRICE', price.Value__c);
            }
            if (price.Index_Price__c == 'ROC') {
                result.put('ROC_FIX_P', price.Value__c);
                result.put('ROC_FIX_P', price.Percentage__c);
            }
            if (price.RecordType.Name == 'Floating Energy Price') {
                result.put('P_INDEX', price.Index_Price__c);
                result.put('P_SHARING_RATE', price.Percentage__c);
            }
        }
        result.put('ANCIL_RELEVANT', ancillary_exists);
        return result;
    }

    public static List<Map<String, Object>> getResult() {
        List<Map<String, Object>> res = new List<Map<String, Object>>();
        Set<Id> contracts = getContracts();
        for (Id contractId : contracts) {
            Map<String, Object> finalresult = new Map<String, Object>();
            Map<String, Object> result = new Map<String, Object>();
            if (!getPricing(contractId).isEmpty()) {
                result.putAll(getPricing(contractId));
                result.putAll(getFromContract(contractId));
                result.putAll(getFromEntity(contractId));
            }
            finalresult.put('ContractID', contractId);
            finalresult.put('Values', result);
            res.add(finalresult);
            break;
        }
        return res;
    }
    @HttpGet
    global static String doGet() {
        return JSON.serialize(getResult());
    }
}