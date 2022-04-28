/****************************************************************************************************
* Class msUserManagementApprovalController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   04.11.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   04.11.2019      	    Init version.
*****************************************************************************************************/

public without sharing class msUserManagementApprovalController {

    public static final String USERNAME_SUFFIX = Label.msPortalUsernameSufix;


    @AuraEnabled
    public static String getInitialApprovalRequests() {
        String market = '';
        String userProfileName = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        switch on userProfileName {
            when 'DE EEG' {
                market = 'Germany';
            }
            when 'France' {
                market = 'France';
            }
            when 'UK Flex' {
                market = 'Flex';
            }
            when 'UK PPA' {
                market = 'UK';
            }
            when 'UK Ireland' {
                market = 'Ireland';
            }
            when else {
                market = 'Germany';
            }
        }
        return market;
    }

    @AuraEnabled
    public static ApprovalWrapper getApprovalRequests(String market) {
        ApprovalWrapper result = new ApprovalWrapper();
        List<String> userNames = new List<String>();
        List<String> accountIds = new List<String>();
        Map<String, UserWrapper> userWrappers = new Map<String, UserWrapper>();
        Map<String, User>userMap = new Map<String, User>();

        List<Contract_Role__c> contractRequests = [
                SELECT Id, Contact__c, Contract__c, Contract__r.Name, Role__c, msAwaitingPortalActivation__c,
                        Start_Date__c, End_Date__c, CreatedBy.ContactId, Contract__r.Global_Portal_Market__c
                FROM Contract_Role__c
                WHERE msAwaitingPortalActivation__c = TRUE
                AND Contract__r.Global_Portal_Market__c = :market
                AND Contact__c != NULL
                AND Contract__c != NULL
        ];
        List<Site_Role__c> meterRequests = [
                SELECT Id, Contact__c, Meter__c, Meter__r.Name, Role__c, msAwaitingPortalActivation__c,
                        Start_Date__c, End_Date__c, CreatedBy.ContactId
                FROM Site_Role__c
                WHERE msAwaitingPortalActivation__c = TRUE
                AND Contact__c != NULL
                AND Meter__c != NULL
        ];
        //remove roles of wrong market
        Map<Id, Contract__c> meterToContractMap = msUtility.determineContract(meterRequests);
        for (Integer i = 0; i < meterRequests.size(); i++) {
            if (meterToContractMap.get(meterRequests[i].Meter__c) == null
                    || meterToContractMap.get(meterRequests[i].Meter__c).Global_Portal_Market__c != market) {
                meterRequests.remove(i);
                i--;
            }
        }

        for (Contract_Role__c tempContract : contractRequests) {
            UserWrapper tempUserWrapper = userWrappers.get(tempContract.Contact__c);
            if (tempUserWrapper == null) {
                tempUserWrapper = new UserWrapper();
            }

            tempUserWrapper.contractRoles.add(tempContract);
            tempUserWrapper.sortDate = msLepton.min(tempUserWrapper.sortDate, tempContract.Start_Date__c);
            userWrappers.put(tempContract.Contact__c, tempUserWrapper);
        }
        for (Site_Role__c tempSiteRole : meterRequests) {
            UserWrapper tempUserWrapper = userWrappers.get(tempSiteRole.Contact__c);
            if (tempUserWrapper == null) {
                tempUserWrapper = new UserWrapper();
            }

            tempUserWrapper.siteRoles.add(tempSiteRole);
            tempUserWrapper.sortDate = msLepton.min(tempUserWrapper.sortDate, tempSiteRole.Start_Date__c);
            userWrappers.put(tempSiteRole.Contact__c, tempUserWrapper);
        }

        List<Contact> contactRequests = [
                SELECT Id, Name, msPortalRequestBy__c, AccountId, Account.Name, msAwaitingPortalActivation__c, Email, msHideFromUserManagement__c
                FROM Contact
                WHERE msAwaitingPortalActivation__c = TRUE
                OR Id IN:userWrappers.keySet()
        ];

        for (Contact tempContact : contactRequests) {
            userNames.add(tempContact.Email + USERNAME_SUFFIX);
            accountIds.add(tempContact.AccountId);
        }

        List<User> users = [
                SELECT Id, Name, Username, Email
                FROM User
                WHERE Username IN:userNames
        ];

        for (User tempUser : users) {
            userMap.put(tempUser.Username, tempUser);
        }
        Map<Id, Account> accountsMap = new Map<Id, Account>([
                SELECT Id, Name
                FROM Account
                WHERE Id IN :accountIds
        ]);

        for (Contact tempContact : contactRequests) {
            UserWrapper tempUserWrapper = userWrappers.get(tempContact.Id);
            if (tempUserWrapper == null) {
                tempUserWrapper = new UserWrapper();
            }

            tempUserWrapper.contact = tempContact;
            tempUserWrapper.account = accountsMap.get(tempContact.AccountId);
            tempUserWrapper.user = userMap.get(tempContact.Email + USERNAME_SUFFIX);

            if (tempContact.msHideFromUserManagement__c == true) {
                tempUserWrapper.hideFromUserManagement = true;
            }
            userWrappers.put(tempContact.Id, tempUserWrapper);
        }


        Decimal contactRequestsSize = contactRequests.size();
        Integer iterations = (Integer) Math.ceil(contactRequestsSize.divide(50, 2));
        for (Integer i = 0; i < iterations; i++) {
            List<Contact> tempContactList = new List<Contact>();
            for (Integer j = (i * 50); (j < (i * 50) + 50) && j < contactRequestsSize; j++) {
                tempContactList.add(contactRequests[j]);
            }

            List<Datacloud.FindDuplicatesResult> duplicates = Datacloud.FindDuplicates.findDuplicates(tempContactList);
            for (Integer j = 0; j < duplicates.size(); j++) {
                for (Datacloud.DuplicateResult dupeResult : duplicates[j].getDuplicateResults()) {
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            if (matchRecord.getRecord() instanceof Contact) {
                                UserWrapper tempUserWrapper = userWrappers.get(contactRequests[j + (i * 50)].Id);
                                if (tempUserWrapper.duplicates == null) {
                                    tempUserWrapper.duplicates = new Set<SObject>();
                                }
                                tempUserWrapper.duplicates.add(matchRecord.getRecord());
                                userWrappers.put(contactRequests[j + (i * 50)].Id, tempUserWrapper);
                            }
                        }
                    }
                }
            }
        }
        //remove requests without role
        for (String key : userWrappers.keySet()) {
            UserWrapper userWrapper = userWrappers.get(key);
            if ((userWrapper.siteRoles == null || userWrapper.siteRoles.size() == 0) && (userWrapper.contractRoles == null || userWrapper.contractRoles.size() == 0)) {
                userWrappers.remove(key);
            }
        }
        List<UserWrapper> resultWrappers = userWrappers.values();
        resultWrappers.sort();
        result.userWrappers = resultWrappers;
        result.license = [SELECT TotalLicenses, UsedLicenses FROM UserLicense WHERE Name = 'Customer Community'];
        result.usersToRetire = getUsersToRetire();
        return result;
    }

    public static List<UserWrapper> getUsersToRetire() {
        Date today = Date.today();
        List<String> meterIds = new List<String>();
        Map<Id, List<Contract_Role__c>> contractRoleMap = new Map<Id, List<Contract_Role__c>>();
        Map<Id, List<Site_Role__c>> siteRoleMap = new Map<Id, List<Site_Role__c>>();
        List<Id> activeContactIds = new List<Id>();
        List<Id> contactIdsToDeactivate = new List<Id>();
        List<UserWrapper> retireWrappers = new List<UserWrapper>();
        msPortalSystemSetting__mdt portalSettings = msUtility.getPortalSettings();
        Integer lastLoginDuration = Integer.valueOf(portalSettings.UserManagementLastLoginDuration__c);
        Map<Id, Boolean> isContractualContactMap = new Map<Id, Boolean>();

        List<User> activeUsers = [
                SELECT Id, ContactId, Contact.Name, Name, Username, Email, LastLoginDate
                FROM User
                WHERE IsActive = TRUE
                AND Profile.Name = 'Global Customer Community User'
                AND ContactId != NULL
        ];
        for (User tempUser : activeUsers) {
            activeContactIds.add(tempUser.ContactId);
        }

        List<Contract_Role__c> subContractRoles = [
                SELECT Contact__c
                FROM Contract_Role__c
                WHERE Contact__c IN:activeContactIds
                AND Role__c INCLUDES ('Customer Portal')
                AND Contract__r.KeepPortalAccessUntil__c > :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
        ];
        List<Contract_Role__c> subContractualContactRoles = [
                SELECT Contact__c
                FROM Contract_Role__c
                WHERE Contact__c IN :activeContactIds
                AND Role__c INCLUDES ('Contractual contact')
                AND Contract__r.KeepPortalAccessUntil__c > :Date.today()
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
        ];

        for (Contract_Role__c tempContractRole : subContractRoles) {
            List<Contract_Role__c> contractsOfContact = contractRoleMap.get(tempContractRole.Contact__c);
            if (contractsOfContact == null) {
                contractsOfContact = new List<Contract_Role__c>();
            }

            contractsOfContact.add(tempContractRole);
            contractRoleMap.put(tempContractRole.Contact__c, contractsOfContact);
        }
        for (Contract_Role__c tempContractRole : subContractualContactRoles) {
//if there is a record is the list, the contact is contractual contact
            isContractualContactMap.put(tempContractRole.Contact__c, true);
        }


        List<MeterRegistration__c> meterRegs = [
                SELECT Meter__c
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
                AND Meter__c IN (
                        SELECT Meter__c
                        FROM Site_Role__c
                        WHERE Contact__c IN :activeContactIds
                        AND Role__c INCLUDES ('Customer Portal')
                        AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
                )
        ];
        for (MeterRegistration__c regItem : meterRegs) {
            meterIds.add(regItem.Meter__c);
        }

        List<Site_Role__c> subSiteRoles = [
                SELECT Contact__c
                FROM Site_Role__c
                WHERE Meter__c IN :meterIds
                AND Role__c INCLUDES ('Customer Portal')
                AND Contact__c IN:activeContactIds
                AND (End_Date__c >= :Date.today() OR End_Date__c = NULL)
        ];
        for (Site_Role__c tempSiteRole : subSiteRoles) {
            List<Site_Role__c> siteRolesOfContact = siteRoleMap.get(tempSiteRole.Contact__c);
            if (siteRolesOfContact == null) {
                siteRolesOfContact = new List<Site_Role__c>();
            }

            siteRolesOfContact.add(tempSiteRole);
            siteRoleMap.put(tempSiteRole.Contact__c, siteRolesOfContact);
        }

        for (User tempUser : activeUsers) {
            if ((contractRoleMap.get(tempUser.ContactId) == null && siteRoleMap.get(tempUser.ContactId) == null) || (tempUser.LastLoginDate != null && tempUser.LastLoginDate.addDays(lastLoginDuration) < today)) {
                contactIdsToDeactivate.add(tempUser.ContactId);
            }
        }
        Map<Id, Contact> contactRequests = new Map<Id, Contact>([
                SELECT Id, FirstName, LastName, Name, msPortalRequestBy__c, AccountId, Account.Name, msAwaitingPortalActivation__c, Email, msHideFromUserManagement__c
                FROM Contact
                WHERE Id IN:contactIdsToDeactivate
        ]);
        for (User tempUser : activeUsers) {
            if ((contractRoleMap.get(tempUser.ContactId) == null && siteRoleMap.get(tempUser.ContactId) == null) || (tempUser.LastLoginDate != null && tempUser.LastLoginDate.addDays(lastLoginDuration) < today)) {
                UserWrapper tempWrapper = new UserWrapper();
                tempWrapper.user = tempUser;
                if (tempUser.LastLoginDate == null) {
                    tempWrapper.sortDate = null;
                } else {
                    tempWrapper.sortDate = tempUser.LastLoginDate.date();
                }

                tempWrapper.contact = contactRequests.get(tempUser.ContactId);

                if (tempWrapper.contact.msHideFromUserManagement__c == true) {
                    tempWrapper.hideFromUserManagement = true;
                }
                if (contractRoleMap.get(tempUser.ContactId) != null) {
                    tempWrapper.contractRoles = contractRoleMap.get(tempUser.ContactId);
                }
                if (siteRoleMap.get(tempUser.ContactId) != null) {
                    tempWrapper.siteRoles = siteRoleMap.get(tempUser.ContactId);
                }
                tempWrapper.isContractualContact = isContractualContactMap.get(tempUser.ContactId);
                retireWrappers.add(tempWrapper);
            }
        }

        retireWrappers.sort();
        return retireWrappers;
    }


    @AuraEnabled
    public static ApprovalWrapper approveRequest(List<Id> ids, String market) {
        List<Contract_Role__c> requestedContractRoles = [SELECT Id, Contact__c, Contract__c, Start_Date__c, End_Date__c FROM Contract_Role__c WHERE Id IN:ids];
        List<Site_Role__c> requestedSiteRoles = [SELECT Id, Contact__c, Meter__c, Start_Date__c, End_Date__c FROM Site_Role__c WHERE Id IN:ids];
        List<Id> contactIds = new List<Id>();
        List<Id> contractIds = new List<Id>();
        List<Id> meterIds = new List<Id>();
        List<Contract_Role__c> contractRolesToUpdate = new List<Contract_Role__c>();
        List<Contract_Role__c> contractRolesToDelete = new List<Contract_Role__c>();
        List<Site_Role__c> siteRolesToUpdate = new List<Site_Role__c>();
        List<Site_Role__c> siteRolesToDelete = new List<Site_Role__c>();
        Map<String, Contract_Role__c> contractRoleMap = new Map<String, Contract_Role__c>();
        Map<String, Site_Role__c> siteRoleMap = new Map<String, Site_Role__c>();
        for (Contract_Role__c tmpRole : requestedContractRoles) {
            contactIds.add(tmpRole.Contact__c);
            contractIds.add(tmpRole.Contract__c);
        }
        for (Site_Role__c tmpRole : requestedSiteRoles) {
            contactIds.add(tmpRole.Contact__c);
            meterIds.add(tmpRole.Meter__c);
        }

        List<Contract_Role__c> oldContractRoles = [
                SELECT Id, Contact__c, Contract__c
                FROM Contract_Role__c
                WHERE Contact__c IN:contactIds
                AND Contract__c IN:contractIds
                AND Role__c = 'Customer Portal'
                AND msAwaitingPortalActivation__c = FALSE
        ];
        List<Site_Role__c> oldSiteRoles = [
                SELECT Id, Contact__c, Meter__c
                FROM Site_Role__c
                WHERE Contact__c IN:contactIds
                AND Meter__c IN:meterIds
                AND Role__c = 'Customer Portal'
                AND msAwaitingPortalActivation__c = FALSE
        ];
        for (Contract_Role__c tmpRole : oldContractRoles) {
            contractRoleMap.put('' + tmpRole.Contact__c + tmpRole.Contract__c, tmpRole);
        }
        for (Site_Role__c tmpRole : oldSiteRoles) {
            siteRoleMap.put('' + tmpRole.Contact__c + tmpRole.Meter__c, tmpRole);
        }
        for (Contract_Role__c tmpRole : requestedContractRoles) {
            Contract_Role__c oldCounterPart = contractRoleMap.get('' + tmpRole.Contact__c + tmpRole.Contract__c);
            if (oldCounterPart != null && contractRolesToUpdate.contains(oldCounterPart) == false) {
                oldCounterPart.Start_Date__c = tmpRole.Start_Date__c;
                oldCounterPart.End_Date__c = tmpRole.End_Date__c;
                contractRolesToUpdate.add(oldCounterPart);
                contractRolesToDelete.add(tmpRole);
            } else if (oldCounterPart == null) {
                tmpRole.msAwaitingPortalActivation__c = false;
                contractRolesToUpdate.add(tmpRole);
            }
        }
        for (Site_Role__c tmpRole : requestedSiteRoles) {
            Site_Role__c oldCounterPart = siteRoleMap.get('' + tmpRole.Contact__c + tmpRole.Meter__c);
            if (oldCounterPart != null && siteRolesToUpdate.contains(oldCounterPart) == false) {
                oldCounterPart.Start_Date__c = tmpRole.Start_Date__c;
                oldCounterPart.End_Date__c = tmpRole.End_Date__c;
                siteRolesToUpdate.add(oldCounterPart);
                siteRolesToDelete.add(tmpRole);
            } else if (oldCounterPart == null) {
                tmpRole.msAwaitingPortalActivation__c = false;
                siteRolesToUpdate.add(tmpRole);
            }
        }
        update contractRolesToUpdate;
        update siteRolesToUpdate;
        delete contractRolesToDelete;
        delete siteRolesToDelete;

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper approveUserRequest(Id id, String username, String market) {
        try {

            Contact newContact = [
                    SELECT Id, Name, FirstName, LastName, Email, MailingCountry, msAwaitingPortalActivation__c, msPortalRequestBy__c
                    FROM Contact
                    WHERE Id = :id
            ];

            List<String> contactIds = new List<String>();
            contactIds.add(id);
            Profile profile = [SELECT Id FROM Profile WHERE Profile.Name = 'Global Customer Community User' LIMIT 1];

            User newUser = msCreateCommunityUser.generateUser(newContact, profile, username + Label.msPortalUsernameSufix);

            if (newContact.msAwaitingPortalActivation__c == true && newContact.msPortalRequestBy__c == null) {
                Contract_Role__c conRole = [
                        SELECT Id, Start_Date__c
                        FROM Contract_Role__c
                        WHERE Contact__c = :id
                        AND Role__c INCLUDES ('Contractual Contact')
                        ORDER BY Start_Date__c
                        LIMIT 1
                ];

                newUser.Activate_User_at__c = conRole.Start_Date__c;
                newUser.IsActive = false;
            }

            insert newUser;

            newContact.msAwaitingPortalActivation__c = false;
            update newContact;
        } catch (DmlException e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getDmlMessage(0));
        }

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper declineRequest(List<Id> ids, String market) {
        try {
            List<Contract_Role__c>contractRoles = new List<Contract_Role__c>();
            List<Site_Role__c>siteRoles = new List<Site_Role__c>();

            for (Id id : ids) {
                String objectType = '' + id.getSobjectType();
                if (objectType == 'Contract_Role__c') {
                    Contract_Role__c tempRole = new Contract_Role__c();
                    tempRole.Id = id;
                    contractRoles.add(tempRole);

                } else if (objectType == 'Site_Role__c') {
                    Site_Role__c tempRole = new Site_Role__c();
                    tempRole.Id = id;
                    siteRoles.add(tempRole);
                }
            }

            delete contractRoles;
            delete siteRoles;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper declineUserRequest(Id id, String market) {
        try {
            Contact contactToDelete = [SELECT Id, CreatedById, msPortalRequestBy__c, msAwaitingPortalActivation__c FROM Contact WHERE Id = :id];

            List<Site_Role__c> siteRolesToDelete = [SELECT Id FROM Site_Role__c WHERE Contact__c = :id AND msAwaitingPortalActivation__c = TRUE];
            List<Contract_Role__c> contractRolesToDelete = [SELECT Id FROM Contract_Role__c WHERE Contact__c = :id AND msAwaitingPortalActivation__c = TRUE];

            if (siteRolesToDelete.size() > 0) {
                delete siteRolesToDelete;
            }

            if (contractRolesToDelete.size() > 0) {
                delete contractRolesToDelete;
            }

            if (contactToDelete.CreatedById == contactToDelete.msPortalRequestBy__c) {
                delete contactToDelete;
            } else {
                contactToDelete.msAwaitingPortalActivation__c = false;
                contactToDelete.msPortalRequestBy__c = null;
                update contactToDelete;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper hideUserRequest(Id id, String market) {
        try {
            Contact contactToHide = [SELECT Id, msHideFromUserManagement__c FROM Contact WHERE Id = :id];
            contactToHide.msHideFromUserManagement__c = !contactToHide.msHideFromUserManagement__c;
            update contactToHide;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper deactivateUsers(String userIds, String market) {
        List<User> users = new List<User>();
        for (String userId : (List<String>) System.JSON.deserializeStrict(userIds, List<String>.class)) {
            User tempUser = new User();
            tempUser.Id = userId;
            tempUser.IsActive = false;
            users.add(tempUser);
        }
        update users;

        return getApprovalRequests(market);
    }

    @AuraEnabled
    public static ApprovalWrapper reassignContactToRoles(String oldContactId, String newContactId, String market) {
        List<Contract_Role__c> contractRoles = [SELECT Id FROM Contract_Role__c WHERE Contact__c = :oldContactId];
        List<Site_Role__c> siteRoles = [SELECT Id FROM Site_Role__c WHERE Contact__c = :oldContactId];
        Contact newContact = [
                SELECT Id, msAwaitingPortalActivation__c, msPortalRequestBy__c, (SELECT Id, ContactId FROM Users)
                FROM Contact
                WHERE Id = :newContactId
        ];
        Contact oldContact = [
                SELECT Id, msAwaitingPortalActivation__c, msPortalRequestBy__c, (SELECT Id, ContactId FROM Users)
                FROM Contact
                WHERE Id = :oldContactId
        ];

        for (Contract_Role__c tempContractRole : contractRoles) {
            tempContractRole.Contact__c = newContactId;
        }
        for (Site_Role__c tempSiteRole : siteRoles) {
            tempSiteRole.Contact__c = newContactId;
        }

        if (newContact.Users == null) {
            newContact.msAwaitingPortalActivation__c = true;
            newContact.msPortalRequestBy__c = oldContact.msPortalRequestBy__c;
            update newContact;
        }

        update contractRoles;
        update siteRoles;
        delete oldContact;

        return getApprovalRequests(market);
    }

    public class UserWrapper implements Comparable {
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public Account account { get; set; }
        @AuraEnabled public User user { get; set; }
        @AuraEnabled public List<Contract_Role__c> contractRoles { get; set; }
        @AuraEnabled public List<Site_Role__c> siteRoles { get; set; }
        @AuraEnabled public Set<SObject> duplicates { get; set; }
        @AuraEnabled public Boolean hideFromUserManagement { get; set; }
        @AuraEnabled public Boolean isContractualContact { get; set; }
        @AuraEnabled public Date sortDate { get; set; }

        public UserWrapper() {
            contractRoles = new List<Contract_Role__c>();
            siteRoles = new List<Site_Role__c>();
            hideFromUserManagement = false;
            isContractualContact = false;
        }

        public Integer compareTo(Object other) {
            Integer comparisonResult;
            if (this.sortDate == null && ((UserWrapper) other).sortDate == null) {
                comparisonResult = 0;
            } else if (this.sortDate == null) {
                comparisonResult = -1;
            } else if (((UserWrapper) other).sortDate == null) {
                comparisonResult = 1;
            } else {
                comparisonResult = ((UserWrapper) other).sortDate.daysBetween(this.sortDate);
            }
            return comparisonResult;
        }

    }
    public class ApprovalWrapper {
        @AuraEnabled public List<UserWrapper> userWrappers { get; set; }
        @AuraEnabled public List<UserWrapper> usersToRetire { get; set; }
        @AuraEnabled public UserLicense license { get; set; }
        @AuraEnabled public String userDefaultMarket { get; set; }
    }
}