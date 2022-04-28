/****************************************************************************************************
 * Class msContractRoleHandlerTest
 *
 *   Create By	:   Steffen Naundorf (mindsquare GmbH)
 *   Create Date	:   12.12.2019
 *   Description	:
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	   Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Steffen Naundorf (mindsquare GmbH)   12.12.2019      	    Init version.
 *****************************************************************************************************/

@IsTest
private class msContractHandlerTest {
    private static Id UK_RETAIL_CONTRACT_REC_TYPE_ID = msTestDataFactory.UK_RETAIL_CONTRACT_REC_TYPE_ID;
    private static Id CONTRACT_PPA_REC_TYPE_ID = msTestDataFactory.CONTRACT_PPA_RECORD_TYPE_ID;
    private static Id DE_EEG_PROFILE_ID = msTestDataFactory.DE_EEG_PROFILE_ID;
    private static final Date TODAY = Date.today();

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();
    }

    @IsTest
    private static void testContractIdGeneration() {
        Contract__c testContract = [SELECT Id, Statkraft_Contract_ID__c FROM Contract__c WHERE Country__c = 'France' LIMIT 1];
        System.assert(testContract.Statkraft_Contract_ID__c != null, 'The ID generation is deactivated');
        System.assert(testContract.Statkraft_Contract_ID__c.isNumeric(), 'The ID was illegally defined');
    }

    @IsTest
    private static void testUpdateMarket() {
        Contract__c testContract = [SELECT Id, Global_Portal_Market__c FROM Contract__c LIMIT 1];

        testContract.Country__c = 'France';
        update testContract;
        testContract = [SELECT Id, Global_Portal_Market__c FROM Contract__c WHERE Id = :testContract.Id];
        System.assertEquals('France', testContract.Global_Portal_Market__c);

        testContract.Country__c = 'Germany';
        update testContract;
        testContract = [SELECT Id, Global_Portal_Market__c FROM Contract__c WHERE Id = :testContract.Id];
        System.assertEquals('Germany', testContract.Global_Portal_Market__c);

        testContract.Country__c = 'United Kingdom';
        testContract.Contract_Type_New__c = 'Merchant PPA';
        testContract.Product_Type_New__c = 'Flex Optimization GB';
        update testContract;
        testContract = [SELECT Id, Global_Portal_Market__c FROM Contract__c WHERE Id = :testContract.Id];
        System.assertEquals('Flex', testContract.Global_Portal_Market__c);

        testContract.Country__c = 'United Kingdom';
        testContract.Contract_Type_New__c = null;
        testContract.Product_Type_New__c = null;
        testContract.RecordTypeId = UK_RETAIL_CONTRACT_REC_TYPE_ID;
        update testContract;
        testContract = [SELECT Id, Global_Portal_Market__c FROM Contract__c WHERE Id = :testContract.Id];
        System.assertEquals('UKRetail', testContract.Global_Portal_Market__c);
    }

    @IsTest
    private static void testContractValidationPositiveDEEEGInsert() {
        Custom_Validation_Passes__mdt profileDEEEGPasses = [
                SELECT
                        Id,
                        CfD_Product_Types__c,
                        Feed_in_Tariff_Product_Types__c,
                        Framework_Agreement_Product_Types__c,
                        Merchant_PPA_Product_Types__c,
                        Sub_Contract_Product_Types__c,
                        Supply_Product_Types__c
                FROM Custom_Validation_Passes__mdt
                WHERE Profile_Id__c = :DE_EEG_PROFILE_ID
                LIMIT 1
        ];
        User testUserOffice = [
                SELECT Id
                FROM User
                WHERE Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser'
        ];
        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        List<Contract__c> contractsToInsertForTest = new List<Contract__c>();
        if (profileDEEEGPasses.CfD_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'CfD';
            newContract.Product_Type_New__c = profileDEEEGPasses.CfD_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Feed_in_Tariff_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Feed in Tariff PPA';
            newContract.Product_Type_New__c = profileDEEEGPasses.Feed_in_Tariff_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Framework_Agreement_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Framework Agreement';
            newContract.Product_Type_New__c = profileDEEEGPasses.Framework_Agreement_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Merchant_PPA_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Merchant PPA';
            newContract.Product_Type_New__c = profileDEEEGPasses.Merchant_PPA_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Sub_Contract_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Sub-Contract';
            newContract.Product_Type_New__c = profileDEEEGPasses.Sub_Contract_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Supply_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Supply';
            newContract.Product_Type_New__c = profileDEEEGPasses.Supply_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }

        Test.startTest();
        System.runAs(testUserOffice) {
            insert contractsToInsertForTest;
        }
        Test.stopTest();
    }

    @IsTest
    private static void testContractValidationPositiveDEEEGUpdate() {
        Custom_Validation_Passes__mdt profileDEEEGPasses = [
                SELECT
                        Id,
                        CfD_Product_Types__c,
                        Feed_in_Tariff_Product_Types__c,
                        Framework_Agreement_Product_Types__c,
                        Merchant_PPA_Product_Types__c,
                        Sub_Contract_Product_Types__c,
                        Supply_Product_Types__c
                FROM Custom_Validation_Passes__mdt
                WHERE Profile_Id__c = :DE_EEG_PROFILE_ID
                LIMIT 1
        ];
        User testUserOffice = [
                SELECT Id
                FROM User
                WHERE Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser'
        ];
        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        List<Contract__c> contractsToInsertForTest = new List<Contract__c>();
        if (profileDEEEGPasses.CfD_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'CfD';
            newContract.Product_Type_New__c = profileDEEEGPasses.CfD_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Feed_in_Tariff_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Feed in Tariff PPA';
            newContract.Product_Type_New__c = profileDEEEGPasses.Feed_in_Tariff_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Framework_Agreement_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Framework Agreement';
            newContract.Product_Type_New__c = profileDEEEGPasses.Framework_Agreement_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Merchant_PPA_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Merchant PPA';
            newContract.Product_Type_New__c = profileDEEEGPasses.Merchant_PPA_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Sub_Contract_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Sub-Contract';
            newContract.Product_Type_New__c = profileDEEEGPasses.Sub_Contract_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        if (profileDEEEGPasses.Supply_Product_Types__c != null) {
            Contract__c newContract = minimalContractFactoryGermany(randomAccount.Id);
            newContract.Contract_Type_New__c = 'Supply';
            newContract.Product_Type_New__c = profileDEEEGPasses.Supply_Product_Types__c.split(';')[0];
            contractsToInsertForTest.add(newContract);
        }
        insert contractsToInsertForTest;
        Integer countOfNewContracts = contractsToInsertForTest.size();
        List<String> contractTypes = new List<String>();
        List<String> productTypes = new List<String>();

        for (Contract__c contractItem : contractsToInsertForTest) {
            contractTypes.add(contractItem.Contract_Type_New__c);
            productTypes.add(contractItem.Product_Type_New__c);
        }
        List<Contract__c> contractListForUpdate = new List<Contract__c>();
        for (Integer i = 0; i < countOfNewContracts; i++) {
            contractListForUpdate.add(
                    new Contract__c(
                            Id = contractsToInsertForTest[i].Id,
                            Contract_Type_New__c = contractTypes[countOfNewContracts - i - 1],
                            Product_Type_New__c = productTypes[countOfNewContracts - i - 1]
                    )
            );
        }

        Test.startTest();
        System.runAs(testUserOffice) {
            update contractListForUpdate;
        }
        Test.stopTest();
    }

    @IsTest
    private static void testContractValidationNegativeDEEEGInsert() {
        Custom_Validation_Passes__mdt profileDEEEGPasses = [
                SELECT
                        Id,
                        CfD_Product_Types__c,
                        Feed_in_Tariff_Product_Types__c,
                        Framework_Agreement_Product_Types__c,
                        Merchant_PPA_Product_Types__c,
                        Sub_Contract_Product_Types__c,
                        Supply_Product_Types__c
                FROM Custom_Validation_Passes__mdt
                WHERE Profile_Id__c = :DE_EEG_PROFILE_ID
                LIMIT 1
        ];
        User testUserOffice = [
                SELECT Id
                FROM User
                WHERE Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser'
        ];
        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        Set<String> validFeedInTariffProducts = new Set<String>(
                profileDEEEGPasses.Feed_in_Tariff_Product_Types__c.split(';')
        );
        Set<String> validMerchantPPAProducts = new Set<String>(
                profileDEEEGPasses.Merchant_PPA_Product_Types__c.split(';')
        );
        String invalidProduct;

        for (String validMerchantPPAProduct : validMerchantPPAProducts) {
            if (!validFeedInTariffProducts.contains(validMerchantPPAProduct)) {
                invalidProduct = validMerchantPPAProduct;
                break;
            }
        }

        Contract__c newContractForTest = minimalContractFactoryGermany(randomAccount.Id);
        newContractForTest.Contract_Type_New__c = 'Feed in Tariff PPA';
        newContractForTest.Product_Type_New__c = invalidProduct;

        Boolean blockedAsIntended = false;
        String error = '';
        Test.startTest();
        System.runAs(testUserOffice) {
            try {
                insert newContractForTest;
            } catch (Exception e) {
                blockedAsIntended = true;
                error += e.getMessage();
            }
        }
        Test.stopTest();
        System.assert(blockedAsIntended, 'Should have blocked the insert of the Contract');
        System.assert(
                error.contains(Label.msContractTypeAndProductTypeValidationError),
                'The wrong error occurred: ' + error
        );
    }

    @IsTest
    private static void testContractValidationNegativeDEEEGUpdate() {
        Custom_Validation_Passes__mdt profileDEEEGPasses = [
                SELECT
                        Id,
                        CfD_Product_Types__c,
                        Feed_in_Tariff_Product_Types__c,
                        Framework_Agreement_Product_Types__c,
                        Merchant_PPA_Product_Types__c,
                        Sub_Contract_Product_Types__c,
                        Supply_Product_Types__c
                FROM Custom_Validation_Passes__mdt
                WHERE Profile_Id__c = :DE_EEG_PROFILE_ID
                LIMIT 1
        ];
        User testUserOffice = [
                SELECT Id
                FROM User
                WHERE Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser'
        ];
        Account randomAccount = [SELECT Id FROM Account LIMIT 1];
        Set<String> validFeedInTariffProducts = new Set<String>(
                profileDEEEGPasses.Feed_in_Tariff_Product_Types__c.split(';')
        );
        Set<String> validMerchantPPAProducts = new Set<String>(
                profileDEEEGPasses.Merchant_PPA_Product_Types__c.split(';')
        );
        String invalidProduct;

        for (String validMerchantPPAProduct : validMerchantPPAProducts) {
            if (!validFeedInTariffProducts.contains(validMerchantPPAProduct)) {
                invalidProduct = validMerchantPPAProduct;
                break;
            }
        }

        Contract__c newContractForTest = minimalContractFactoryGermany(randomAccount.Id);
        newContractForTest.Contract_Type_New__c = 'Feed in Tariff PPA';
        newContractForTest.Product_Type_New__c = profileDEEEGPasses.Feed_in_Tariff_Product_Types__c.split(';')[0];
        System.runAs(testUserOffice) {
            insert newContractForTest;
        }

        Boolean blockedAsIntended = false;
        String error = '';
        Test.startTest();
        System.runAs(testUserOffice) {
            try {
                newContractForTest.Product_Type_New__c = invalidProduct;
                update newContractForTest;
            } catch (Exception e) {
                blockedAsIntended = true;
                error += e.getMessage();
            }
        }
        Test.stopTest();
        System.assert(blockedAsIntended, 'Should have blocked the update of the Contract');
        System.assert(
                error.contains(Label.msContractTypeAndProductTypeValidationError),
                'The wrong error occurred: ' + error
        );
    }

    private static Contract__c minimalContractFactoryGermany(Id accountId) {
        return new Contract__c(
                RecordTypeId = CONTRACT_PPA_REC_TYPE_ID,
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.newInstance(Date.today().year(), 12, 31),
                Contract_Holder__c = accountId,
                Status__c = 'Active',
                Country__c = 'Germany',
                RED_Contract_ID__c = 'GermanTestContract1',
                Approved__c = true,
                Meter_Billing_Type__c = 'Sub-Meter Yearly',
                Name = 'DETestContract1',
                Settlement_SubModel__c = null
        );
    }


    @IsTest
    private static void testCongaNoAmendment_Insert() {
        Test.startTest();
        CongaContextTestData testData = createTestDataConga(1, false);
        Test.stopTest();
        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Start_Date__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.End_Date__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    private static void testCongaNoAmendment_Update() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(1, false);
        enableTriggers();

        Test.startTest();
        for (Contract__c contractItem : testData.Contracts) {
            contractItem.Start_Date__c = TODAY;
            contractItem.End_Date__c = TODAY.addYears(2);
        }
        update testData.Contracts;
        Test.stopTest();
        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(contractItem.Start_Date__c, contractItem.Start_for_Conga_Context__c);
            System.assertEquals(contractItem.End_Date__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    private static void testCongaWithAmendment_Update() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(1, true);
        enableTriggers();
        Test.startTest();
        for (Contract__c contractItem : testData.Contracts) {
            contractItem.Start_Date__c = TODAY;
            contractItem.End_Date__c = TODAY.addYears(2);
        }
        update testData.Contracts;
        Test.stopTest();
        testData.updateContracts();
        for (Contract__c contractItem : testData.Contracts) {
            System.assertEquals(
                    contractItem.Last_Amentment__r.Amendment_Start__c,
                    contractItem.Start_for_Conga_Context__c
            );
            System.assertEquals(contractItem.Last_Amentment__r.Amendment_End__c, contractItem.End_for_Conga_Context__c);
        }
    }

    @IsTest
    private static void anp_testRenaming_single() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(1, true);
        enableTriggers();
        Test.startTest();
        for (Contract__c contractItem : testData.Contracts) {
            contractItem.Name = 'Test Renaming';
        }
        update testData.Contracts;
        Test.stopTest();
        List<Ammendment__c> amendments = [SELECT Name FROM Ammendment__c WHERE Base_Contract__c IN :testData.Contracts];
        for (Ammendment__c amendment : amendments) {
            System.assert(amendment.Name.contains('Test Renaming'), 'Amendment was not renamed');
        }
    }

    @IsTest
    private static void anp_testRenaming_bulk() {
        disableTriggers();
        CongaContextTestData testData = createTestDataConga(2, true);
        enableTriggers();
        Test.startTest();
        for (Contract__c contractItem : testData.Contracts) {
            contractItem.Name = 'Test Renaming';
        }
        update testData.Contracts;
        Test.stopTest();
        List<Ammendment__c> amendments = [SELECT Name FROM Ammendment__c WHERE Base_Contract__c IN :testData.Contracts];
        for (Ammendment__c amendment : amendments) {
            System.assert(amendment.Name.contains('Test Renaming'), 'Amendment was not renamed');
        }
    }

    @IsTest
    private static void remitTerminationCaseTest() {
        Contract__c testContract = [
                SELECT Id, End_Date__c, (SELECT Id FROM Cases__r)
                FROM Contract__c
                WHERE Country__c = 'Germany'
                LIMIT 1
        ];
        Integer initialCount = testContract.Cases__r.size();
        testContract.Country__c = 'Germany';
        testContract.Contract_Type_New__c = 'Merchant PPA';
        testContract.Termination_Status__c = 'Terminated by Statkraft';
        testContract.Status__c = 'Active';
        testContract.REMIT_Reporting_Relevant__c = true;
        testContract.Contracted_Capacity__c = 100;
        testContract.Legal_Capacity__c = 100;
        testContract.Active_Installed_Capacity__c = 100;
        testContract.Contract_Date__c = Date.today().addYears(-100);
        testContract.End_Date__c = testContract.End_Date__c.addDays(-1);

        Test.startTest();
        update testContract;
        Test.stopTest();

        testContract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        System.assert(initialCount < testContract.Cases__r.size(), 'Remit Case: Termination was not generated');
    }

    @IsTest
    private static void remitDelegatedReportingChangeCaseTest() {
        Contract__c testContract = [
                SELECT Id, REMIT_delegated_reporting__c, End_Date__c, (SELECT Id FROM Cases__r)
                FROM Contract__c
                WHERE Country__c = 'Germany'
                LIMIT 1
        ];
        Integer initialCount = testContract.Cases__r.size();
        testContract.Country__c = 'Germany';
        testContract.Contract_Type_New__c = 'Merchant PPA';
        testContract.Status__c = 'Active';
        testContract.REMIT_Reporting_Relevant__c = true;
        testContract.Contracted_Capacity__c = 100;
        testContract.Legal_Capacity__c = 100;
        testContract.Active_Installed_Capacity__c = 100;
        testContract.Contract_Date__c = Date.today().addYears(-100);
        testContract.REMIT_delegated_reporting__c = !testContract.REMIT_delegated_reporting__c;

        Test.startTest();
        update testContract;
        Test.stopTest();

        testContract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        System.assert(
                initialCount < testContract.Cases__r.size(),
                'Remit Case: Delegated Reporting Change was not generated'
        );
    }

    @IsTest
    private static void remitAgreementDateChangeCaseTest() {
        Contract__c testContract = [
                SELECT Id, REMIT_Agreement_Date__c, End_Date__c, (SELECT Id FROM Cases__r)
                FROM Contract__c
                WHERE Country__c = 'Germany'
                LIMIT 1
        ];
        Integer initialCount = testContract.Cases__r.size();
        testContract.Country__c = 'Germany';
        testContract.Contract_Type_New__c = 'Merchant PPA';
        testContract.Status__c = 'Active';
        testContract.REMIT_Reporting_Relevant__c = true;
        testContract.Contracted_Capacity__c = 100;
        testContract.Legal_Capacity__c = 100;
        testContract.Active_Installed_Capacity__c = 100;
        testContract.Contract_Date__c = Date.today().addYears(-100);
        testContract.End_Date__c = testContract.End_Date__c.addDays(-1);
        if (testContract.REMIT_Agreement_Date__c == null) {
            testContract.REMIT_Agreement_Date__c = Date.today();
        } else {
            testContract.REMIT_Agreement_Date__c = testContract.REMIT_Agreement_Date__c.addDays(-1);
        }

        Test.startTest();
        update testContract;
        Test.stopTest();

        testContract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        System.assert(
                initialCount < testContract.Cases__r.size(),
                'Remit Case: Agreement Date Change was not generated'
        );
    }

    @IsTest
    private static void remitContractHolderChangeCaseTest() {
        Contract__c testContract = [
                SELECT Id, Contract_Holder__c, End_Date__c, (SELECT Id FROM Cases__r)
                FROM Contract__c
                WHERE Country__c = 'Germany'
                LIMIT 1
        ];
        Account randomOtherAccount = [SELECT Id FROM Account WHERE Id != :testContract.Contract_Holder__c LIMIT 1];
        Integer initialCount = testContract.Cases__r.size();
        testContract.Country__c = 'Germany';
        testContract.Contract_Type_New__c = 'Merchant PPA';
        testContract.Status__c = 'Active';
        testContract.REMIT_Reporting_Relevant__c = true;
        testContract.Contracted_Capacity__c = 100;
        testContract.Legal_Capacity__c = 100;
        testContract.Active_Installed_Capacity__c = 100;
        testContract.Contract_Date__c = Date.today().addYears(-100);
        testContract.Contract_Holder__c = randomOtherAccount.Id;

        Test.startTest();
        update testContract;
        Test.stopTest();

        testContract = [SELECT Id, (SELECT Id FROM Cases__r) FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];
        System.assert(
                initialCount < testContract.Cases__r.size(),
                'Remit Case: Contract holder Change was not generated'
        );
    }


    private static CongaContextTestData createTestDataConga(Integer batchSize, Boolean withAmendments) {
        CongaContextTestData testData = new CongaContextTestData();

        testData.Owner = createAccount('Owner');
        insert testData.Owner;

        for (Integer i = 0; i < batchSize; i++) {
            testData.Contracts.add(
                    createContract(TODAY.addYears(-1), TODAY.addYears(1), testData.Owner.Id, 'Name' + i)
            );
        }
        insert testData.Contracts;
        for (Contract__c contractItem : testData.Contracts) {
            testData.contractIds.add(contractItem.Id);
        }
        if (withAmendments) {
            //Faulty Flow design force us to have more test data in place in order to create Amendments - uSe DeClArAtIvE ToOlS.....
            Opportunity opp = createOpportunity('test', testData.Owner.Id);
            insert opp;

            List<Ammendment__c> amendments = new List<Ammendment__c>();
            List<Pricing_Component__c> pcList = new List<Pricing_Component__c>();
            for (Integer i = 0; i < batchSize; i++) {
                amendments.add(createAmendment('test' + i, testData.Contracts[i].Id, TODAY, TODAY.addYears(2)));
                pcList.add(
                        createPricingComponent(
                                'test' + i,
                                testData.Contracts[i].Id,
                                testData.Contracts[i].Start_Date__c,
                                testData.Contracts[i].End_Date__c
                        )
                );
            }
            insert pcList;
            insert amendments;

            for (Integer i = 0; i < batchSize; i++) {
                testData.Contracts[i].Last_Amentment__c = amendments[i].Id;
            }
            update testData.Contracts;
        }
        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account(
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
    }

    private static Opportunity createOpportunity(String nameEntry, Id accountId) {
        return new Opportunity(
                RecordTypeId = '0121v00000034W0AAI',
                Country__c = 'Germany',
                Opportunity_Size__c = 'Portfolio',
                AccountId = accountId,
                Name = nameEntry,
                StageName = 'New',
                CloseDate = TODAY
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder, String nameString) {
        String status = 'Active';
        if (endDate < TODAY) {
            status = 'Expired';
        } else if (TODAY < startDate) {
            status = 'Draft';
        }
        return new Contract__c(
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = nameString,
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0,
                Start_for_Conga_Context__c = TODAY.addYears(-1),
                End_for_Conga_Context__c = TODAY.addDays(-1)
        );
    }

    private static Pricing_Component__c createPricingComponent(
            String nameEntry,
            Id contractId,
            Date startDate,
            Date endDate
    ) {
        return new Pricing_Component__c(
                Name = nameEntry,
                Contract__c = contractId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }

    private static Ammendment__c createAmendment(String nameString, Id baseContractId, Date startDate, Date endDate) {
        return new Ammendment__c(
                Name = nameString,
                Base_Contract__c = baseContractId,
                Amendment_Start__c = startDate,
                Amendment_End__c = endDate,
                Security_Handling__c = 'no security anymore',
                Status__c = 'In Progress',
                Contract_Type__c = 'Feed in Tariff PPA',
                Product_type__c = 'Direct Marketing'
        );
    }

    private class CongaContextTestData {
        Account Owner { get; set; }
        List<Contract__c> Contracts { get; set; }
        Set<Id> contractIds = new Set<Id>();

        public CongaContextTestData() {
            Contracts = new List<Contract__c>();
        }

        public void updateContracts() {
            Contracts = [
                    SELECT
                            Id,
                            Start_Date__c,
                            End_Date__c,
                            Start_for_Conga_Context__c,
                            End_for_Conga_Context__c,
                            Last_Amentment__c,
                            Last_Amentment__r.Amendment_Start__c,
                            Last_Amentment__r.Amendment_End__c
                    FROM Contract__c
                    WHERE Id IN :this.Contracts
            ];
        }
    }
    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Account.SObjectType);
        TriggerHandlerExtension.disableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Assignment__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Account.SObjectType);
        TriggerHandlerExtension.enableObject(Ammendment__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__ChangeEvent.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Assignment__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
    }
}