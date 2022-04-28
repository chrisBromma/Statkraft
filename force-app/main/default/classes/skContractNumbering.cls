// Author: Karl Bühler
// Created: 27.09.2018
// On request of Ilvija Svilpe
// Statkraft Contract Ids can only be numeric

public class skContractNumbering {
    // Definition of numbering rules
    
    public static map<string, integer> ContractIdStart = new map<string, integer>();
    public static map<string, integer> ContractIdIncrement = new map<string, integer>();

    static {
        ContractIdStart.put('France', 100000);
        ContractIdIncrement.put('France', 10);
        
        // For additional auto numbering of other countries:
        //ContractIdStart.put('United Kingdom', 200000);
        //ContractIdIncrement.put('United Kingdom', 20);    
    }
    
    public string getLatestContractId(string country){
        integer MaxContractId;
        // Country selected per Contract__c.Country, tested against ContractIdStart map
        
        if (ContractIdStart.keySet().contains(country)) {
            MaxContractId = integer.valueof(ContractIdStart.get(country));
            for (Contract__c Contract : [SELECT Statkraft_Contract_Id__c FROM Contract__c WHERE Statkraft_Contract_Id__c  != Null AND Country__c = :country]) {
                if (Contract.Statkraft_Contract_Id__c.isNumeric()) {
                	MaxContractId = math.max(MaxContractId, Integer.valueOf(Contract.Statkraft_Contract_Id__c));
                }
            }
            MaxContractId = MaxContractId + ContractIdIncrement.get(country); 
            return(string.valueof(MaxContractId));   

        } else {
            return(Null);
        }
        
    }
}