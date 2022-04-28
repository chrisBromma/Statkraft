/**
 * Created by Steffen Naundorf on 10.02.2022.
 */

public with sharing class sapTriggerHelper {
    public Map<Id, Map<String, BankData>>bankDataMapOld = new Map<Id, Map<String, BankData>>(); //all of accounts except current
    public Map<Id, Map<String, BankData>>bankDataMapNew = new Map<Id, Map<String, BankData>>(); //only current
    public static final Id SAP_TRANSFER_CASE_RECORD_TYPE = Application.RecordTypes.byDeveloperName('Case', 'SAP_Setup_Case').Id;
    public Map<Id, Case> accountToCase = new Map<Id, Case>();
    public Map<Id, Account> accountMap = new Map<Id, Account>();
    public Map<Id, List<Contract__c>> accountToAllContracts = new Map<Id, List<Contract__c>>();
    public fflib_SObjectUnitOfWork uow;

    //Scenarios
    public static final String NEW_CONTRACT_NEW_COUNTERPARTY = 'New contract with new counterparty';
    public static final String NEW_CONTRACT_EXISTING_COUNTERPARTY = 'New contract with existing counterparty - new bank data';
    public static final String CHANGE_BANK_DATA = 'Change of bank data';
    public static final String CHANGE_NAME_ADDRESS = 'Change of company name or address';
    public static final String CHANGE_RESELLER_STATUS = 'Change of Reseller Status';
    public static final String CHANGE_VAT_TAX = 'Change of VAT or Tax number';
    public static final String CLAIM_RECEIVED = 'Claim received for existing contract with existing counterparty';


    public sapTriggerHelper(fflib_SObjectUnitOfWork uowIn) {
        uow = uowIn;
    }
    public void generateTransferCase(Contract__c newAccount) {

    }
    public void generateTransferCase(Account oldAccount, Account newAccount) {
        List<String>messages = new List<String>();
        TransferData transferData;
        Set<String> scenarios = defineScenario(oldAccount, newAccount);
        Case transferCase = accountToCase.get(newAccount.Id);

        if (transferCase == null) {
            transferCase = new Case();
            transferCase.RecordTypeId = SAP_TRANSFER_CASE_RECORD_TYPE;
            transferCase.AccountId = newAccount.Id;
            transferCase.Status = 'New';
            transferData = new TransferData();
        } else {
            transferData = (TransferData) JSON.deserializeStrict(transferCase.SAP_Transfer_Data__c, TransferData.Class);
        }
        transferData.scenarios.addAll(scenarios);
        messages.addAll(scenarios);


        if (oldAccount.Name != newAccount.Name) {
            messages.add('Name changed: ' + oldAccount.Name + ' -> ' + newAccount.Name);
        }
        if (oldAccount.BillingAddress != newAccount.BillingAddress) {
            messages.add('Billing Address changed: ' + oldAccount.BillingAddress + ' -> ' + newAccount.BillingAddress);
        }
        if (oldAccount.VAT_Reseller__c != newAccount.VAT_Reseller__c) {
            messages.add('VAT Reseller changed: ' + oldAccount.VAT_Reseller__c + ' -> ' + newAccount.VAT_Reseller__c);
        }
        if (oldAccount.VAT_Reseller_Valid_Until__c != newAccount.VAT_Reseller_Valid_Until__c) {
            messages.add('VAT Reseller Valid Until changed: ' + oldAccount.VAT_Reseller_Valid_Until__c.format() + ' -> ' + newAccount.VAT_Reseller_Valid_Until__c.format());
        }
        if (oldAccount.VAT_Number__c != newAccount.VAT_Number__c) {
            transferData.updateVat = 'x';
            messages.add('VAT Number changed: ' + oldAccount.VAT_Number__c + ' -> ' + newAccount.VAT_Number__c);
        }
        if (oldAccount.company_tax_number__c != newAccount.company_tax_number__c) {
            transferData.updateTax = 'x';
            messages.add('TAX Number changed: ' + oldAccount.company_tax_number__c + ' -> ' + newAccount.company_tax_number__c);
        }


        if (!messages.isEmpty()) {
            addMessage(messages, transferCase);
        }
        transferCase.SAP_Transfer_Data__c = JSON.serialize(transferData);
        accountToCase.put(newAccount.Id, transferCase);
    }
    public void generateTransferCase(Contract__c oldContract, Contract__c newContract) {
        List<String>messages = new List<String>();
        Account account = accountMap.get(newContract.Contract_Holder__c);
        TransferData transferData;
        List<String> scenarios = defineScenario(oldContract, newContract, account);
        Case transferCase = accountToCase.get(newContract.Contract_Holder__c);

        if (transferCase == null) {
            transferCase = new Case();
            transferCase.RecordTypeId = SAP_TRANSFER_CASE_RECORD_TYPE;
            transferCase.AccountId = newContract.Contract_Holder__c;
            transferCase.Status = 'New';
            transferData = new TransferData();
        } else {
            transferData = (TransferData) JSON.deserializeStrict(transferCase.SAP_Transfer_Data__c, TransferData.Class);
        }
        for (String scenario : scenarios) {
            messages.add(newContract.Name + ': ' + scenario);
        }
        transferData = addScenario(newContract, transferData, scenarios);


        if (isNewBankData(newContract)) {
            BankData bankData = new BankData(newContract);
            String key = getKey(bankData);

            BankData bankDataOld = transferData.bankData.get(key);
            if (bankDataOld != null && bankDataOld.updateBank == 'd') {
                transferData.bankData.remove(key);
                messages.add('Bank Data Removal undone: ' + key);
            } else {
                bankData.updateBank = 'i';
                transferData.bankData.put(key, bankData);
                messages.add('Bank Data Inserted: ' + key);
            }
        }
        if (isBankDataDeleted(oldContract)) {
            BankData bankData = new BankData(oldContract);
            String key = getKey(bankData);

            BankData bankDataOld = transferData.bankData.get(key);
            if (bankDataOld != null && bankDataOld.updateBank == 'i') {
                transferData.bankData.remove(key);
                messages.add('Bank Data Insertion undone: ' + key);
            } else {
                bankData.updateBank = 'd';
                transferData.bankData.put(key, bankData);
                messages.add('Bank Data Removed: ' + key);
            }
        }
        if (scenarios.contains(NEW_CONTRACT_NEW_COUNTERPARTY)) {
            transferData.newBP = 'X';
        }

        if (!messages.isEmpty()) {
            addMessage(messages, transferCase);
        }
        transferCase.SAP_Transfer_Data__c = JSON.serialize(transferData);
        accountToCase.put(newContract.Contract_Holder__c, transferCase);
    }


    public void addBankToListOld(Contract__c oldContract) {
        BankData bankData = new BankData(oldContract);
        Map<String, BankData>bankDataOfAccount = bankDataMapOld.get(oldContract.Contract_Holder__c);

        if (bankDataOfAccount == null)
            bankDataOfAccount = new Map<String, BankData>();

        bankDataOfAccount.put(getKey(bankData), bankData);
        bankDataMapOld.put(oldContract.Contract_Holder__c, bankDataOfAccount);
    }
    public void addBankToListNew(Contract__c newContract) {
        BankData bankData = new BankData(newContract);
        Map<String, BankData>bankDataOfAccount = bankDataMapNew.get(newContract.Contract_Holder__c);

        if (bankDataOfAccount == null)
            bankDataOfAccount = new Map<String, BankData>();

        bankDataOfAccount.put(getKey(bankData), bankData);
        bankDataMapNew.put(newContract.Contract_Holder__c, bankDataOfAccount);
    }

    public void addMessage(List<String> messages, Case parentCase) {
        FeedItem post = new FeedItem();
        post.Body = String.join(messages, '\n');
        uow.registerNew(post, FeedItem.ParentId, parentCase);
    }
    public static String getKey(BankData bankData) {
        return bankData.bankAccountOwner + ': ' + bankData.iban;
    }

    public List<String> defineScenario(Contract__c oldContract, Contract__c newContract, Account account) {
        List<String> scenarios = new List<String>();
        if (oldContract.Status__c != newContract.Status__c && newContract.Status__c == 'Active' && account.SAP_Customer__c == null) {
            scenarios.add(NEW_CONTRACT_NEW_COUNTERPARTY);
        }
        if (oldContract.Status__c != newContract.Status__c
                && newContract.Status__c == 'Active'
                && account.SAP_Customer__c != null) {
            scenarios.add(NEW_CONTRACT_EXISTING_COUNTERPARTY);
        }
        if ((oldContract.IBAN__c != newContract.IBAN__c
                || oldContract.Bank_Claim__c != newContract.Bank_Claim__c
                || oldContract.Bank_Account_Owner__c != newContract.Bank_Account_Owner__c)
                && newContract.Status__c == 'Active'
                && oldContract.Status__c == 'Active') {
            scenarios.add(CHANGE_BANK_DATA);
        }

        return scenarios;
    }
    public Set<String> defineScenario(Account oldAccount, Account newAccount) {
        Set<String> scenarios = new Set<String>();
        if (newAccount.SAP_Customer__c != null &&
                (oldAccount.Name != newAccount.Name ||
                        oldAccount.BillingStreet != newAccount.BillingStreet ||
                        oldAccount.BillingCity != newAccount.BillingCity ||
                        oldAccount.BillingCountry != newAccount.BillingCountry ||
                        oldAccount.BillingCountryCode != newAccount.BillingCountryCode ||
                        oldAccount.BillingPostalCode != newAccount.BillingPostalCode)) {
            scenarios.add(CHANGE_NAME_ADDRESS);

        }
        if (newAccount.SAP_Customer__c != null &&
                (oldAccount.VAT_Reseller__c != newAccount.VAT_Reseller__c ||
                        oldAccount.VAT_Reseller_Valid_Until__c != newAccount.VAT_Reseller_Valid_Until__c)) {
            scenarios.add(CHANGE_RESELLER_STATUS);

        }
        if (newAccount.SAP_Customer__c != null &&
                (oldAccount.VAT_Number__c != newAccount.VAT_Number__c ||
                        oldAccount.company_tax_number__c != newAccount.company_tax_number__c)) {
            scenarios.add(CHANGE_VAT_TAX);
        }

        return scenarios;
    }

    public TransferData addScenario(Contract__c newContract, TransferData transferData, List<String> scenarios) {
        Set<String> scenariosOld = transferData.contractToScenarios.get(newContract.Id);
        if (scenariosOld == null)
            scenariosOld = new Set<String>();

        scenariosOld.addAll(scenarios);
        transferData.contractToScenarios.put(newContract.Id, scenariosOld);

        return transferData;
    }

    public Boolean isNewBankData(Contract__c newContract) {
        Map<String, BankData>bankDataOfAccountOld = bankDataMapOld.get(newContract.Contract_Holder__c);
        BankData bankData = new BankData(newContract);
        String key = getKey(bankData);

        if (bankDataOfAccountOld.get(key) != null) {
            return false;
        } else {
            return true;
        }
    }
    public Boolean isBankDataDeleted(Contract__c oldContract) {
        Map<String, BankData>bankDataOfAccountNew = bankDataMapNew.get(oldContract.Contract_Holder__c);
        BankData bankData = new BankData(oldContract);
        String key = getKey(bankData);

        if (bankDataOfAccountNew.get(key) != null) {
            return false;
        } else {
            return true;
        }
    }


    public class TransferData {
        @AuraEnabled public Set<String> scenarios { get; set; }
        @AuraEnabled public Map<String, BankData> bankData { get; set; }
        @AuraEnabled public Map<Id, Set<String>> contractToScenarios { get; set; }
        @AuraEnabled public String updateVat { get; set; }
        @AuraEnabled public String updateTax { get; set; }
        @AuraEnabled public String newBP { get; set; }
        public TransferData() {
            updateTax = '';
            updateVat = '';
            newBP = '';
            bankData = new Map<String, BankData>();
            contractToScenarios = new Map<Id, Set<String>>();
            scenarios = new Set<String>();
        }
    }
    public class BankData {
        @AuraEnabled public String bankAccountOwner { get; set; }
        @AuraEnabled public String iban { get; set; }
        @AuraEnabled public Boolean bankClaim { get; set; }
        @AuraEnabled public String updateBank { get; set; }
        public BankData() {
            updateBank = '';
        }
        public BankData(Contract__c contract) {
            bankAccountOwner = contract.Bank_Account_Owner__c;
            iban = contract.IBAN__c;
            bankClaim = contract.Bank_Claim__c;
            updateBank = '';
        }
    }
}