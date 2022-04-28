public without sharing class msBrytFileUploadController {
    private static Id BRYT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('msBrytAccount').getRecordTypeId(); // For Accounts with type "Bryt"
    private static Id BRYT_CONTRACT_RECORD_TYPE_ID = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Bryt_Contract').getRecordTypeId(); // For Contracts with type "Bryt"

    private static final String BRYT_CONTRACT_ID_FIELD_NAME = 'Bryt Contract Id';
    private static final String CSV_SEPARATOR = ',';
    private static final String CSV_NEW_LINE_CHAR = '\n';

    // CSV header field for contract upload
    private static final String CSV_COMPANY = 'Company'; // The Account name
    private static final String CSV_ALLOW_SELL_BACK = 'Allow Sell Back';
    private static final String CSV_ASK_PREMIUM = 'Ask Premium';
    private static final String CSV_BID_PREMIUM = 'Bid Premium';
    private static final String CSV_BRYT_CONTRACT_ID = 'Bryt Contract ID';
    private static final String CSV_CONTRACT_NAME = 'Contract Name';
    private static final String CSV_COST_PER_TRADE = 'Cost Per Trade';
    private static final String CSV_END_DATE = 'End Date';
    private static final String CSV_EXPIRY_DAYS = 'Expiry Days';
    private static final String CSV_FIXED_CLIP_PERCENT = 'Fixed Clip Percent';
    private static final String CSV_START_DATE = 'Start Date';
    private static final String CSV_TRADABLE_MONTHS = 'Tradable Months';
    private static final String CSV_TRADABLE_QUARTERS = 'Tradable Quarters';
    private static final String CSV_TRADABLE_SEASONS = 'Tradable Seasons';
    private static final String CSV_TRADABLE_YEARS = 'Tradable Years';
    private static final String CSV_CONTRACT_RECORDTYPE = 'Contract RecordTypeId';

    // API-names for contract__c
    private static final String API_ALLOW_SELL_BACK = 'Bryt_Allow_Sellback__c';
    private static final String API_ASK_PREMIUM = 'Bryt_Ask_Premium__c';
    private static final String API_BID_PREMIUM = 'Bryt_Bid_Premium__c';
    private static final String API_BRYT_CONTRACT_ID = 'Bryt_Contract_ID__c';
    private static final String API_CONTRACT_NAME = 'Name';
    private static final String API_COST_PER_TRADE = 'Bryt_Cost_per_Trade__c';
    private static final String API_END_DATE = 'End_Date__c';
    private static final String API_EXPIRY_DAYS = 'msExpiry_Days__c';
    private static final String API_FIXED_CLIP_PERCENT = 'Bryt_Fixed_Perce_Clip__c';
    private static final String API_START_DATE = 'Start_Date__c';
    private static final String API_TRADABLE_MONTHS = 'Bryt_Tradable_Months__c';
    private static final String API_TRADABLE_QUARTERS = 'Bryt_Tradable_Quarters__c';
    private static final String API_TRADABLE_SEASONS = 'Bryt_Tradable_Seasons__c';
    private static final String API_TRADABLE_YEARS = 'Bryt_Tradable_Years__c';
    private static final String API_CONTRACT_RECORDTYPE = 'RecordTypeId';

    // CSV header field for Reference Capacities upload
    private static final String CSV_REFCAP_BRYT_CONTRACT_ID = 'Bryt Contract Id';
    private static final String CSV_REFCAP_CAPACITY_BASE = 'Capacity Base';
    private static final String CSV_REFCAP_CAPACITY_PEAK = 'Capacity Peak';
    private static final String CSV_REFCAP_MONTH = 'Month';

    @AuraEnabled
    public static UserFileWrapper getUploads() {
        UserFileWrapper wrapper = new UserFileWrapper();

        User runningUser = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        if (runningUser.ContactId != null) {
            wrapper.recordId = runningUser.Contact.AccountId;
            List<ContentDocumentLink> contentDocumentLinkList = [
                    SELECT Id, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :runningUser.Contact.AccountId
            ];
            if (contentDocumentLinkList.size() > 0) {
                Set<Id> contentDocumentIdSet = new Set<Id>();
                for (ContentDocumentLink cdl : contentDocumentLinkList) {
                    contentDocumentIdSet.add(cdl.ContentDocumentId);
                }

                wrapper.files = [
                        SELECT
                                Id,
                                Owner.Name,
                                Description,
                                Title,
                                PathOnClient,
                                CreatedDate,
                                FileExtension,
                                Bryt_Content_Type__c,
                                ContentDocumentId
                        FROM ContentVersion
                        WHERE IsLatest = TRUE
                        AND ContentDocumentId IN :contentDocumentIdSet
                        AND Bryt_Content_Type__c != NULL
                        ORDER BY CreatedDate DESC
                ];
            }
        }
        wrapper.fileTypes = JSON.serialize(getTypesOfContent());
        return wrapper;

    }

    @AuraEnabled
    public static void updateInsertedFiles(List<String> fileIds, String fileType) { // Used by msBrytFileUploadController.cmp (JS controller)

        List<ContentVersion> contentVersionsToUpdate = new List<ContentVersion>();
        if (!fileIds.isEmpty()) {
            // HINT: You are not allowed to modify "ContentVersion.VersionData", as this is denied by SF.
            for (ContentVersion contentVersion : [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId IN :fileIds]) {

                ContentVersion cV2Update = new ContentVersion();

                if (contentVersion.VersionData != null) {
                    cV2Update.Description= getAffectedContractIds(contentVersion.VersionData); // Get descriotion from CSV-blob
                }

                cV2Update.Id = contentVersion.Id;
                cV2Update.Bryt_Content_Type__c = fileType;
                contentVersionsToUpdate.add(cV2Update);
            }

            // 0.) Update ContentVersion.Bryt_Content_Type__c with the correct upload-type
            // "Contracts" or "Reference Capacities"
            update contentVersionsToUpdate;

            if (!fileIds.isEmpty()) {

                if (fileType == 'Contracts') {
                    upsertContracts(fileIds);             // 1.) Insert/Update Contracts
                }
                if (fileType == 'Reference Capacities') {
                    upsertReferenceCapacities(fileIds);   // 2.) Insert/Update Reference Capacities
                }

            }
            return;
        }
    }

    @TestVisible
    private static String getAffectedContractIds(Blob csvBlob) {
        String contractIdsCsv = '';
        List<String> csvRows = csvBlob.toString().toLowerCase().split(CSV_NEW_LINE_CHAR);
        Integer contractIdFieldIndex = csvRows[0].split(CSV_SEPARATOR).indexOf(BRYT_CONTRACT_ID_FIELD_NAME.toLowerCase());
        if(contractIdFieldIndex > -1 && csvRows.size() > 1) {
            Set<String> brytContractIds = new Set<String>();
            for (Integer i = 1 ; i < csvRows.size() ; i++) {
                if (String.isNotBlank(csvRows[i].split(CSV_SEPARATOR)[contractIdFieldIndex])) {
                    brytContractIds.add(csvRows[i].split(CSV_SEPARATOR)[contractIdFieldIndex]);
                }

            }
            contractIdsCsv = String.join(new List<String>(brytContractIds) , ',');
        }
        return contractIdsCsv;
    }

    private static List<Schema.PicklistEntry> getTypesOfContent() {
        //List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = ContentVersion.Bryt_Content_Type__c.getDescribe();
        return fieldResult.getPicklistValues();
    }

    /*
    * @description At this point, CSV were stored into contentVersion, so read+return it from here.
    * @parameters List<String> fileIds
    * */
    public static void upsertContracts(List<String> fileIds){

        List<Object> csvInsertUpdate = new List<Object>();
        Object updateContractFromCsv = new List<Object>();
        Object insertContractFromCsv = new List<Object>();

        for (Integer f = 0; f < fileIds.size(); f++) { // Iterate over all files

            // Get a list of all CSV files
            List<Map<String, Object>> csvListOfMaps = msBrytUtility.getCsvFromContentVersionGivenContentDocumentId(fileIds[f]);

            // Map the CSV-header to API-header (for later DML statements) (+ Get Contract__c.Id for each row)
            csvInsertUpdate = mapCsvToApiNamesForContract(csvListOfMaps);

            updateContractFromCsv = csvInsertUpdate[0]; // UPDATE Contract
            insertContractFromCsv = csvInsertUpdate[1]; // INSERT Contract

            // Contracts: Prepare data for UPDATE
            String updateContractListString = JSON.serialize(updateContractFromCsv);
            List<Contract__c> updateContractList = (List<Contract__c>) System.JSON.deserializeStrict(updateContractListString, List<Contract__c>.class);
            update updateContractList;

            // Contracts: Prepare data for INSERT
            String insertNewContractListString = JSON.serialize(insertContractFromCsv);
            List<Contract__c> insertNewContractList = (List<Contract__c>) System.JSON.deserializeStrict(insertNewContractListString, List<Contract__c>.class);
            insert insertNewContractList;

        }

        return;
    }

    /*
    * @description At this point, CSV were stored into contentVersion, so read+return it from here.
    * @parameters List<String> fileIds
    * */
    public static void upsertReferenceCapacities(List<String> fileIds) {
        List<Object> csvInsertUpdate = new List<Object>();

        List<Bryt_Reference_Capacity__c> updateRefCapFromCsv = new List<Bryt_Reference_Capacity__c>();
        List<Bryt_Reference_Capacity__c> insertRefCapFromCsv = new List<Bryt_Reference_Capacity__c>();

        for (Integer f = 0; f < fileIds.size(); f++) { // Iterate over all files
            // Get a list of all CSV files
            List<Map<String, Object>> csvListReferenceCapacities = msBrytUtility.getCsvFromContentVersionGivenContentDocumentId(fileIds[f]);

            // Map the CSV-header to API-header (for later DML statements) (+ Get Contract__c.Id for each row)
            csvInsertUpdate = mapCsvToApiNamesForReferenceCapacities(csvListReferenceCapacities);

            updateRefCapFromCsv = (List<Bryt_Reference_Capacity__c>) csvInsertUpdate[0]; // UPDATE Contract
            insertRefCapFromCsv = (List<Bryt_Reference_Capacity__c>) csvInsertUpdate[1]; // INSERT Contract

            // Update updateRefCapFromCsv
            update updateRefCapFromCsv;

            // Insert new insertRefCapFromCsv
            insert insertRefCapFromCsv;
        }

        return;
    }

    /*
    * @description Get a single Id for given "Bryt Contract ID"
    * @parameters String brytContractId
    * */
    public static String getContractIdGivenBrytContractId(String brytContractId) {
        try {
            Id myId = [SELECT Id FROM Contract__c WHERE Bryt_Contract_ID__c = :brytContractId LIMIT 1].Id;
            return myId;
        } catch (Exception e) {
            /* If the Contrac__c.ID was not found for given Bryt_Contract_ID__c, return NULL */
            return null;
        }
    }

    /*
    * @description Get all Contract__c.Id's given a List of brytContractIds
    * @parameters Set<String> brytContractIds
    * */
    public static List<Contract__c> getContractIdsGivenListOfBrytContractIds(Set<String> brytContractIds) {
        List<Contract__c> myIds = [SELECT Id, Bryt_Contract_ID__c FROM Contract__c WHERE Bryt_Contract_ID__c IN :brytContractIds];
        return myIds;
    }

    /*
    * @description Maps CSV-header-names map to API-names + query Contract__c.Id
    * @parameters List<Map<String, Object>> csvListOfMaps
    * */
    public static List<Object> mapCsvToApiNamesForContract(List<Map<String, Object>> csvListOfMaps) {
        // This List will contain all data for INSERT and UPDATE
        List<Object>csvInsertAndUpdateList = new List<Object>();

        // Not all users are allowed to create Accounts. Pixos user has the permission.
        Id pixosUserId = [SELECT Id FROM User WHERE FirstName = 'Pixos' AND LastName = 'Service' LIMIT 1].Id;

        // List for INSERT and list for UPDATE
        List<Map<String, Object>> updateContractFromCsv = new List<Map<String, Object>>(); // Update Contract
        List<Map<String, Object>> insertContractFromCsv = new List<Map<String, Object>>(); // New Contract to be inserted

        for (Integer i = 0; i < csvListOfMaps.size(); i++) { // List

            Map<String, Object> accountAndContractFound = new Map<String, Object>();
            Map<String, Object> accountFoundButNoContract = new Map<String, Object>();

            // Get Id for each row given 'Bryt Contract ID'
            Object currentBrytContractId = csvListOfMaps[i].get(CSV_BRYT_CONTRACT_ID);
            String IdOfCurrentBrytContract = getContractIdGivenBrytContractId(String.valueOf(currentBrytContractId));

            // DIFFERENTIATE between UPDATE and INSERT:
            Object csvCompanyOrAccountName = csvListOfMaps[i].get('Company').toString(); // Get the Account.Name from CSV
            String companyNameOrAccountName = csvCompanyOrAccountName.toString();

            // Check if Account exists in SF (Or CSV Company Name), given Account.Name
            Map<String, Account> accountNameToAccountMap = msBrytUtility.getInstance();
            Account matchedAccount = accountNameToAccountMap.get(companyNameOrAccountName.toUpperCase());

            // UPDATE CONTRACT: Account & Contract found: Update all contract values. Use csvToUpdate
            if (matchedAccount != null && IdOfCurrentBrytContract != null) {
                for (Integer j = 0; j < csvListOfMaps[i].size(); j++) { // Iterate over a row and position i
                    // Map CSV to API names:
                    accountAndContractFound.put('Id', IdOfCurrentBrytContract);
                    accountAndContractFound.put(API_ALLOW_SELL_BACK, csvListOfMaps[i].get(CSV_ALLOW_SELL_BACK));
                    accountAndContractFound.put(API_ASK_PREMIUM, csvListOfMaps[i].get(CSV_ASK_PREMIUM));
                    accountAndContractFound.put(API_BID_PREMIUM, csvListOfMaps[i].get(CSV_BID_PREMIUM));
                    accountAndContractFound.put(API_BRYT_CONTRACT_ID, csvListOfMaps[i].get(CSV_BRYT_CONTRACT_ID));
                    accountAndContractFound.put(API_CONTRACT_NAME, csvListOfMaps[i].get(CSV_CONTRACT_NAME));
                    accountAndContractFound.put(API_COST_PER_TRADE, csvListOfMaps[i].get(CSV_COST_PER_TRADE));
                    accountAndContractFound.put(API_END_DATE, csvListOfMaps[i].get(CSV_END_DATE));
                    accountAndContractFound.put(API_EXPIRY_DAYS, csvListOfMaps[i].get(CSV_EXPIRY_DAYS));
                    accountAndContractFound.put(API_FIXED_CLIP_PERCENT, csvListOfMaps[i].get(CSV_FIXED_CLIP_PERCENT));
                    accountAndContractFound.put(API_START_DATE, csvListOfMaps[i].get(CSV_START_DATE));
                    accountAndContractFound.put(API_TRADABLE_MONTHS, csvListOfMaps[i].get(CSV_TRADABLE_MONTHS));
                    accountAndContractFound.put(API_TRADABLE_QUARTERS, csvListOfMaps[i].get(CSV_TRADABLE_QUARTERS));
                    accountAndContractFound.put(API_TRADABLE_SEASONS, csvListOfMaps[i].get(CSV_TRADABLE_SEASONS));
                    accountAndContractFound.put(API_TRADABLE_YEARS, csvListOfMaps[i].get(CSV_TRADABLE_YEARS));
                    accountAndContractFound.put(API_CONTRACT_RECORDTYPE, csvListOfMaps[i].get(CSV_CONTRACT_RECORDTYPE));
                }
                updateContractFromCsv.add(accountAndContractFound);
            }
            // INSERT CONTRACT: Account found, but no Contract
            else if (matchedAccount != null && IdOfCurrentBrytContract == null) {
                // Get the Account.Id
                Id accountId = matchedAccount.Id;

                // Create(Insert) Contract
                for (Integer j = 0; j < csvListOfMaps[i].size(); j++) { // Iterate over a row and position i
                        // Map CSV to API names:
                        accountFoundButNoContract.put(API_ALLOW_SELL_BACK, csvListOfMaps[i].get(CSV_ALLOW_SELL_BACK));
                        accountFoundButNoContract.put(API_ASK_PREMIUM, csvListOfMaps[i].get(CSV_ASK_PREMIUM));
                        accountFoundButNoContract.put(API_BID_PREMIUM, csvListOfMaps[i].get(CSV_BID_PREMIUM));
                        accountFoundButNoContract.put(API_BRYT_CONTRACT_ID, csvListOfMaps[i].get(CSV_BRYT_CONTRACT_ID));
                        accountFoundButNoContract.put(API_CONTRACT_NAME, csvListOfMaps[i].get(CSV_CONTRACT_NAME));
                        accountFoundButNoContract.put(API_COST_PER_TRADE, csvListOfMaps[i].get(CSV_COST_PER_TRADE));
                        accountFoundButNoContract.put(API_END_DATE, csvListOfMaps[i].get(CSV_END_DATE));
                        accountFoundButNoContract.put(API_EXPIRY_DAYS, csvListOfMaps[i].get(CSV_EXPIRY_DAYS));
                        accountFoundButNoContract.put(API_FIXED_CLIP_PERCENT, csvListOfMaps[i].get(CSV_FIXED_CLIP_PERCENT));
                        accountFoundButNoContract.put(API_START_DATE, csvListOfMaps[i].get(CSV_START_DATE));
                        accountFoundButNoContract.put(API_TRADABLE_MONTHS, csvListOfMaps[i].get(CSV_TRADABLE_MONTHS));
                        accountFoundButNoContract.put(API_TRADABLE_QUARTERS, csvListOfMaps[i].get(CSV_TRADABLE_QUARTERS));
                        accountFoundButNoContract.put(API_TRADABLE_SEASONS, csvListOfMaps[i].get(CSV_TRADABLE_SEASONS));
                        accountFoundButNoContract.put(API_TRADABLE_YEARS, csvListOfMaps[i].get(CSV_TRADABLE_YEARS));
                        accountFoundButNoContract.put(API_CONTRACT_RECORDTYPE, csvListOfMaps[i].get(CSV_CONTRACT_RECORDTYPE));

                        accountFoundButNoContract.put('RecordTypeId', BRYT_CONTRACT_RECORD_TYPE_ID);
                        accountFoundButNoContract.put('OwnerId', pixosUserId);
                        accountFoundButNoContract.put('Contract_Holder__c', accountId); // = Account.Id // 0014E000017V3igQAC
                        accountFoundButNoContract.put('CreatedById', pixosUserId);
                        accountFoundButNoContract.put('Status__c', 'Draft'); // New contracts will get status: "Draft"
                }
                insertContractFromCsv.add(accountFoundButNoContract);
            }
            // INSERT CONTRACT: Account with the given name not found. (CSV: 1st column = Company). Use csvToInsert
            else if (matchedAccount == null) {
                Object accountNameToCreate = csvListOfMaps[i].get(CSV_COMPANY);
                Id createdAccountId = createAccountWithRecordTypeBryt(accountNameToCreate.toString());
                for (Integer j = 0; j < csvListOfMaps[i].size(); j++) { // Iterate over a row and position i
                    // Map CSV to API names:
                    //csvColumnRowValues.put('Id', createdAccountId);
                    accountAndContractFound.put(API_ALLOW_SELL_BACK, csvListOfMaps[i].get(CSV_ALLOW_SELL_BACK));
                    accountAndContractFound.put(API_ASK_PREMIUM, csvListOfMaps[i].get(CSV_ASK_PREMIUM));
                    accountAndContractFound.put(API_BID_PREMIUM, csvListOfMaps[i].get(CSV_BID_PREMIUM));
                    accountAndContractFound.put(API_BRYT_CONTRACT_ID, csvListOfMaps[i].get(CSV_BRYT_CONTRACT_ID));
                    accountAndContractFound.put(API_CONTRACT_NAME, csvListOfMaps[i].get(CSV_CONTRACT_NAME));
                    accountAndContractFound.put(API_COST_PER_TRADE, csvListOfMaps[i].get(CSV_COST_PER_TRADE));
                    accountAndContractFound.put(API_END_DATE, csvListOfMaps[i].get(CSV_END_DATE));
                    accountAndContractFound.put(API_EXPIRY_DAYS, csvListOfMaps[i].get(CSV_EXPIRY_DAYS));
                    accountAndContractFound.put(API_FIXED_CLIP_PERCENT, csvListOfMaps[i].get(CSV_FIXED_CLIP_PERCENT));
                    accountAndContractFound.put(API_START_DATE, csvListOfMaps[i].get(CSV_START_DATE));
                    accountAndContractFound.put(API_TRADABLE_MONTHS, csvListOfMaps[i].get(CSV_TRADABLE_MONTHS));
                    accountAndContractFound.put(API_TRADABLE_QUARTERS, csvListOfMaps[i].get(CSV_TRADABLE_QUARTERS));
                    accountAndContractFound.put(API_TRADABLE_SEASONS, csvListOfMaps[i].get(CSV_TRADABLE_SEASONS));
                    accountAndContractFound.put(API_TRADABLE_YEARS, csvListOfMaps[i].get(CSV_TRADABLE_YEARS));
                    accountAndContractFound.put(API_CONTRACT_RECORDTYPE, csvListOfMaps[i].get(CSV_CONTRACT_RECORDTYPE));

                    accountAndContractFound.put('RecordTypeId', BRYT_CONTRACT_RECORD_TYPE_ID);
                    accountAndContractFound.put('OwnerId', pixosUserId);
                    accountAndContractFound.put('Contract_Holder__c', createdAccountId); // = Account.Id // 0014E000017V3igQAC
                    accountAndContractFound.put('CreatedById', pixosUserId);
                    accountAndContractFound.put('Status__c', 'Draft'); // New contracts will get status: "Draft"

                }
                insertContractFromCsv.add(accountAndContractFound);
            }
        }

        // Connect the two Lists(Insert and Update) to one: csvToUpdate + csvToInsert
        csvInsertAndUpdateList.add(updateContractFromCsv);  // Contract to Update
        csvInsertAndUpdateList.add(insertContractFromCsv);  // Contracts to Insert

        return csvInsertAndUpdateList;
    }

    public static List<Object> mapCsvToApiNamesForReferenceCapacities(List<Map<String, Object>> csvListOfMapsRefCap) {
        // This List will contain all data for the UPDATE DML
        List<Object> csvToUpdateAndInsert = new List<Object>();

        List<Bryt_Reference_Capacity__c>csvUpdateList = new List<Bryt_Reference_Capacity__c>();
        List<Bryt_Reference_Capacity__c>csvInsertList = new List<Bryt_Reference_Capacity__c>();

        Id pixosUserId = [SELECT Id FROM User WHERE FirstName = 'Pixos' AND LastName = 'Service' LIMIT 1].Id;

        // Create a List of all BrytContractId´s from CSV: allBrytContractIds
        Set<String> allDistinctBrytContractIds = new Set<String>(); // Store all Bryt_Contract_ID__c into a Set
        for (Integer i = 0; i < csvListOfMapsRefCap.size(); i++) {
            for (Integer j = 0; j < csvListOfMapsRefCap[i].size(); j++) { // Iterate over a row and position i
                String currentBrytContractId = String.valueOf(csvListOfMapsRefCap[i].get(CSV_REFCAP_BRYT_CONTRACT_ID));

                if (!allDistinctBrytContractIds.contains(currentBrytContractId)) {
                    allDistinctBrytContractIds.add(currentBrytContractId); // Add distinct BrytContractId to a List
                }
            }
        }

        // List with BrytContractID`s AND Id´s
        List<Contract__c> allDistinctBrytContractIdsWithContractIds = new List<Contract__c>();
        allDistinctBrytContractIdsWithContractIds = [
                SELECT Id, Bryt_Contract_ID__c
                FROM Contract__c
                WHERE Bryt_Contract_ID__c IN :allDistinctBrytContractIds
                AND RecordType.Id = :BRYT_CONTRACT_RECORD_TYPE_ID
        ]; // If this SOQL is empty, there are no contracts with these Bryt_Contract_ID__c's

        // Get all Data from Salesforce according to the CSV:
        List<Bryt_Reference_Capacity__c> allRefCapFromSfAccordingToCsv = [
                SELECT
                        Id,
                        Capacity_Off_Peak__c,
                        Capacity_Peak__c,
                        Contract__c,
                        CreatedById,
                        Month__c,
                        Contract__r.Bryt_Contract_ID__c
                FROM Bryt_Reference_Capacity__c
                WHERE IsDeleted = FALSE
                AND Contract__r.Bryt_Contract_ID__c IN :allDistinctBrytContractIds
        ];

        // Get all Bryt Contracts, which have no Reference-Capacities. Necessary for insert-DML
        List<Contract__c> allContractsWithoutReferenceCapacities = [
                SELECT Id, Bryt_Contract_ID__c
                FROM Contract__c
                WHERE Bryt_Contract_ID__c != NULL
                AND RecordType.Name = 'Bryt Contract'
                AND Id NOT IN (SELECT Contract__c FROM Bryt_Reference_Capacity__c)
        ];

        // Put the above SOQL into map with a distinct key(Month+BrytContractId)
        Map<String, Bryt_Reference_Capacity__c> refCapMap = new Map<String, Bryt_Reference_Capacity__c>();
        for (Bryt_Reference_Capacity__c currentRow : allRefCapFromSfAccordingToCsv) {
            // Create unique key. Will look like: 2021-03-01 00:00:00 141053
            String key = currentRow.Month__c + ' ' + currentRow.Contract__r.Bryt_Contract_ID__c;
            refCapMap.put(key, currentRow);
        } // Later Map-Lookup: refCapMap.get('2021-03-01 00:00:00 141053')

        // Iterate over CSV rows
        for (Integer i = 0; i < csvListOfMapsRefCap.size(); i++) {

            // A single CSV row with its values
            String csvBrytId = String.valueOf(csvListOfMapsRefCap[i].get(CSV_REFCAP_BRYT_CONTRACT_ID));
            Date csvMonth = (Date) csvListOfMapsRefCap[i].get(CSV_REFCAP_MONTH);

            Decimal csvCapBase = null;
            if (String.valueOf(csvListOfMapsRefCap[i].get(CSV_REFCAP_CAPACITY_BASE)).trim() != '') {
                csvCapBase = Decimal.valueOf((Double) csvListOfMapsRefCap[i].get(CSV_REFCAP_CAPACITY_BASE));
            }

            Decimal csvCapPeak = null;
            if (String.valueOf(csvListOfMapsRefCap[i].get(CSV_REFCAP_CAPACITY_PEAK)).trim() != '') {
                csvCapPeak = Decimal.valueOf((Double) csvListOfMapsRefCap[i].get(CSV_REFCAP_CAPACITY_PEAK));
            }

            // With this String, we will search in our "refCapMap" Map
            String csvSearchKeyForMap = null;
            csvSearchKeyForMap = csvMonth + ' ' + csvBrytId;

            // If not NULL, we found a match between CSV and refCapMap
            // E.g.: 2021-03-01 00:00:00 141053 was found in CSV and in refCapMap
            if(refCapMap.get(csvSearchKeyForMap) != null) {
                // Prepare data for update DML
                Bryt_Reference_Capacity__c csvToUpdateDML = new Bryt_Reference_Capacity__c(
                        Id = refCapMap.get(csvSearchKeyForMap).Id,
                        Capacity_Off_Peak__c = csvCapBase,
                        Capacity_Peak__c = csvCapPeak
                );
                csvUpdateList.add(csvToUpdateDML);
            }

            // If user wants to insert (non existing) reference-capacities:
            for (Integer cn = 0; cn < allContractsWithoutReferenceCapacities.size(); cn++) {
                Boolean result = allContractsWithoutReferenceCapacities[cn].Bryt_Contract_ID__c.contains(csvBrytId);
                if (result) { // Found csvBrytId with Contract__c.Id, but no ref-cap
                    Bryt_Reference_Capacity__c csvToInsertDML = new Bryt_Reference_Capacity__c(
                            Contract__c = allContractsWithoutReferenceCapacities[cn].Id,
                            Capacity_Off_Peak__c = csvCapBase,
                            Capacity_Peak__c = csvCapPeak,
                            Month__c = csvMonth,
                            CreatedById = pixosUserId
                    );
                    csvInsertList.add(csvToInsertDML);
                }
            }

            /*
            // If user wants to insert (non existing) reference-capacities
            // for allContractsWithoutReferenceCapacities = 0:
            // Means: All Contracts HAVE actually RefCaps. There are NO contracts without RefCaps.
            Create new RefCaps if:
             - All Contracts HAVE RefCaps in database
             - RefCaps for _this_ Contract was NOT found
             - If Contract exists for given Bryt_Contract_ID__c
            */
            if(allContractsWithoutReferenceCapacities.size() == 0 && refCapMap.get(csvSearchKeyForMap) == null && allDistinctBrytContractIdsWithContractIds.size() != 0){

                Id currentContractId = null; // ... just to get sure, we don´t have already a value here.

                // Get the contract-Id given our List
                for(Contract__c currentContractRow : allDistinctBrytContractIdsWithContractIds){
                    if(currentContractRow.Bryt_Contract_ID__c == csvBrytId) {
                        currentContractId = currentContractRow.Id;
                    }
                }

                if(currentContractId != null) { // Insert only if contract exists
                    Bryt_Reference_Capacity__c csvToInsertDML = new Bryt_Reference_Capacity__c(
                            Contract__c = currentContractId,
                            Capacity_Off_Peak__c = csvCapBase,
                            Capacity_Peak__c = csvCapPeak,
                            Month__c = csvMonth,
                            CreatedById = pixosUserId
                    );
                    csvInsertList.add(csvToInsertDML);
                }

            }

        }

        csvToUpdateAndInsert.add(csvUpdateList);
        csvToUpdateAndInsert.add(csvInsertList);

        return csvToUpdateAndInsert;
    }

    /*
    * @description Helper method, to check for String-values in given Map
    * @parameters Map<Id, String> m, String s
    * */
    public static Boolean checkIfStringInMap(Map<Id, String> m, String s) {
        Boolean myReturn = false;

        for (String key : m.keySet()) {
            if (m.get(key) == s) {
                myReturn = true;
            }
        }

        return myReturn;
    }

    /*
    * @descriptionCreate Account with given name. Return the Account.Id
    * @parameters String accountName
    * */
    public static Id createAccountWithRecordTypeBryt(String accountName) {
        // Not all users are allowed to create Accounts. Pixos user has the permission.
        //TODO: The User that own the record should rather be decided by an entry in a Custom Metadata and only default to Pixos if no such entry can be found
        Id pixosUserId = [SELECT Id FROM User WHERE FirstName = 'Pixos' AND LastName = 'Service' LIMIT 1].Id;

        Account newBrytAccount = new Account(
                Name = accountName,
                RecordTypeId = BRYT_ACCOUNT_RECORD_TYPE_ID,
                OwnerId = pixosUserId,

                // This information is not given in the CSV, but in this context this seems to be correct.
                // A validation rule requires these fields to be set.
                BillingCountry = 'United Kingdom',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Other segments'
        );

        insert newBrytAccount;
        return newBrytAccount.Id;
    }

    public class UserFileWrapper {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public List<ContentVersion> files { get; set; }
        @AuraEnabled public String fileTypes { get; set; }
    }
}