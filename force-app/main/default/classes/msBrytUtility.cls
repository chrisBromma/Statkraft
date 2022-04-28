/****************************************************************************************************
* Class msBrytUtility
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   29.11.2018
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   29.11.2018      	    Init version.
*****************************************************************************************************/

public without sharing class msBrytUtility {

    private static Bryt_Portal_Settings__mdt metaDataSettings;
    public static String environment;
    public static Id BRYT_CONTRACT_RECORD_TYPE_ID = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId();
    public static Id BRYT_CONTRACT_ROLE_RECORD_TYPE_ID = Schema.SObjectType.Contract_Role__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract_Role').getRecordTypeId();
    public static final Id BRYT_ACCOUNT_REC_TYPE_ID =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('msBrytAccount').getRecordTypeId();
    public static String BRYT_PROFILE_NAME = 'Bryt Customer Community User';
    public static Map<String, Account> instance;

    public static Map<String, Account> getInstance() {
        if (instance == null) {
            instance = new Map<String, Account>();
            for (Account acc : [SELECT Id, Name FROM Account WHERE RecordTypeId = :BRYT_ACCOUNT_REC_TYPE_ID]) {
                if (!instance.containsKey(acc.Name.toUpperCase())) {
                    instance.put(acc.Name.toUpperCase(), acc);
                }
            }
        }
        return instance;
    }

    @AuraEnabled
    public static UserDetails getUserDetails() {
        UserDetails result;
        try {
            result = (UserDetails) Cache.Session.get('local.PortalCache.userDetails');
        } catch (Cache.Session.SessionCacheException e) {
            System.debug(e.getMessage());
        }

        if (result == null || result.user.Id != UserInfo.getUserId() || result.user.LanguageLocaleKey != UserInfo.getLanguage()) {
            System.debug('Load User Details');
            result = new UserDetails();
            Id userId = UserInfo.getUserId();
            User user = [
                    SELECT Name, FirstName, Profile.Name, ContactId,Email,Contact.Bryt_isUser_Admin__c, LanguageLocaleKey, Account.Name
                    FROM User
                    WHERE Id = :userId
                    LIMIT 1
            ];
            result.user = user;

            List<Contact> contacts = [
                    SELECT Name, FirstName, LastName, Salutation, Account.Name, Bryt_isUser_Admin__c
                    FROM Contact
                    WHERE Id = :user.ContactId
            ];
            if (contacts.size() > 0) {
                Contact contact = contacts[0];
                result.contact = contact;

                List<Contract_Role__c> contractRoles = [
                        SELECT Id, Contact__c, Contract__c,Contract__r.Name, Account__r.Name, Role__c, Bryt_isTradingEnabled__c, Bryt_isUserAdmin__c, Bryt_isTPI__c, Start_Date__c, End_Date__c
                        FROM Contract_Role__c
                        WHERE Contact__c IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
                        AND RecordType.DeveloperName = 'Bryt_Contract_Role'
                        AND Start_Date__c <= :Date.today()
                        AND (End_Date__c >= :Date.today()
                        OR End_Date__c = NULL)
                        AND Contract__r.POD_ID__c != NULL
                ];

                List<Id> contractIds = new List<Id>();
                Boolean isTPI = false;
                for (Contract_Role__c tmp : contractRoles) {
                    contractIds.add(tmp.Contract__c);
                    if (tmp.Bryt_isTPI__c) {
                        isTPI = true;
                    }
                }
                result.contractRoles = contractRoles;
                result.isTPI = isTPI;
                result.isAdmin = contact.Bryt_isUser_Admin__c;

                Map<Id, Contract__c> contracts = new Map<Id, Contract__c>([
                        SELECT Id, Name, Approved__c, Broker__c, Bryt_Allow_Sellback__c, Bryt_Ask_Premium__c, Bryt_Basket_Contract__c,
                                Bryt_Bid_Premium__c, Bryt_Cost_per_Trade__c, Bryt_Contract_ID__c, Bryt_Default_Days__c,
                                Bryt_Default_Index__c, Bryt_Fixed_Perce_Clip__c, Bryt_Min_Clip_Size__c, Bryt_Product_Name__c,
                                Bryt_Tradable_Months__c, Bryt_Tradable_Quarters__c, Bryt_Tradable_Seasons__c, Bryt_Tradable_Years__c,
                                Contract_Date__c, Contract_Holder__c, Contract_Legal_Status__c, Contract_Type__c,
                                Contracted_Capacity__c, Contracted_Energy__c, Contractual_P50__c, Country__c, End_Date_Confirmed__c,
                                End_Date__c, Inflation_Index__c, Start_Date__c, Contract_Holder__r.Name
                        FROM Contract__c
                        WHERE Id IN :contractIds
                ]);
                result.contracts = contracts.values();


                if (result.isAdmin || result.isTPI) {
                    result.administeredContracts = getContractsWrappers(result);

                    Set<Contract__c> tpiContracts = new Set<Contract__c>();
                    for (ContractWrapper tmpContractWrapper : result.administeredContracts) {
                        tpiContracts.add(tmpContractWrapper.contract);
                        contracts.put(tmpContractWrapper.contract.Id, tmpContractWrapper.contract);
                    }
                    result.contracts = contracts.values();
                    result.tpiContracts = new List<Contract__c>(tpiContracts);
                    result.portalUserWrappers = getPortalUserWrappers(result);

                }

                Map<Id, AccountWrapper> accountWrapperMap = new Map<Id, AccountWrapper>();
                for (Contract__c tempContract : contracts.values()) {
                    AccountWrapper accountWrapper = accountWrapperMap.get(tempContract.Contract_Holder__c);
                    if (accountWrapper == null)accountWrapper = new AccountWrapper(tempContract.Contract_Holder__r);

                    accountWrapper.contracts.add(tempContract);
                    accountWrapperMap.put(tempContract.Contract_Holder__c, accountWrapper);
                }
                result.accounts = accountWrapperMap.values();

                result.pricefixSeconds = (Integer) msBrytUtility.getMetadata().Trading_Pricefix_Seconds__c;

                try {
                    Cache.Session.put('local.PortalCache.userDetails', result, 600);
                } catch (Cache.Session.SessionCacheException e) {
                    System.debug(e.getMessage());
                }
            }
        }
        return result;
    }

    public static List<ContractWrapper> getContractsWrappers(UserDetails userDetails) {
        List<ContractWrapper> result = new List<ContractWrapper>();
        List<Contract__c> contracts = new List<Contract__c>();
        Map<Id, List<Contract_Role__c>> contractIdToRolesMap = new Map<Id, List<Contract_Role__c>>();

        List<Contract_Role__c> administeredRoles;
        if (userDetails.isAdmin) {
            contracts = [
                    SELECT Id, Name, Contract_Holder__r.Name, Start_Date__c, End_Date__c, msExpiry_Days__c,
                            Bryt_Tradable_Months__c, Bryt_Tradable_Quarters__c, Bryt_Tradable_Seasons__c,
                            Bryt_Tradable_Years__c, (
                            SELECT Id,Month__c,Capacity_Peak__c,Capacity_Off_Peak__c,Traded_Peak__c,Traded_Off_Peak__c, Remaining_Capacity__c
                            FROM Reference_Capacities__r
                            ORDER BY Month__c
                    )
                    FROM Contract__c
                    WHERE RecordTypeId = :BRYT_CONTRACT_RECORD_TYPE_ID
                    AND POD_ID__c != NULL
                    ORDER BY Name
            ];
        } else if (userDetails.isTPI) {
            List<Contract_Role__c> myRoles = [
                    SELECT Id, Contract__c
                    FROM Contract_Role__c
                    WHERE RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
                    AND Contact__c = :userDetails.contact.Id
                    AND Contract__r.POD_ID__c != NULL
                    AND Bryt_isTPI__c = TRUE
            ];
            List<Id>contractIds = new List<Id>();
            for (Contract_Role__c tempRole : myRoles) {
                contractIds.add(tempRole.Contract__c);
            }

            contracts = [
                    SELECT Id, Name, Contract_Holder__r.Name, Start_Date__c, End_Date__c, msExpiry_Days__c,
                            Bryt_Tradable_Months__c, Bryt_Tradable_Quarters__c, Bryt_Tradable_Seasons__c,
                            Bryt_Tradable_Years__c, (
                            SELECT Id,Month__c,Capacity_Peak__c,Capacity_Off_Peak__c,Traded_Peak__c,Traded_Off_Peak__c, Remaining_Capacity__c
                            FROM Reference_Capacities__r
                            ORDER BY Month__c
                    )
                    FROM Contract__c
                    WHERE RecordTypeId = :BRYT_CONTRACT_RECORD_TYPE_ID
                    AND Id IN:contractIds
                    ORDER BY Name
            ];
        }


        administeredRoles = [
                SELECT Id, Name, Contact__r.Name,Contract__r.Name, Bryt_isTradingEnabled__c, Bryt_isTPI__c, Start_Date__c, End_Date__c,Contact__c, Contract__c
                FROM Contract_Role__c
                WHERE RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
                AND Contract__c IN:contracts
                AND Contract__r.POD_ID__c != null
        ];
        for (Contract_Role__c roleItem : administeredRoles) {
            if (!contractIdToRolesMap.containsKey(roleItem.Contract__c)) {
                contractIdToRolesMap.put(roleItem.Contract__c, new List<Contract_Role__c>());
            }
            contractIdToRolesMap.get(roleItem.Contract__c).add(roleItem);
        }

        for (Contract__c contr : contracts) {
            ContractWrapper contractWrapper = new ContractWrapper();
            contractWrapper.contract = contr;
            contractWrapper.referenceCapacities = contr.Reference_Capacities__r;
            contractWrapper.relatedRoles = contractIdToRolesMap.get(contr.Id);
            contractWrapper.showContractRoles = false;
            result.add(contractWrapper);
        }

        return result;
    }

    public static Bryt_Portal_Settings__mdt getMetadata() {
        if (metaDataSettings == null) {
            String metaDataName = getEnvironment();

            Map<String, Schema.SObjectField> fieldMap = Bryt_Portal_Settings__mdt.SObjectType.getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());

            Bryt_Portal_Settings__mdt apiSettings = (Bryt_Portal_Settings__mdt) Database.query('SELECT ' + String.join(fieldNames, ',') + ' FROM Bryt_Portal_Settings__mdt WHERE DeveloperName =\'' + metaDataName + '\'');
            metaDataSettings = apiSettings;
        }
        return metaDataSettings;
    }

    public static String getEnvironment() {
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String metaDataName = 'Production';
        if (runningInASandbox) {
            metaDataName = 'PreProd';
        }

        if (msBrytUtility.environment != null) {
            metaDataName = msBrytUtility.environment;
        }

        return metaDataName;
    }

    public static List<PortalUserWrapper> getPortalUserWrappers(msBrytUtility.UserDetails userDetails) {
        Map<Id, User> brytPortalUsersMap = new Map<Id, User>();
        List<PortalUserWrapper> result = new List<PortalUserWrapper>();
        List<Id> contactId = new List<Id>();
        List<Id> allPortalUserIds = new List<Id>();

        if (userDetails.isAdmin) {
            brytPortalUsersMap.putAll(new Map<Id, User>([
                    SELECT Id, Name,LastName,FirstName, Username, LastLoginDate, Contact.Bryt_isUser_Admin__c,Contact.AccountId, IsActive, Email
                    FROM User
                    WHERE Profile.Name = :BRYT_PROFILE_NAME
                    AND IsActive = TRUE
                    ORDER BY LastName
            ]));
            for (User user : brytPortalUsersMap.values()) {
                contactId.add(user.ContactId);
                allPortalUserIds.add(user.Id);
            }
        } else if (userDetails.isTPI) {
            for (msBrytUtility.ContractWrapper tempWrapper : userDetails.administeredContracts) {
                for (Contract_Role__c tempRole : tempWrapper.relatedRoles) {
                    contactId.add(tempRole.Contact__c);
                }
            }
            brytPortalUsersMap.putAll(new Map<Id, User>([
                    SELECT Id, Name,LastName,FirstName, Username, LastLoginDate, Contact.Bryt_isUser_Admin__c,Contact.AccountId, IsActive, Email
                    FROM User
                    WHERE Profile.Name = :BRYT_PROFILE_NAME
                    AND ContactId IN:contactId
                    AND IsActive = TRUE
                    ORDER BY LastName
            ]));
            for (User user : brytPortalUsersMap.values()) {
                allPortalUserIds.add(user.Id);
            }
        }

        List<Contract_Role__c> contractRoles = new List<Contract_Role__c>();
        if (userDetails.isAdmin) {
            contractRoles.addAll([
                    SELECT Id, Name, Contact__r.Name,Contract__r.Name, Bryt_isTradingEnabled__c, Bryt_isTPI__c, Start_Date__c, End_Date__c,Contact__c
                    FROM Contract_Role__c
                    WHERE Contact__c IN :contactId
                    AND RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
            ]);
        } else if (userDetails.isTPI) {
            contractRoles.addAll([
                    SELECT Id, Name, Contact__r.Name,Contract__r.Name, Bryt_isTradingEnabled__c, Bryt_isTPI__c, Start_Date__c, End_Date__c,Contact__c
                    FROM Contract_Role__c
                    WHERE Contract__c IN :userDetails.tpiContracts
                    AND RecordTypeId = :BRYT_CONTRACT_ROLE_RECORD_TYPE_ID
            ]);
        }

        // Get user-frozen-status for all given users (UserLogin.isFrozen TRUE/FALSE)
        List<UserLogin> userFrozenStatus = [
                SELECT IsFrozen, UserId
                FROM UserLogin
                WHERE UserId IN :allPortalUserIds
        ];

        for (User user : brytPortalUsersMap.values()) {
            PortalUserWrapper userWrapper = new PortalUserWrapper();
            userWrapper.user = user;

            // Set freeze-status for each user.
            for (UserLogin currentUserLogin : userFrozenStatus) {
                if (currentUserLogin.UserId == userWrapper.user.Id) {
                    userWrapper.userIsFrozen = currentUserLogin.IsFrozen;
                }
            }

            for (Contract_Role__c contract_role : contractRoles) {
                if (contract_role.Contact__c.equals(user.ContactId)) {
                    userWrapper.contractRoles.add(contract_role);
                }
            }
            result.add(userWrapper);
        }

        return result;
    }

    public static Boolean checkObjectAccess(Id recordId) {
        System.debug(recordId);
        UserDetails userDetails = getUserDetails();
        String objectType = recordId.getSobjectType().getDescribe().getName();
        System.debug(objectType);
        switch on objectType {
            when 'Contract__c' {
                for (Contract__c tempContract : userDetails.contracts) {
                    if (tempContract.Id == recordId) {
                        return true;
                    }
                }
            }
            when 'User' {
                Set<Id> legalIdList = new Set<Id>();
                for (PortalUserWrapper wrapperItem : userDetails.portalUserWrappers) {
                    legalIdList.add(wrapperItem.user.Id);
                }
                if (legalIdList.contains(recordId)) {
                    return true;
                }
            }
        }

        throw new AuraHandledException('User not allowed to access ' + objectType + ': ' + recordId);
    }

    public static Integer getHoursInMonth(Date startDate) {
        Integer year = startDate.year();
        Integer month = startDate.month();

        return Date.daysInMonth(year, month) * 24;
    }


    /*
    *    This method reads a CSV file from "ContentVersion".
    *    Pass ContentDocumentId to this function. You will get List of Map's.
    *
    *    Example:
    *        List<Map<String, String>> myCSV =  msBrytUtility.getCsvFromContentVersionGivenContentDocumentId('0694E000000fCdvQAE');
    *        system.debug('result: ' + myCSV);
    */
    public static List<Map<String, Object>> getCsvFromContentVersionGivenContentDocumentId(Id ContentDocumentId) {
        try {

            ContentVersion cv = [
                    SELECT Id, ContentDocumentId, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :ContentDocumentId
            ];

            Blob csvBlob = cv.VersionData; // Binary data from Contentversion

            //List<String> csvRows = csvBlob.toString().split('[\\n\\r]'); // Use this split instead of a single '\n' !
            List<String> csvRows = csvBlob.toString().split('\n');

            String separatorSemicolon = ';';
            String separatorComma = ',';
            String separator = ';'; // Default separator for CSV header

            String csvHeaderSemicolon = csvRows[0].trim();
            String separatorSemicolonRegex = '.*[' + separatorSemicolon + '].*';
            Pattern csvPatternSemicolon = Pattern.compile(separatorSemicolonRegex);
            Matcher csvHeaderMatcherSemicolon = csvPatternSemicolon.matcher(csvHeaderSemicolon); // Check header ;

            String csvHeaderComma = csvRows[0].trim();
            String separatorCommaRegex = '.*[' + separatorComma + '].*';
            Pattern csvPatternComma = Pattern.compile(separatorCommaRegex);
            Matcher csvHeaderMatcherComma = csvPatternComma.matcher(csvHeaderComma); // Check header for ,

            if (csvHeaderMatcherSemicolon.matches()) {
                separator = ';';
            }
            if (csvHeaderMatcherComma.matches()) {
                separator = ',';
            }

            List<String> columnFields = csvRows[0].split(separator); // All column (or header fields of the CSV)

            // Clean CSV-header-field-names: Replace \n and \r from header
            List<String> columnFieldsCleaned = new List<String>();

            for (Integer cf = 0; cf < columnFields.size(); cf++) {
                String currentHeaderNameWithoutNR = columnFields[cf].replace('\r\n', '');
                currentHeaderNameWithoutNR = columnFields[cf].replace('\n', '');
                currentHeaderNameWithoutNR = columnFields[cf].replace('\r', '');
                columnFieldsCleaned.add(currentHeaderNameWithoutNR);
            }

            // This List of Map´s will contain all CSV rows(or values)
            List<Map<String, Object>> csvDataListOfMaps = new List<Map<String, Object>>();

            for (Integer i = 1; i < csvRows.size(); i++) { // Rows
                List<String> columnField = csvRows[i].split(separator);
                Map<String, Object> csvColumnRowValues = new Map<String, Object>();

                for (Integer j = 0; j < columnField.size(); j++) { // Columns

                    String dataType = getDataTypeFromString(columnField[j]);

                    if (dataType == 'Date') {

                        // Date can be in formatted with / or .
                        Boolean checkForSlashes = columnField[j].trim().contains('/');
                        Boolean checkForDots = columnField[j].trim().contains('.');
                        String defaultDateFormatCharacter = '.';

                        if (checkForSlashes) {
                            defaultDateFormatCharacter = '/';
                        }
                        if (checkForDots) {
                            defaultDateFormatCharacter = '\\.';
                        }

                        // Split date from CSV (e.g.: 20/09/2021 or 20.09.2021) into 3 chunks:
                        String[] csvDateSplitted = columnField[j].trim().split(defaultDateFormatCharacter);

                        Integer csvDateDay = Integer.valueof(csvDateSplitted[0]);
                        Integer csvDateMonth = Integer.valueof(csvDateSplitted[1]);
                        Integer csvDateYear = Integer.valueof(csvDateSplitted[2]);

                        Date csvDate = Date.newInstance(csvDateYear, csvDateMonth, csvDateDay);
                        csvColumnRowValues.put(columnFieldsCleaned[j], csvDate);
                    }
                    if (dataType == 'String') {
                        csvColumnRowValues.put(columnFieldsCleaned[j], columnField[j]);
                    }
                    if (dataType == 'Integer') {
                        Integer csvInteger = Integer.valueOf(columnField[j]);
                        csvColumnRowValues.put(columnFieldsCleaned[j], csvInteger);
                    }
                    if (dataType == 'Boolean') {
                        Boolean csvBoolean = Boolean.valueOf(columnField[j]);
                        csvColumnRowValues.put(columnFieldsCleaned[j], csvBoolean);
                    }
                    if (dataType == 'Decimal') {
                        Decimal csvDecimal = Decimal.valueOf(columnField[j]);
                        csvColumnRowValues.put(columnFieldsCleaned[j], csvDecimal);
                    }
                }

                csvDataListOfMaps.add(csvColumnRowValues);
            }

            return csvDataListOfMaps;
        } catch (Exception e) {
            //System.debug(' ERROR: ' + e);// Contract not found?
            return null;
        }
    }

    /* Determines the data type of given parameter.
    *
    *  Example: String dataTypeCheck = msBrytUtility.getDataTypeFromString('30/09/2021');
    *           Will return: 'Date'
    * */
    public static String getDataTypeFromString(String checkDataType) {
        Pattern checkString = Pattern.compile('.*');
        Pattern checkInteger = Pattern.compile('^\\d+$');
        Pattern checkDate = Pattern.compile('^(?:(?:31(\\/|-|\\.)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/|-|\\.)(?:0?[13-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/|-|\\.)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/|-|\\.)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$');
        Pattern checkBoolean = Pattern.compile('(?i)true|(?i)false');
        Pattern checkDecimal = Pattern.compile('^[0-9]+([\\.\\,][0-9]{1,6})?$'); // MAX decimal places = 6 !

        String retrievedDataType = null;
        if (checkString.matcher(checkDataType).matches()) {
            retrievedDataType = 'String';
        } // 1st! Check for any Strings
        if (checkDecimal.matcher(checkDataType).matches()) {
            retrievedDataType = 'Decimal';
        } // 2nd! Check for any Decimals
        if (checkInteger.matcher(checkDataType).matches()) {
            retrievedDataType = 'Integer';
        }
        if (checkDate.matcher(checkDataType.trim()).matches()) {
            retrievedDataType = 'Date';
        }
        if (checkBoolean.matcher(checkDataType).matches()) {
            retrievedDataType = 'Boolean';
        }
        if (retrievedDataType == null) {
            retrievedDataType = 'NULL';
        }
        return retrievedDataType;
    }

    public class UserDetails {
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public User user { get; set; }
        @AuraEnabled public List<Contract_Role__c> contractRoles { get; set; }
        @AuraEnabled public List<Contract__c> contracts { get; set; }
        @AuraEnabled public List<Contract__c> tpiContracts { get; set; }
        @AuraEnabled public List<AccountWrapper> accounts { get; set; }
        @AuraEnabled public Boolean isTPI { get; set; }
        @AuraEnabled public Integer pricefixSeconds { get; set; }
        @AuraEnabled public Boolean isAdmin { get; set; }
        @AuraEnabled public List<ContractWrapper> administeredContracts { get; set; }
        @AuraEnabled public List<PortalUserWrapper> portalUserWrappers { get; set; }
    }
    public class AccountWrapper {
        @AuraEnabled public Account account { get; set; }
        @AuraEnabled public List<Contract__c> contracts { get; set; }

        public AccountWrapper(Account accountInput) {
            account = accountInput;
            contracts = new List<Contract__c>();
        }
    }

    public class ContractWrapper {
        @AuraEnabled public Contract__c contract { get; set; }
        @AuraEnabled public List<Bryt_Reference_Capacity__c> referenceCapacities { get; set; }
        @AuraEnabled public List<Contract_Role__c> relatedRoles { get; set; }
        @AuraEnabled public Boolean showContractRoles { get; set; }
    }

    public class PortalUserWrapper {
        @AuraEnabled public User user { get; set; }
        @AuraEnabled public List<Contract_Role__c> contractRoles { get; set; }
        @AuraEnabled public Boolean showContracts { get; set; } // TRUE/FALSE
        @AuraEnabled public Boolean allContracts { get; set; }
        @AuraEnabled public Boolean showUser { get; set; }
        @AuraEnabled public Boolean userIsFrozen { get; set; }

        public PortalUserWrapper() {
            showContracts = false;
            contractRoles = new List<Contract_Role__c>();
            showUser = true; // Default: Show all users in admin-panel
            userIsFrozen = false;
        }
    }
}