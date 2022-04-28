/****************************************************************************************************
* Class msUserManagementController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   19.09.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   19.09.2019      	    Init version.
*****************************************************************************************************/

public without sharing class msUserManagementController {
    public static final Id CONTRACT_ROLE_RECORD_TYPE =
            Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Contract_Role_Contact').getRecordTypeId();
    public static final Id SITE_ROLE_RECORD_TYPE =
            Schema.SObjectType.Site_Role__c.getRecordTypeInfosByDeveloperName().get('Site_Role_Contact').getRecordTypeId();
    public static final Id CONTACT_RECORD_TYPE = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
    public static UserManagementWrapper userPermissions;


    @AuraEnabled
    public static UserManagementWrapper getUserDetails() {
        UserManagementWrapper result = new UserManagementWrapper();
        User user = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Contact contact = [SELECT Id, Name FROM Contact WHERE Id = :user.ContactId];
        List<String> contractIds = new List<String>();

        Set<String> subContactIds = new Set<String>();
        List<String> contactIds = new List<String>();
        Map<String, UserWrapper> idToUserWrapperMap = new Map<String, UserWrapper>();

        List<Contract_Role__c> contractRoles = [
                SELECT Contract__c, Role__c, Contact__c, Start_Date__c, End_Date__c
                FROM Contract_Role__c
                WHERE Contact__c = :contact.Id
                AND Role__c INCLUDES ('Contractual contact')
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
                AND Contact__c != NULL
        ];
        for (Contract_Role__c tmpRole : contractRoles) {
            contractIds.add(tmpRole.Contract__c);
        }
        Map<Id, Id> meterToContract = getMeterToContract(contractIds);
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([
                SELECT Id, Name, Start_Date__c, End_Date__c, Contract_Holder__c, KeepPortalAccessUntil__c
                FROM Contract__c
                WHERE Id IN:contractIds
        ]);
        Map<Id, Meter__c> meterMap = new Map<Id, Meter__c>([
                SELECT Id, Name
                FROM Meter__c
                WHERE Id IN:meterToContract.keySet()
        ]);
        List<Contract_Role__c> subContractRoles = [
                SELECT Contract__c, Contract__r.Name, Contract__r.Start_Date__c,
                        Contract__r.End_Date__c, Role__c, Contact__c, Start_Date__c,
                        End_Date__c, msAwaitingPortalActivation__c, Contract__r.KeepPortalAccessUntil__c,
                        Contact__r.Email
                FROM Contract_Role__c
                WHERE Contract__c IN:contractsMap.keySet()
                AND (Role__c INCLUDES ('Customer Portal')
                OR Role__c INCLUDES ('Commercial Contact')
                OR Role__c INCLUDES ('Technical Contact'))
                AND Contact__c != :contact.Id
                AND Contact__c != NULL
        ];
        List<Site_Role__c> subSiteRoles = [
                SELECT Id, Contact__c, Meter__c, Meter__r.Name,
                        Role__c, End_Date__c, Start_Date__c, msAwaitingPortalActivation__c,
                        Contact__r.Email
                FROM Site_Role__c
                WHERE Meter__c IN :meterToContract.keySet()
                AND Role__c INCLUDES ('Customer Portal')
                AND Contact__c != :contact.Id
                AND Contact__c != NULL
        ];

        Map<Id, ContractWrapper> contractSchema = getContractWrappersSchema(contractsMap, meterMap, meterToContract);
        result = setPicklistValues(result, contractsMap.values());


        for (Contract_Role__c tmpRole : subContractRoles) {
            if (tmpRole.Contact__r.Email != null
                    && !tmpRole.Contact__r.Email.contains('statkraft')) {
                subContactIds.add(tmpRole.Contact__c);
            }
        }
        for (Site_Role__c siteRoleItem : subSiteRoles) {
            if (siteRoleItem.Contact__r.Email != null
                    && !siteRoleItem.Contact__r.Email.contains('statkraft')) {
                subContactIds.add(siteRoleItem.Contact__c);
            }
        }
        List<Contact> subContacts = [
                SELECT Id, Name, Email, msAwaitingPortalActivation__c
                FROM Contact
                WHERE (Id IN:subContactIds
                AND Id != :contact.Id)
                OR (msPortalRequestBy__c = :contact.Id AND msAwaitingPortalActivation__c = TRUE)
        ];
        for (Contact tmpContact : subContacts) {
            UserWrapper tmpWrapper = new UserWrapper();
            tmpWrapper.contact = tmpContact;
            tmpWrapper.contractWrappers = (Map<Id, ContractWrapper>) System.JSON.deserializeStrict(JSON.serialize(contractSchema), Map<Id, ContractWrapper>.class);
            contactIds.add(tmpContact.Id);
            idToUserWrapperMap.put(tmpContact.Id, tmpWrapper);
        }


        for (Contract_Role__c tmpRole : subContractRoles) {
            if (tmpRole.Role__c.contains('Customer Portal')
                    && tmpRole.Contact__r.Email != null
                    && !tmpRole.Contact__r.Email.contains('statkraft')) {
                UserWrapper tmpWrapper = idToUserWrapperMap.get(tmpRole.Contact__c);
                ContractWrapper contractWrapper = tmpWrapper.contractWrappers.get(tmpRole.Contract__c);

                if (tmpRole.msAwaitingPortalActivation__c == false) {
                    contractWrapper.activeRole = tmpRole;
                } else {
                    contractWrapper.requestedRole = tmpRole;
                }

                tmpWrapper.contractWrappers.put(tmpRole.Contract__c, contractWrapper);
                idToUserWrapperMap.put(tmpRole.Contact__c, tmpWrapper);
            }
        }

        for (Site_Role__c siteRoleItem : subSiteRoles) {
            if (siteRoleItem.Contact__r.Email != null
                    && !siteRoleItem.Contact__r.Email.contains('statkraft')) {
                UserWrapper tmpWrapper = idToUserWrapperMap.get(siteRoleItem.Contact__c);
                ContractWrapper contractWrapper = tmpWrapper.contractWrappers.get(meterToContract.get(siteRoleItem.Meter__c));

                MeterWrapper meterWrapper = contractWrapper.meters.get(siteRoleItem.Meter__c);
                if (meterWrapper == null) {
                    meterWrapper = new MeterWrapper();
                    meterWrapper.meter = meterMap.get(siteRoleItem.Meter__c);
                }

                if (siteRoleItem.msAwaitingPortalActivation__c == false) {
                    meterWrapper.activeRole = siteRoleItem;
                } else {
                    meterWrapper.requestedRole = siteRoleItem;
                }
                contractWrapper.meters.put(siteRoleItem.Meter__c, meterWrapper);

                tmpWrapper.contractWrappers.put(meterToContract.get(siteRoleItem.Meter__c), contractWrapper);
                idToUserWrapperMap.put(siteRoleItem.Contact__c, tmpWrapper);
            }
        }

        Map<String, User>usersMap = new Map<String, User>([
                SELECT Id, Name, Username, Email, IsActive, ContactId, LastLoginDate
                FROM User
                WHERE ContactId IN :contactIds
        ]);

        for (User tempUser : usersMap.values()) {
            UserWrapper tmpWrapper = idToUserWrapperMap.get(tempUser.ContactId);
            tmpWrapper.user = tempUser;
            idToUserWrapperMap.put(tempUser.ContactId, tmpWrapper);
        }
        List<UserLogin>userLogins = [
                SELECT Id, UserId, IsFrozen
                FROM UserLogin
                WHERE UserId IN :usersMap.keySet()
        ];
        for (UserLogin tempUserLogin : userLogins) {
            User tempUser = usersMap.get(tempUserLogin.UserId);
            UserWrapper tmpWrapper = idToUserWrapperMap.get(tempUser.ContactId);
            tmpWrapper.userLogin = tempUserLogin;
            idToUserWrapperMap.put(tempUser.ContactId, tmpWrapper);
        }

        result.userWrappers = idToUserWrapperMap.values();
        result.contracts = contractsMap.values();
        result.contractSchema = contractSchema.values();
        return result;
    }

    private static Map<Id, ContractWrapper> getContractWrappersSchema(Map<Id, Contract__c> contractsMap, Map<Id, Meter__c> meterMap, Map<Id, Id> meterToContract) {
        Map<Id, ContractWrapper> result = new Map<Id, ContractWrapper>();

        for (Id meterId : meterMap.keySet()) {
            Id contractId = meterToContract.get(meterId);

            ContractWrapper tmpWrapper = result.get(contractId);
            if (tmpWrapper == null)tmpWrapper = new ContractWrapper();

            MeterWrapper meterWrapper = tmpWrapper.meters.get(meterId);
            if (meterWrapper == null) {
                meterWrapper = new MeterWrapper();
                meterWrapper.meter = meterMap.get(meterId);
            }
            tmpWrapper.meters.put(meterId, meterWrapper);

            tmpWrapper.contract = contractsMap.get(contractId);
            result.put(contractId, tmpWrapper);
        }
        for (Id contractId : contractsMap.keySet()) {
            ContractWrapper tmpWrapper = result.get(contractId);
            if (tmpWrapper == null) {
                tmpWrapper = new ContractWrapper();
                tmpWrapper.contract = contractsMap.get(contractId);
            }

            result.put(contractId, tmpWrapper);
        }
        return result;
    }

    private static UserManagementWrapper setPicklistValues(UserManagementWrapper result, List<Contract__c> contracts) {
        result.picklistValues = new PicklistWrapper();
        List<Id> accountIds = new List<Id>();
        for (Contract__c contract : contracts) {
            accountIds.add(contract.Contract_Holder__c);
        }
        result.picklistValues.accounts = [SELECT Id, Name FROM Account WHERE Id IN:accountIds];

        result.picklistValues.salutation = new List<Map<String, String>>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get('Contact') ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String, Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('Salutation').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            Map<String, String> values = new Map<String, String>();
            values.put('label', pickListVal.getLabel());
            values.put('value', pickListVal.getValue());
            result.picklistValues.salutation.add(values);
        }

        return result;
    }

    public static Map<Id, Id> getMeterToContract(List<Id> contractIds) {
        List<MeterRegistration__c> meterRegistrations = [
                SELECT Meter__c, Contract__r.Name, Contract__r.Meter_Billing_Type__c, Contract__c,
                        Meter__r.Parent_Meter__c, Meter__r.Country__c, Meter__r.Name,
                        Contract__r.Parent_Contract__r.Name, Contract__r.Global_Portal_Market__c, Contract__r.Start_Date__c, Contract__r.KeepPortalAccessUntil__c,
                        Contract__r.End_Date__c, Valid_from__c, Valid_to__c
                FROM MeterRegistration__c
                WHERE Valid_from__c <= :Date.today()
                AND ((
                        Contract__r.Status__c = 'Active'
                        AND (
                                Valid_to__c >= :Date.today()
                                OR Valid_to__c = NULL
                        ))
                OR (
                        Contract__r.Status__c = 'Expired'
                        AND
                        Contract__r.KeepPortalAccessUntil__c >= :Date.today()
                ))
                AND (Contract__c IN :contractIds)
                ORDER BY Contract__r.Start_Date__c DESC
        ];
        Map<Id, Id> meterToContracts = new Map<Id, Id>();

        for (MeterRegistration__c tmpRegistration : meterRegistrations) {
            meterToContracts.put(tmpRegistration.Meter__c, tmpRegistration.Contract__c);
        }
        return meterToContracts;
    }

    @AuraEnabled
    public static void saveSettings(String contractRolesString, String siteRolesString) {
        UserManagementWrapper userDetails = getUserDetails();
        List<Site_Role__c> siteRoles = (List<Site_Role__c>) System.JSON.deserializeStrict(siteRolesString, List<Site_Role__c>.class);
        List<Contract_Role__c> contractRoles = (List<Contract_Role__c>) System.JSON.deserializeStrict(contractRolesString, List<Contract_Role__c>.class);

        Map<Id, UserWrapper> userWrapperMap = new Map<Id, UserWrapper>();
        for (UserWrapper tmpWrapper : userDetails.userWrappers) {
            userWrapperMap.put(tmpWrapper.contact.Id, tmpWrapper);
        }
        List<SObject> rolesToInsert = new List<SObject>();
        List<SObject> rolesToUpdate = new List<SObject>();
        List<SObject> rolesToDelete = new List<SObject>();
        for (Site_Role__c tmpRole : siteRoles) {
            UserWrapper userWrapper = userWrapperMap.get(tmpRole.Contact__c);
            for (ContractWrapper contractWrapper : userWrapper.contractWrappers.values()) {
                MeterWrapper meterWrapper = contractWrapper.meters.get(tmpRole.Meter__c);
                if (meterWrapper != null) {
                    if (meterWrapper.requestedRole != null) {//Delete Requested Role, will be replaced by a new request
                        rolesToDelete.add(meterWrapper.requestedRole);
                    }

                    if (tmpRole.Active__c == true) {
                        if (meterWrapper.activeRole == null || (meterWrapper.activeRole.End_Date__c < tmpRole.End_Date__c) || (meterWrapper.activeRole.End_Date__c != null && tmpRole.End_Date__c == null)) {
                            Site_Role__c newRequest = new Site_Role__c();
                            newRequest.msAwaitingPortalActivation__c = true;
                            newRequest.Role__c = 'Customer Portal';
                            newRequest.Contact__c = userWrapper.contact.Id;
                            newRequest.Meter__c = tmpRole.Meter__c;
                            newRequest.Start_Date__c = tmpRole.Start_Date__c;
                            newRequest.End_Date__c = tmpRole.End_Date__c;
                            newRequest.RecordTypeId = SITE_ROLE_RECORD_TYPE;
                            rolesToInsert.add(newRequest);
                        } else if (meterWrapper.activeRole != null) {
                            meterWrapper.activeRole.Start_Date__c = tmpRole.Start_Date__c;
                            meterWrapper.activeRole.End_Date__c = tmpRole.End_Date__c;
                            rolesToUpdate.add(meterWrapper.activeRole);
                        }
                    } else if (meterWrapper.activeRole != null) { //Remove Access
                        meterWrapper.activeRole.End_Date__c = Date.today().addDays(-1);
                        rolesToUpdate.add(meterWrapper.activeRole);
                    }
                }
            }
        }

        for (Contract_Role__c tmpRole : contractRoles) {
            UserWrapper userWrapper = userWrapperMap.get(tmpRole.Contact__c);
            ContractWrapper contractWrapper = userWrapper.contractWrappers.get(tmpRole.Contract__c);

            if (contractWrapper != null) {
                if (contractWrapper.requestedRole != null) {//Delete Requested Role, will be replaced by a new request
                    rolesToDelete.add(contractWrapper.requestedRole);
                }

                if (tmpRole.Active__c == true) {
                    if (contractWrapper.activeRole == null || (contractWrapper.activeRole.End_Date__c < tmpRole.End_Date__c) || (contractWrapper.activeRole.End_Date__c != null && tmpRole.End_Date__c == null)) {
                        Contract_Role__c newRequest = new Contract_Role__c();
                        newRequest.msAwaitingPortalActivation__c = true;
                        newRequest.Role__c = 'Customer Portal';
                        newRequest.Contact__c = userWrapper.contact.Id;
                        newRequest.Contract__c = tmpRole.Contract__c;
                        newRequest.Start_Date__c = tmpRole.Start_Date__c;
                        newRequest.End_Date__c = tmpRole.End_Date__c;
                        newRequest.RecordTypeId = CONTRACT_ROLE_RECORD_TYPE;
                        rolesToInsert.add(newRequest);
                    } else if (contractWrapper.activeRole != null) {
                        contractWrapper.activeRole.Start_Date__c = tmpRole.Start_Date__c;
                        contractWrapper.activeRole.End_Date__c = tmpRole.End_Date__c;
                        rolesToUpdate.add(contractWrapper.activeRole);
                    }
                } else if (contractWrapper.activeRole != null) { //Remove Access
                    contractWrapper.activeRole.End_Date__c = Date.today().addDays(-1);
                    rolesToUpdate.add(contractWrapper.activeRole);
                }
            }

        }
        insert rolesToInsert;
        update rolesToUpdate;
        delete rolesToDelete;
    }

    @AuraEnabled
    public static Boolean insertContact(String contactToInsertString, String contractRequestsString, String plantRequestsString) {
        Contact contactToInsert = (Contact) System.JSON.deserializeStrict(contactToInsertString, Contact.class);
        User me = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        contactToInsert.msAwaitingPortalActivation__c = true;
        contactToInsert.msPortalRequestBy__c = me.ContactId;
        if (contactToInsert.Id == null) {
            contactToInsert.RecordTypeId = CONTACT_RECORD_TYPE;
        }

        if (contactToInsert.AccountId == null) {
            List<Account> unknownAccount = [SELECT Id FROM Account WHERE Sandbox_Migration_Id__c = 'Unknown Account'];
            if (unknownAccount.size() > 0) {
                contactToInsert.AccountId = unknownAccount[0].Id;
            }
        }
        try {
            upsert contactToInsert;
        } catch (Exception e) {
            if (e.getMessage().indexOf('DUPLICATES_DETECTED') != -1) {
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.duplicateRuleHeader.allowSave = true;
                dml.duplicateRuleHeader.runAsCurrentUser = true;

                Database.SaveResult sr = Database.insert(contactToInsert, dml);
                if (sr.isSuccess()) {
                    System.debug('Duplicate account has been inserted in Salesforce!');
                }
            } else {
                throw new AuraHandledException(e.getMessage());
            }
        }

        if (contractRequestsString != null && contractRequestsString != '[]') {
            List<Contract_Role__c> contractRequests = (List<Contract_Role__c>) System.JSON.deserializeStrict(contractRequestsString, List<Contract_Role__c>.class);
            for (Contract_Role__c contractRole : contractRequests) {
                contractRole.msAwaitingPortalActivation__c = true;
                contractRole.Contact__c = contactToInsert.Id;
                contractRole.RecordTypeId = CONTRACT_ROLE_RECORD_TYPE;
                contractRole.Role__c = 'Customer Portal';
            }
            insert contractRequests;
        }
        if (plantRequestsString != null && plantRequestsString != '[]') {
            List<Site_Role__c> plantRequests = (List<Site_Role__c>) System.JSON.deserializeStrict(plantRequestsString, List<Site_Role__c>.class);
            for (Site_Role__c siteRole : plantRequests) {
                siteRole.msAwaitingPortalActivation__c = true;
                siteRole.Contact__c = contactToInsert.Id;
                siteRole.RecordTypeId = SITE_ROLE_RECORD_TYPE;
                siteRole.Role__c = 'Customer Portal';
            }
            insert plantRequests;
        }

        return true;
    }

    @AuraEnabled
    public static void changeUserStatus(String userId, Boolean isActive) {
        UserLogin userLogin = [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE UserId = :userId];
        userLogin.IsFrozen = !isActive;
        update userLogin;
    }

    @AuraEnabled
    public static void deleteRelationshipToContact(String contactString) {
        Contact contactToRemove = (Contact) System.JSON.deserializeStrict(contactString, Contact.class);

        User userMe = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Contact contactMe = [SELECT Id, Name FROM Contact WHERE Id = :userMe.ContactId];
        List<Contract_Role__c> contractRoles = [
                SELECT Contract__c, Role__c, Contact__c, Start_Date__c, End_Date__c
                FROM Contract_Role__c
                WHERE Contact__c = :contactMe.Id
                AND Role__c INCLUDES ('Contractual contact')
                AND Start_Date__c <= :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
        ];
        List<String> contractIds = new List<String>();
        for (Contract_Role__c tmpRole : contractRoles) {
            contractIds.add(tmpRole.Contract__c);
        }

        List<Contract_Role__c> contractRolesToRemove = [
                SELECT Contract__c, Contract__r.Name, Contract__r.Start_Date__c,
                        Contract__r.End_Date__c, Role__c, Contact__c, Start_Date__c,
                        End_Date__c, msAwaitingPortalActivation__c
                FROM Contract_Role__c
                WHERE Contract__c IN:contractIds
                AND Contact__c = :contactToRemove.Id
        ];
        List<MeterRegistration__c> meterRegs = [
                SELECT Meter__c, Meter__r.Name, Contract__r.Start_Date__c, Contract__r.End_Date__c, Contract__r.Name, Active__c
                FROM MeterRegistration__c
                WHERE Contract__c IN :contractIds
        ];
        List<Id> meterIds = new List<Id>();
        for (MeterRegistration__c regItem : meterRegs) {
            meterIds.add(regItem.Meter__c);
        }

        List<Site_Role__c> siteRolesToRemove = [
                SELECT Id, Contact__c
                FROM Site_Role__c
                WHERE Meter__c IN :meterIds
                AND Contact__c = :contactToRemove.Id
        ];

        contactToRemove.msPortalRequestBy__c = null;
        contactToRemove.msAwaitingPortalActivation__c = false;
        update contactToRemove;

        delete contractRolesToRemove;
        delete siteRolesToRemove;
    }


    public class UserWrapper {
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Map<Id, ContractWrapper> contractWrappers { get; set; }
        @AuraEnabled public User user { get; set; }
        @AuraEnabled public UserLogin userLogin { get; set; }
    }
    public class ContractWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Contract__c contract { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Contract_Role__c activeRole { get; set; }
        @AuraEnabled public Contract_Role__c requestedRole { get; set; }
        @AuraEnabled public Map<Id, MeterWrapper> meters { get; set; }

        public ContractWrapper() {
            meters = new Map<Id, MeterWrapper>();
        }
    }
    public class MeterWrapper {
        @AuraEnabled public Meter__c meter { get; set; }
        @AuraEnabled public Site_Role__c activeRole { get; set; }
        @AuraEnabled public Site_Role__c requestedRole { get; set; }
    }
    public class UserManagementWrapper {
        @AuraEnabled public List<Contract__c> contracts { get; set; }
        @AuraEnabled public List<UserWrapper> userWrappers { get; set; }
        @AuraEnabled public PicklistWrapper picklistValues { get; set; }
        @AuraEnabled public List<ContractWrapper> contractSchema { get; set; }
    }
    public class PicklistWrapper {
        @AuraEnabled public List<Account> accounts { get; set; }
        @AuraEnabled public List<Map<String, String>> salutation { get; set; }
    }
}