/****************************************************************************************************
* Class msKAMContactsListViewController
*
*   Create By	:   ChristianGottlieb (mindsquare GmbH)
*   Create Date	:   2020-02-17
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * ChristianGottlieb (mindsquare GmbH)	            2020-02-17       	Init version.
*****************************************************************************************************/

public with sharing class msKAMContactsListViewController {
    @AuraEnabled
    public static listViewWrapper getContacts(Id accountId, String filteredRole) {
        listViewWrapper result = new listViewWrapper();

        List<Account> childAccounts = [SELECT Id FROM Account WHERE Negotiating_Party__c =:accountId];
        Set<String> respectedRoles = new Set<String>{'Contractual Contact','Customer Portal','Technical Contact', 'Commercial Contact'};
        Set<Id> childAccountIds = new Set<Id>();
        for(Account childItem : childAccounts) {
            childAccountIds.add(childItem.Id);
        }
        List<Contract__c> scopeOfContracts = [
                SELECT Id, Alternative_Contract_Name__c, Contracted_Capacity__c, Profit__c, End_Date__c, KeepPortalAccessUntil__c
                FROM Contract__c
                WHERE ( Contract_Holder__c = :accountId
                OR Contract_Holder__c IN :childAccountIds
                )
                AND KeepPortalAccessUntil__c >= :Date.today()
        ];

        Set<Id> scopeOfContractIds = new Set<Id>();
        for(Contract__c contractItem : scopeOfContracts) {
            scopeOfContractIds.add(contractItem.Id);
        }

        List<Contract_Role__c> contractRolesOfAllContacts = [
                SELECT Id, Contact__c, Start_Date__c, Role__c
                FROM Contract_Role__c
                WHERE Contract__c IN :scopeOfContractIds
                AND Role__c IN :respectedRoles
                ORDER BY Start_Date__c DESC
        ];

        List<Site_Role__c> siteRolesOfAllContacts = [
                SELECT Id, Name, Contact__c, Start_Date__c, Role__c
                FROM Site_Role__c
                WHERE Meter__c IN (SELECT Meter__c FROM MeterRegistration__c WHERE Contract__c IN :scopeOfContractIds)
                AND Role__c IN :respectedRoles
                ORDER BY Start_Date__c DESC
        ];

        Map<Id,List<Contract_Role__c>> contactIdToContractRolesMap = new Map<Id, List<Contract_Role__c>>();
        Map<Id,List<Site_Role__c>> contactIdToSiteRolesMap = new Map<Id, List<Site_Role__c>>();

        for(Contract_Role__c roleItem : contractRolesOfAllContacts) {
            if(!contactIdToContractRolesMap.containsKey(roleItem.Contact__c)) {
                contactIdToContractRolesMap.put(roleItem.Contact__c, new List<Contract_Role__c>());
            }
            contactIdToContractRolesMap.get(roleItem.Contact__c).add(roleItem);
        }

        for(Site_Role__c roleItem : siteRolesOfAllContacts) {
            if(!contactIdToSiteRolesMap.containsKey(roleItem.Contact__c)) {
                contactIdToSiteRolesMap.put(roleItem.Contact__c, new List<Site_Role__c>());
            }
            contactIdToSiteRolesMap.get(roleItem.Contact__c).add(roleItem);
        }

        Set<Id> setOfAllContactIds = new Set<Id>();
        setOfAllContactIds.addAll(contactIdToContractRolesMap.keySet());
        setOfAllContactIds.addAll(contactIdToSiteRolesMap.keySet());

        Map<Id,Contact> allContacts = new Map<Id, Contact>([
                SELECT Id, Name, Account.Name, Email, Phone, AccountId
                FROM Contact WHERE Id IN:setOfAllContactIds
        ]);

        Map<Id,contactWrapper> contactIdToContactWrapper = new Map<Id, contactWrapper>();
        Set<Id> countedContractualContacts = new Set<Id>();
        Set<Id> countedCommercialContacts = new Set<Id>();
        Set<Id> countedTechnicalContacts = new Set<Id>();
        Set<Id> countedCustomerPortalContacts = new Set<Id>();



        for(Id contactId : allContacts.keySet()) {
            if(contactIdToContractRolesMap.containsKey(contactId)) {
                for(Contract_Role__c roleItem : contactIdToContractRolesMap.get(contactId)) {
                    if(roleItem.Role__c == filteredRole) {
                        if(!contactIdToContactWrapper.keySet().contains(contactId)) {
                            contactWrapper contactWrapped = contactToContactWrapper(allContacts.get(contactId));
                            contactIdToContactWrapper.put(contactId, contactWrapped);
                        }
                        contactIdToContactWrapper.get(contactId).countOfContractRoles++;

                    }
                    if(roleItem.Role__c == 'Commercial Contact' && !countedCommercialContacts.contains(contactId)) {
                        result.countOfCommercialContacts++;
                        countedCommercialContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Contractual Contact' && !countedContractualContacts.contains(contactId)) {
                        result.countOfContractualContacts++;
                        countedContractualContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Technical Contact' && !countedTechnicalContacts.contains(contactId)) {
                        result.countOfTechnicalContacts++;
                        countedTechnicalContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Customer Portal' && !countedCustomerPortalContacts.contains(contactId)) {
                        result.countOfCustomerPortalContacts++;
                        countedCustomerPortalContacts.add(contactId);
                    }
                }
            }
            if(contactIdToSiteRolesMap.containsKey(contactId)) {
                for(Site_Role__c roleItem : contactIdToSiteRolesMap.get(contactId)) {
                    if(roleItem.Role__c == filteredRole) {
                        if(!contactIdToContactWrapper.keySet().contains(contactId)) {
                            contactWrapper contactWrapped = contactToContactWrapper(allContacts.get(contactId));
                            contactIdToContactWrapper.put(contactId, contactWrapped);
                        }
                        contactIdToContactWrapper.get(contactId).countOfSiteRoles++;

                    }
                    if(roleItem.Role__c == 'Commercial Contact' && !countedCommercialContacts.contains(contactId)) {
                        result.countOfCommercialContacts++;
                        countedCommercialContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Contractual Contact' && !countedContractualContacts.contains(contactId)) {
                        result.countOfContractualContacts++;
                        countedContractualContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Technical Contact' && !countedTechnicalContacts.contains(contactId)) {
                        result.countOfTechnicalContacts++;
                        countedTechnicalContacts.add(contactId);
                    } else if(roleItem.Role__c == 'Customer Portal' && !countedCustomerPortalContacts.contains(contactId)) {
                        result.countOfCustomerPortalContacts++;
                        countedCustomerPortalContacts.add(contactId);
                    }
                }
            }
        }
        for(Id contactId : contactIdToContactWrapper.keySet()) {
            result.contacts.add(contactIdToContactWrapper.get(contactId));
        }
        return result;
    }

    private static contactWrapper contactToContactWrapper(Contact contactToWrap) {
        contactWrapper result = new contactWrapper();
        result.name = contactToWrap.Name;
        result.accountName = contactToWrap.Account.Name;
        result.email = contactToWrap.Email;
        result.phone = contactToWrap.Phone;
        result.contactId = contactToWrap.Id;
        result.accountId = contactToWrap.AccountId;
        return result;
    }

    public class contactWrapper {
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public String phone {get;set;}
        @AuraEnabled public Id contactId {get;set;}
        @AuraEnabled public Id accountId {get;set;}
        @AuraEnabled public Integer countOfContractRoles {get;set;}
        @AuraEnabled public Integer countOfSiteRoles {get;set;}

        contactWrapper() {
            countOfSiteRoles = 0;
            countOfContractRoles = 0;
        }
    }

    public class listViewWrapper {
        @AuraEnabled public List<contactWrapper> contacts {get;set;}
        @AuraEnabled public Integer countOfContractualContacts {get;set;}
        @AuraEnabled public Integer countOfCommercialContacts {get;set;}
        @AuraEnabled public Integer countOfCustomerPortalContacts {get;set;}
        @AuraEnabled public Integer countOfTechnicalContacts {get;set;}
        @AuraEnabled public Map<String,String> fieldAPINameToLabelMap { get; set;}
        @AuraEnabled public String sObjectLabel { get; set;}
        @AuraEnabled public String sObjectPluralLabel { get; set;}
        @AuraEnabled public String pluralLabelContractRoles { get; set;}
        @AuraEnabled public String pluralLabelSiteRoles { get; set;}


        listViewWrapper() {
            contacts = new List<contactWrapper>();
            countOfCommercialContacts = 0;
            countOfContractualContacts = 0;
            countOfCustomerPortalContacts = 0;
            countOfTechnicalContacts = 0;
            fieldAPINameToLabelMap = msKAMUtility.generateFieldAPINameToLabelMap('Contact');
            sObjectLabel = msKAMUtility.getSObjectLabel('Contact');
            sObjectPluralLabel = msKAMUtility.getSObjectPluralLabel('Contact');
            pluralLabelContractRoles = msKAMUtility.getSObjectPluralLabel('Contract_Role__c');
            pluralLabelSiteRoles = msKAMUtility.getSObjectPluralLabel('Site_Role__c');
        }
    }
}