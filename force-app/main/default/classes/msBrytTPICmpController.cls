/****************************************************************************************************
 * Class msBrytTPICmpController
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 31.01.2019
 *   Description :  Controller for the msBrytTPICmp Lightning Component. Features multiple get methods that
 *                  query for Accounts, Contacts, Contracts, Contract Roles and Users that are administered
 *                  by the current User in the Bryt Customer Portal and gives access to create Contract Roles
 *                  Bryt Community Portal Users and Edit, Freeze, Unfreeze them and reset their password.
 *                  Also provides access to and creates entries for the changelog of all actions performed
 *                  through this Component.
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	31.01.2019	Init version.
 *****************************************************************************************************/
public without sharing class msBrytTPICmpController {

    @AuraEnabled
    public static List<Contact> getContacts() {
        List<User> userList = getUsers();
        Set<Id> contactIdSet = new Set<Id>();
        for (User userItem : userList) {
            contactIdSet.add(userItem.ContactId);
        }
        return [SELECT Id, Name FROM Contact WHERE Id IN :contactIdSet AND RecordType.DeveloperName = :'msBrytContact'];
    }
    @AuraEnabled
    public static List<User> getUsers() {
        User runningUser = [SELECT ContactId, Contact.AccountId, Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (msBrytUtility.getUserDetails().isTPI) {
            return [
                    SELECT Id, Name, FirstName, LastName, Email, ContactId, Contact.Name, Username, Contact.Account.Name
                    FROM User
                    WHERE Profile.Name = 'Bryt Customer Community User'
                    AND Contact.AccountId = :runningUser.Contact.AccountId
                    AND Id != :UserInfo.getUserId()
                    AND IsActive = TRUE
            ];
        } else {
            return null;
        }

    }
    @AuraEnabled
    public static List<UserLogin> getUserLogins() {
        List<User> administeredUser = getUsers();
        List<Id> usersIdList = new List<Id>();
        for (User userItem : administeredUser) {
            usersIdList.add(userItem.Id);
        }
        return [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId IN :usersIdList];
    }
    @AuraEnabled
    public static List<Contract_Role__c> getContractRoles() {
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        List<Id> contractIds = new List<Id>();
        for (Contract_Role__c tempRole : userDetails.contractRoles) {
            if (tempRole.Bryt_isTPI__c) {
                contractIds.add(tempRole.Contract__c);
            }
        }
        return [
                SELECT Id, Name, Contact__c, Contract__c,
                        Contract__r.Name, Contact__r.Name, Contract__r.Contract_Holder__r.Name,
                        Start_Date__c, End_Date__c
                FROM Contract_Role__c
                WHERE RecordType.DeveloperName = :'Bryt_Contract_Role' AND Contract__c IN :contractIds
                AND Contract__r.POD_ID__c != null
        ];
    }
    @AuraEnabled
    public static List<msBrytTPIChangelog__c> getChangelogs() {
        List<Contract__c> administeredContracts = msBrytUtility.getUserDetails().tpiContracts;
        Set<Id> administeredContractIds = new Set<Id>();
        for (Contract__c contractItem : administeredContracts) {
            administeredContractIds.add(contractItem.Id);
        }
        List<Contract_Role__c> administeredContractRoles = [
                SELECT Id
                FROM Contract_Role__c
                WHERE Contract__c IN :administeredContractIds
                AND RecordType.DeveloperName = :'Bryt_Contract_Role'
                AND Contract__r.POD_ID__c != null
        ];
        Set<Id> administeredContractRoleIds = new Set<Id>();
        for (Contract_Role__c roleItem : administeredContractRoles) {
            administeredContractRoleIds.add(roleItem.Id);
        }
        User thisUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User> administeredUsers = [
                SELECT Id, ContactId
                FROM User
                WHERE Contact.RecordType.DeveloperName = :'msBrytContact'
                AND Profile.Name = 'Bryt Customer Community User'
                AND Contact.AccountId = :thisUser.Contact.AccountId
        ];
        Set<Id> administeredContactIds = new Set<Id>();
        Set<Id> administeredUserIds = new Set<Id>();
        for (User userItem : administeredUsers) {
            administeredContactIds.add(userItem.ContactId);
            administeredUserIds.add(userItem.Id);
        }
        return [
                SELECT Id, msChangelog__c
                FROM msBrytTPIChangelog__c
                WHERE msUser__c IN :administeredUserIds
                OR msContact__c IN :administeredContactIds
                OR msContract__c IN :administeredContractIds
                OR msContractRole__c IN :administeredContractRoleIds
                ORDER BY CreatedDate DESC
        ];
    }
    @AuraEnabled
    public static Id insertContractRole(Contact usrContact, Contract__c admContract, String strStartDate, String strEndDate) {
        msBrytUtility.checkObjectAccess(admContract.Id);

        Id recordTypeId = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
        List<Contact> legalContactList = getContacts();
        List<Contract__c> legalContractList = msBrytUtility.getUserDetails().tpiContracts;
        Set<Id> legalContactIdSet = new Set<Id>();
        Set<Id> legalContractIdSet = new Set<Id>();
        for (Contact legalItem : legalContactList) {
            legalContactIdSet.add(legalItem.Id);
        }
        for (Contract__c legalItem : legalContractList) {
            legalContractIdSet.add(legalItem.Id);
        }
        if (!(legalContactIdSet.contains(usrContact.Id) && legalContractIdSet.contains(admContract.Id))) {
            throw new AuraHandledException('Illegal Assignment');
        }
        Date crStartDate = Date.valueOf(strStartDate);
        Date crEndDate = Date.valueOf(strEndDate);

        Contract_Role__c newContractRole = new Contract_Role__c();
        newContractRole.Contact__c = usrContact.Id;
        newContractRole.Contract__c = admContract.Id;
        newContractRole.Start_Date__c = crStartDate;
        newContractRole.End_Date__c = crEndDate;
        newContractRole.Account__c = admContract.Contract_Holder__c;
        newContractRole.Bryt_isTradingEnabled__c = true;
        newContractRole.Role__c = 'Customer Portal';
        newContractRole.RecordTypeId = recordTypeId;
        try {
            Database.SaveResult result = Database.insert(newContractRole, true);
            if (result.isSuccess()) {
                msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
                newChangelog.msContact__c = usrContact.Id;
                newChangelog.msContract__c = admContract.Id;
                newChangelog.msContractRole__c = result.getId();
                User connectedUsr = [SELECT Id FROM User WHERE ContactId = :usrContact.Id LIMIT 1];
                newChangelog.msUser__c = connectedUsr.Id;
                newChangelog.msChangelog__c = 'Contract Role between Contract ' + admContract.Name +
                        ' and Contact ' + usrContact.Name +
                        ' for the interval from ' + strStartDate +
                        ' to ' + strEndDate +
                        ' set by User ' + UserInfo.getName() +
                        ' TIMESTAMP: ' + Datetime.now().format();
                try {
                    insert newChangelog;
                } catch (Exception e) {
                    throw new AuraHandledException('The Contract Role was successfully created, however the Log could not be created. Please inform your System Administrator');
                }

                return result.getId();
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return null;
    }
    @AuraEnabled
    public static Boolean deleteContractRole(Contract_Role__c roleToDelete) {
        msBrytUtility.checkObjectAccess(roleToDelete.Contract__c);
        List<Contract_Role__c> legalRolesList = getContractRoles();
        if (!legalRolesList.contains(roleToDelete)) {
            throw new AuraHandledException('Illegal Assignment');
        }
        try {
            delete roleToDelete;
            msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
            newChangelog.msContact__c = roleToDelete.Contact__c;
            newChangelog.msContract__c = roleToDelete.Contract__c;
            User connectedUsr = [SELECT Id FROM User WHERE ContactId = :roleToDelete.Contact__c LIMIT 1];
            newChangelog.msUser__c = connectedUsr.Id;
            newChangelog.msChangelog__c = 'Contract Role deleted between Contract ' + roleToDelete.Contract__r.Name +
                    ' and Contact ' + roleToDelete.Contact__r.Name +
                    ' for the interval from ' + roleToDelete.Start_Date__c +
                    ' to ' + roleToDelete.End_Date__c +
                    ' by User ' + UserInfo.getName() +
                    ' TIMESTAMP: ' + Datetime.now().format();
            try {
                insert newChangelog;
            } catch (Exception e) {
                throw new AuraHandledException('The Contract Role was successfully deleted, however the Log could not be created. Please inform your System Administrator');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }
    @AuraEnabled
    public static Boolean updateUserDetails(User userToUpdate) {
        msBrytUtility.checkObjectAccess(userToUpdate.Id);
        userToUpdate.Username = userToUpdate.Email + '.brytflex';
        List<User> legalUsersList = getUsers();
        Set<Id> legalIdList = new Set<Id>();
        for (User legalItem : legalUsersList) {
            legalIdList.add(legalItem.Id);
        }
        if (!legalIdList.contains(userToUpdate.Id)) {
            throw new AuraHandledException('Illegal User Assignment');
        }
        try {
            update userToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }
    @AuraEnabled
    public static Id insertCommunityContact(Contact contactToInsert) {
        User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (msBrytUtility.getUserDetails().isTPI) {
            Savepoint sp = Database.setSavepoint();
            Id newUserId = null;
            try {
                contactToInsert.Id = insertContact(contactToInsert, currentUser.Contact.AccountId);
                System.debug(contactToInsert.Id + ' is Id of inserted Contact');
                newUserId = insertCommunityUser(contactToInsert);
                msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
                newChangelog.msContact__c = contactToInsert.Id;
                newChangelog.msUser__c = newUserId;
                User matchingUser = [SELECT Id, Name FROM User WHERE Id = :newUserId LIMIT 1];
                newChangelog.msChangelog__c = 'User ' + matchingUser.Name +
                        ' with connected Contact ' + contactToInsert.FirstName +
                        ' ' + contactToInsert.LastName +
                        ' created by User ' + UserInfo.getName() +
                        ' TIMESTAMP: ' + Datetime.now().format();
                try {
                    insert newChangelog;
                } catch (Exception e) {
                    throw new AuraHandledException('The user/contact was successfully created, however the Log could not be created. Please inform your System Administrator');
                }
            } catch (DmlException e) {
                Database.rollback(sp);
                throw new AuraHandledException(e.getMessage());

            } catch (Exception e) {
                Database.rollback(sp);
                throw new AuraHandledException(e.getMessage());
            }
            return newUserId;
        } else {
            return null;
        }

    }
    @AuraEnabled
    public static Id insertCommunityUser(Contact relatedContact) {
        User userToInsert = new User();
        userToInsert.FirstName = relatedContact.FirstName;
        userToInsert.LastName = relatedContact.LastName;
        userToInsert.ContactId = relatedContact.Id;
        userToInsert.Email = relatedContact.Email;
        userToInsert.Username = relatedContact.Email + '.brytflex';
        userToInsert.CommunityNickname = (String.valueOfGmt(Datetime.now()) + relatedContact.FirstName + relatedContact.LastName).abbreviate(40);
        userToInsert.Alias = 'BRYTCCU';
        userToInsert.ProfileId = [SELECT Id FROM Profile WHERE Name = :'Bryt Customer Community User' LIMIT 1].Id;
        userToInsert.EmailEncodingKey = 'UTF-8';
        userToInsert.LanguageLocaleKey = 'en_US';
        userToInsert.LocaleSidKey = 'en_GB';
        userToInsert.TimeZoneSidKey = 'Europe/London';
        userToInsert.CurrencyIsoCode = 'GBP';
        try {
            Database.SaveResult result = Database.insert(userToInsert, true);
            return result.getId();
        } catch (DmlException e) {
            throw e;
        } catch (Exception e) {
            throw e;
        }
    }
    @AuraEnabled
    public static Id insertContact(Contact contactToInsert, Id relatedAccountId) {
        contactToInsert.AccountId = relatedAccountId;
        contactToInsert.OwnerId = [SELECT OwnerId FROM Account WHERE Id = :relatedAccountId LIMIT 1].OwnerId;
        contactToInsert.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('msBrytContact').getRecordTypeId();
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.SaveResult result = Database.insert(contactToInsert, dml);
        if (result.isSuccess()) {
            return result.getId();
        } else {
            return null;
        }
    }
    @AuraEnabled
    public static Contact getNewContact() {
        return new Contact();
    }
    @AuraEnabled
    public static Boolean freezeCommunityUser(UserLogin usrLogin) {
        msBrytUtility.checkObjectAccess(usrLogin.UserId);
        List<User> legalUsersList = getUsers();
        Set<Id> legalIdList = new Set<Id>();
        for (User legalItem : legalUsersList) {
            legalIdList.add(legalItem.Id);
        }
        if (!legalIdList.contains(usrLogin.UserId)) {
            throw new AuraHandledException('Illegal User Assignment');
        }
        User matchingUser = new User();
        for (User userItem : legalUsersList) {
            if (userItem.Id == usrLogin.UserId) {
                matchingUser = userItem;
            }
        }
        try {
            usrLogin.IsFrozen = true;
            update usrLogin;
            msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
            newChangelog.msUser__c = matchingUser.Id;
            newChangelog.msChangelog__c = 'User ' + matchingUser.Name +
                    ' frozen by User ' + UserInfo.getName() +
                    ' TIMESTAMP: ' + Datetime.now().format();
            try {
                insert newChangelog;
            } catch (Exception e) {
                throw new AuraHandledException('The user was successfully frozen, however the Log could not be created. Please inform your System Administrator');
            }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean unfreezeCommunityUser(UserLogin usrLogin) {
        msBrytUtility.checkObjectAccess(usrLogin.UserId);
        List<User> legalUsersList = getUsers();
        Set<Id> legalIdList = new Set<Id>();
        for (User legalItem : legalUsersList) {
            legalIdList.add(legalItem.Id);
        }
        if (!legalIdList.contains(usrLogin.UserId)) {
            throw new AuraHandledException('Illegal User Assignment');
        }
        User matchingUser = new User();
        for (User userItem : legalUsersList) {
            if (userItem.Id == usrLogin.UserId) {
                matchingUser = userItem;
            }
        }
        try {
            usrLogin.IsFrozen = false;
            update usrLogin;
            msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
            newChangelog.msUser__c = matchingUser.Id;
            newChangelog.msChangelog__c = 'User ' + matchingUser.Name +
                    ' unfrozen by User ' + UserInfo.getName() +
                    ' TIMESTAMP: ' + Datetime.now().format();
            try {
                insert newChangelog;
            } catch (Exception e) {
                throw new AuraHandledException('The user was successfully unfrozen, however the Log could not be created. Please inform your System Administrator');
            }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean resetCommunityUserPassword(User usr) {
        msBrytUtility.checkObjectAccess(usr.Id);
        List<User> legalUsersList = getUsers();
        Set<Id> legalIdList = new Set<Id>();
        for (User legalItem : legalUsersList) {
            legalIdList.add(legalItem.Id);
        }
        if (!legalIdList.contains(usr.Id)) {
            throw new AuraHandledException('Illegal User Assignment');
        }
        try {
            System.resetPassword(usr.Id, true);
            msBrytTPIChangelog__c changelog = new msBrytTPIChangelog__c();
            changelog.msUser__c = usr.Id;
            changelog.msChangelog__c = 'The TPI ' + UserInfo.getName() + ' under ID ' + UserInfo.getUserId() + ' reset the Password of User ' + usr.Name;
            insert changelog;
            msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
            newChangelog.msUser__c = usr.Id;
            newChangelog.msChangelog__c = 'User ' + usr.Name +
                    ' frozen by User ' + UserInfo.getName() +
                    ' TIMESTAMP: ' + Datetime.now().format();
            try {
                insert newChangelog;
            } catch (Exception e) {
                throw new AuraHandledException('The user had their password successfully reset, however the Log could not be created. Please inform your System Administrator');
            }
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean createUserEditChangelog(User relatedUser) {
        msBrytUtility.checkObjectAccess(relatedUser.Id);
        msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
        newChangelog.msUser__c = relatedUser.Id;
        newChangelog.msChangelog__c = 'User ' + relatedUser.Name +
                ' updated by User ' + UserInfo.getName() +
                ' TIMESTAMP: ' + Datetime.now().format();
        try {
            insert newChangelog;
        } catch (Exception e) {
            throw new AuraHandledException('The user was successfully updated, however the Log could not be created. Please inform your System Administrator');
        }
        return true;
    }
}