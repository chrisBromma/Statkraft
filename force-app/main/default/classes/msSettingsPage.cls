/**
 * Created by Tilman Disselkamp on 17.08.2018.
 */

global class msSettingsPage {

    @AuraEnabled
    public static ContractContactWrapper getContracts() {
        List<Contract__c> contracts = new List<Contract__c>();
        ContractContactWrapper result = new ContractContactWrapper();

        Id userId = UserInfo.getUserId();

        Id contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
        if (contactId != null) {
            Contact cnt = [SELECT FirstName, LastName, AccountId,MobilePhone,Email FROM Contact WHERE Id =:ContactId][0];
            Account acc = [SELECT Name FROM Account WHERE Id =: cnt.AccountId][0];
            result.cnt = cnt;
            result.acc = acc;
            List<Contract_Role__c> contractRoles = [SELECT Contract__c FROM Contract_Role__c WHERE Contact__c = :contactId AND Start_Date__c <= :Date.today()
            AND End_Date__c >= :Date.today()];
            List<Id> contractRoleIds = new List<Id>();
            for (Contract_Role__c tmp : contractRoles) {
                contractRoleIds.add(tmp.Contract__c);
            }
            contracts = [SELECT Id, Name, Country__c FROM Contract__c WHERE Id IN :contractRoleIds];
            result.contracts = contracts;
        }
        return result;
    }

    public class ContractContactWrapper {
        @AuraEnabled Public Account acc { get; set; }
        @AuraEnabled Public Contact cnt { get; set; }
        @AuraEnabled Public List<Contract__c> contracts { get; set; }
        @AuraEnabled Public CountryContactDetails__c contactDetails { get; set; }
    }

}