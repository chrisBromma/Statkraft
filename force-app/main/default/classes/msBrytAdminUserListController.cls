/****************************************************************************************************
* Class msBrytAdminUserListController
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   2020-01-16
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)	            2020-01-16       	Init version.
*****************************************************************************************************/

public without sharing class msBrytAdminUserListController {
    private static final Id BRYT_CONTACT_RECORD_TYPE_ID =
            Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('msBrytContact').getRecordTypeId();
    private static final Id BRYT_ACCOUNT_RECORD_TYPE_ID =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('msBrytAccount').getRecordTypeId();
    private static final Id BRYT_CONTRACT_RECORD_TYPE_ID =
            Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
    private static final Id BRYT_CONTRACT_ROLE_RECORD_TYPE_ID =
            Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();

    @AuraEnabled
    public static Contact getNewContact() {
        return new Contact();
    }
    @AuraEnabled
    public static Boolean freezeCommunityUser(Id usrId) {
        msBrytUtility.checkObjectAccess(usrId);
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            UserLogin usrLogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :usrId LIMIT 1];
            User user = [SELECT Id, Name FROM User WHERE Id = :usrId];

            try {
                usrLogin.IsFrozen = true;
                update usrLogin;
                msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
                newChangelog.msUser__c = user.Id;
                newChangelog.msChangelog__c = 'User ' + user.Name +
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
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }

    }

    @AuraEnabled
    public static Boolean unfreezeCommunityUser(Id usrId) {
        msBrytUtility.checkObjectAccess(usrId);
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            UserLogin usrLogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :usrId LIMIT 1];
            User user = [SELECT Id, Name FROM User WHERE Id = :usrId];
            try {
                usrLogin.IsFrozen = false;
                update usrLogin;
                msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
                newChangelog.msUser__c = user.Id;
                newChangelog.msChangelog__c = 'User ' + user.Name +
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
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }

    }

    @AuraEnabled
    public static Boolean resetCommunityUserPassword(Id userId) {
        msBrytUtility.checkObjectAccess(userId);
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            try {
                User targetUser = [SELECT Name FROM User WHERE Id = :userId];
                System.resetPassword(userId, true);
                msBrytTPIChangelog__c changelog = new msBrytTPIChangelog__c();
                changelog.msUser__c = userId;
                User thisUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                changelog.msChangelog__c = 'The TPI ' + thisUser.Name + ' under ID ' + thisUser.Id + ' reset the Password of User ' + targetUser.Name;
                insert changelog;
                msBrytTPIChangelog__c newChangelog = new msBrytTPIChangelog__c();
                newChangelog.msUser__c = userId;
                newChangelog.msChangelog__c = 'User ' + targetUser.Name +
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
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }

    }
    @AuraEnabled
    public static void insertCommunityContact(Contact contactToInsert, Contract_Role__c contractRoleToInsert) {
        msBrytUtility.checkObjectAccess(contractRoleToInsert.Contract__c);
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            User runningUser = [SELECT AccountId, Account.OwnerId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (String.isNotBlank(contactToInsert.AccountId)) {
                contactToInsert.OwnerId = [SELECT OwnerId FROM Account WHERE Id = :contactToInsert.AccountId].OwnerId;
            } else {
                contactToInsert.AccountId = runningUser.AccountId;
                contactToInsert.OwnerId = runningUser.Account.OwnerId;
            }
            contactToInsert.RecordTypeId = BRYT_CONTACT_RECORD_TYPE_ID;
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            Database.SaveResult result = Database.insert(contactToInsert, dml);
            if (result.isSuccess()) {
                if (contractRoleToInsert != null && String.isNotBlank(contractRoleToInsert.Contract__c)) {
                    msBrytUtility.checkObjectAccess(contractRoleToInsert.Contract__c);

                    contractRoleToInsert.Contact__c = result.getId();
                    contractRoleToInsert.Role__c = 'Customer Portal';
                    contractRoleToInsert.RecordTypeId = BRYT_CONTRACT_ROLE_RECORD_TYPE_ID;
                    updateContractRole(JSON.serialize(contractRoleToInsert));
                }
                insertCommunityUser(contactToInsert);
            } else {
                throw new AuraHandledException('The User could not be inserted, please inform your administrator');
            }
        }
    }
    @AuraEnabled
    public static void updateContractRole(String contractRole) {
        Contract_Role__c role = (Contract_Role__c) JSON.deserialize(contractRole, Contract_Role__c.class);

        if(role.Contract__c!=null){
            msBrytUtility.checkObjectAccess(role.Contract__c);
        }else{
            Contract_Role__c oldRole =[SELECT Id, Contract__c FROM Contract_Role__c WHERE Id=:role.Id];
            msBrytUtility.checkObjectAccess(oldRole.Contract__c);
        }

        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            if (String.isBlank(role.Role__c)) {
                role.Role__c = 'Customer Portal';
            }
            if (String.isBlank(role.Id) && isDuplicatedContractRole(role)) {
                throw new AuraHandledException('User is already assigned to this Contract');
            }
            try {
                upsert role;
            } catch (Exception e) {
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }
    }

    @AuraEnabled
    public static String getBrytAccounts() {

        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        Map<String, String> accountNamesByIds = new Map<String, String>();

        // If Bryt-Contat is an admin ("isUser Admin" is checked), he can see ALL Bryt-Accounts.
        if(userDetails.isAdmin == true){

            List<Account> allBrytAccountsForBrytAdmins = [
                    SELECT Id, Name
                    FROM Account
                    WHERE RecordType.Id = :BRYT_ACCOUNT_RECORD_TYPE_ID
            ];

            for (Account acc : allBrytAccountsForBrytAdmins) {
                accountNamesByIds.put(acc.Id, acc.Name);
            }
        } else { // Use the old logic: Take Accounts from Session.

            for (msBrytUtility.AccountWrapper acc : userDetails.accounts) {
                accountNamesByIds.put(acc.account.Id, acc.account.Name);
            }
        }

        return JSON.serialize(accountNamesByIds);
    }

    @AuraEnabled
    public static void updateUser(User userToUpdate) {
        msBrytUtility.checkObjectAccess(userToUpdate.Id);
        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            try {
                update userToUpdate;
            } catch (Exception e) {
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }
    }

    @AuraEnabled
    public static void removeContractRole(String contractRoleId) {
        Contract_Role__c role = [SELECT Id, Contract__c FROM Contract_Role__c WHERE Id = :contractRoleId];
        msBrytUtility.checkObjectAccess(role.Contract__c);

        msBrytUtility.UserDetails userDetails = msBrytUtility.getUserDetails();
        if (userDetails.isAdmin || userDetails.isTPI) {
            try {
                delete role;
            } catch (Exception e) {
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            throw new AuraHandledException('You lack permissions for this action');
        }
    }

    private static Boolean isDuplicatedContractRole(Contract_Role__c newRole) {
        return 0 < [
                SELECT COUNT()
                FROM Contract_Role__c
                WHERE RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
                AND Contact__c = :newRole.Contact__c
                AND Contract__c = :newRole.Contract__c
        ];
    }

    private static void insertCommunityUser(Contact relatedContact) {
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
        userToInsert.DefaultCurrencyIsoCode = 'GBP';
        try {
            insert(userToInsert);
        } catch (DmlException e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(Label.msBrytToastUsernameError);
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException('An unexpected error occurred, please inform your administrator');
        }
    }
}