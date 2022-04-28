@IsTest
public class msPerformanceIndicatorRollupBatchTest {

    private static final String ACCOUNT_TEST_NAME_WITHOUT_CHILDREN = 'Without Children';
    private static final String ACCOUNT_TEST_NAME_WITH_CHILDREN = 'With Children';
    private static final String ACCOUNT_TEST_NAME_CHILD = 'Child Account';
    private static final Id CONTRACT_PPA = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();
    private static final Id DE_EEG_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = :'DE EEG' LIMIT 1].Id;

    @TestSetup
    static void setup() {
        User runningUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        User testUser = new User();
        testUser.ProfileId = DE_EEG_PROFILE_ID;
        testUser.Username = 'testuser@statkraft.mindsquare.apex.testuser.eeg';
        testUser.Email = 'testuser@mindsquare.co.uk';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.LocaleSidKey = 'en_GB';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.TimeZoneSidKey = 'Europe/Berlin';
        testUser.Alias = 'tstusr';
        testUser.LastName = 'user';
        testUser.MobilePhone = '+44123456789';
        testUser.IsActive = true;
        System.runAs(runningUser) {
            insert testUser;
        }

        List<Account> accountsToInsert = new List<Account>();
        Account accountWithoutChildren = new Account(
                Name = ACCOUNT_TEST_NAME_WITHOUT_CHILDREN,
                OwnerId = testUser.Id,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        Account accountWithChildren = new Account(
                Name = ACCOUNT_TEST_NAME_WITH_CHILDREN,
                OwnerId = testUser.Id,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials'
        );
        accountsToInsert.add(accountWithoutChildren);
        accountsToInsert.add(accountWithChildren);
        insert accountsToInsert;

        Account childAccount = new Account(
                Name = ACCOUNT_TEST_NAME_CHILD,
                Sandbox_Migration_Id__c = ACCOUNT_TEST_NAME_CHILD,
                Negotiating_Party__c = accountWithChildren.Id,
                OwnerId = testUser.Id,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
        insert childAccount;

        Date today = Date.today();
        Date contractStartDate = Date.newInstance(today.addYears(-1).year(), today.addMonths(1).month(), 1);

        Contract__c accountWithoutChildrenContract = new Contract__c(
                Contract_Holder__c = accountWithoutChildren.Id,
                Name = 'test1',
                Start_Date__c = contractStartDate,
                Status__c = 'Active',
                Approved__c = true,
                RecordTypeId = CONTRACT_PPA,
                Country__c = 'Germany'
        );
        Contract__c accountWithChildrenContract = new Contract__c(
                Contract_Holder__c = accountWithChildren.Id,
                Start_Date__c = contractStartDate,
                Name = 'test2',
                Status__c = 'Active',
                Approved__c = true,
                RecordTypeId = CONTRACT_PPA,
                Country__c = 'Germany'
        );
        Contract__c childAccountContract = new Contract__c(
                Contract_Holder__c = childAccount.Id,
                Name = 'test3',
                Start_Date__c = contractStartDate,
                Status__c = 'Active',
                Approved__c = true,
                RecordTypeId = CONTRACT_PPA,
                Country__c = 'Germany'
        );
        List<Contract__c> contractsToInsert = new List<Contract__c>{accountWithoutChildrenContract, accountWithChildrenContract, childAccountContract};
        insert contractsToInsert;

        Meter__c deMeter = new Meter__c(
                Name = 'deMeter',
                Status__c = 'Active',
                Country__c = 'Germany',
                Portfolio_ID__c = 'as_de2_an_11210_windpark_hohenseefeld',
                Alternative_Meter_ID__c = 'FRPORTALPLH'
        );
        insert deMeter;

        List<Performance_Indicator__c> performanceIndicatorsToInsert = new List<Performance_Indicator__c>();
        for(Contract__c c : contractsToInsert) {
            Date firstDayOfMonth = Date.newInstance(today.year(), today.month(), 1);
            for(Integer i=0; i < 12; i++) {
                Performance_Indicator__c performanceIndicator = new Performance_Indicator__c();
                performanceIndicator.Cashflow_DownReg_Compensation__c = 10;
                performanceIndicator.Cashflow_Production_Compensation__c = 10;
                performanceIndicator.Contract__c = c.Id;
                performanceIndicator.Dispatch_Profit__c = 10;
                performanceIndicator.Margin_Dispatch__c = 10;
                performanceIndicator.Margin_non_compensated_X51__c = 10;
                performanceIndicator.Margin_Sales__c = 10;
                performanceIndicator.Margin_X51_Flexibility__c = 10;
                performanceIndicator.Market_Value__c = 10;
                performanceIndicator.Market_Value_Difference_12month_rolling__c = 10;
                performanceIndicator.Market_Value_Difference__c = 10;
                performanceIndicator.Month__c = firstDayOfMonth;
                performanceIndicator.of_all_generation_units__c = 10;
                performanceIndicator.of_all_P51_generation_units__c = 10;
                performanceIndicator.P51_Capacity__c = 10;
                performanceIndicator.Sales_Profit_w_o_P51_day_ahead_flex__c = 10;
                performanceIndicator.Total_Capacity__c = 10;
                performanceIndicator.Total_DownReg_volume__c = 10;
                performanceIndicator.Total_Production_Volume__c = 10;
                performanceIndicator.Meter__c = deMeter.Id;
                performanceIndicatorsToInsert.add(performanceIndicator);
                firstDayOfMonth = firstDayOfMonth.addMonths(-1);
            }
        }
        insert performanceIndicatorsToInsert;
    }

    @IsTest
    static void shouldCalculateRollUps() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();

        Test.startTest();

        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        // UNDO System.assert(![
        // UNDO         SELECT
        // UNDO                 Id
        // UNDO         FROM Contract__c
        // UNDO         WHERE of_all_generation_units__c = 10
        // UNDO         AND of_P51_generation_units__c = 10
        // UNDO         AND Market_Value_Difference_CY__c = 10
        // UNDO         AND Market_Value_Difference_12M__c = 10
        // UNDO  ].isEmpty());
        // UNDO  System.assert(![
        // UNDO         SELECT
        // UNDO                 Id
        // UNDO        FROM Account
        // UNDO        WHERE Name = :ACCOUNT_TEST_NAME_WITH_CHILDREN
        // UNDO         AND of_all_generation_units__c = 20
        // UNDO         AND Market_Value_Difference_CY__c = 10
        // UNDO         AND Market_Value_Difference_12M__c = 10
        // UNDO ].isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.isEmpty());
    }

    @IsTest
    static void shouldFindMissingPerformanceIndicatorFromFirstMonthOfContract() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Performance_Indicator__c performanceIndicatorFirstMonth = [
                SELECT Id, Contract__c
                FROM Performance_Indicator__c
                WHERE Contract__r.Contract_Holder__r.Sandbox_Migration_Id__c = :ACCOUNT_TEST_NAME_CHILD
                ORDER BY Month__c
                LIMIT 1
        ];
        Id contractIdWithMissingFirstMonthPI = performanceIndicatorFirstMonth.Contract__c;

        Test.startTest();

        delete performanceIndicatorFirstMonth;
        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Contract__c WHERE Contract_Holder__r.Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Account WHERE Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.contains(contractIdWithMissingFirstMonthPI));
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
    }

    @IsTest
    static void shouldFindMissingPerformanceIndicatorFromLastMonthOfContract() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Performance_Indicator__c performanceIndicatorLastMonth = [
                SELECT Id, Contract__c
                FROM Performance_Indicator__c
                WHERE Contract__r.Contract_Holder__r.Sandbox_Migration_Id__c = :ACCOUNT_TEST_NAME_CHILD
                ORDER BY Month__c DESC
                LIMIT 1
        ];
        Id contractIdWithMissingLastMonthPI = performanceIndicatorLastMonth.Contract__c;

        Test.startTest();

        delete performanceIndicatorLastMonth;
        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Contract__c WHERE Contract_Holder__r.Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Account WHERE Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.contains(contractIdWithMissingLastMonthPI));
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
    }

    @IsTest
    static void shouldFindMissingPerformanceIndicatorFromMonthInTheMiddleOfContract() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Performance_Indicator__c performanceIndicator = [
                SELECT Id, Contract__c
                FROM Performance_Indicator__c
                WHERE Contract__r.Contract_Holder__r.Sandbox_Migration_Id__c = :ACCOUNT_TEST_NAME_CHILD
                ORDER BY Month__c DESC
                LIMIT 1
                OFFSET 3
        ];
        Id contractIdWithMissingPI = performanceIndicator.Contract__c;

        Test.startTest();

        delete performanceIndicator;
        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Contract__c WHERE Contract_Holder__r.Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        // UNDO System.assertEquals(null, [SELECT Market_Value_Difference_12M__c FROM Account WHERE Name = :ACCOUNT_TEST_NAME_CHILD].Market_Value_Difference_12M__c);
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.contains(contractIdWithMissingPI));
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
    }

    @IsTest
    static void shouldFindCorruptedPerformanceIndicator() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Performance_Indicator__c corruptedPerformanceIndicator = [
                SELECT Id, Market_Value__c
                FROM Performance_Indicator__c
                LIMIT 1
        ];
        corruptedPerformanceIndicator.Market_Value__c = null;
        update corruptedPerformanceIndicator;

        Test.startTest();

        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.containsKey(corruptedPerformanceIndicator.Id));
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
    }

    @IsTest
    static void shouldFindMissingContractVersion() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Contract__c contractRecord = [
                SELECT Id, Name
                FROM Contract__c
                WHERE Contract_Holder__r.Sandbox_Migration_Id__c = :ACCOUNT_TEST_NAME_CHILD
        ];
        contractRecord.Name = contractRecord.Name.split('/')[0] + '/2';
        update contractRecord;

        Test.startTest();

        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        //System.assert(!msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.isEmpty());
    }

    @IsTest
    static void shouldCheckIfPreviousContractIsWipedOut() {
        msPerformanceIndicatorRollupBatch performanceIndicatorRollupBatch = new msPerformanceIndicatorRollupBatch();
        Contract__c contractRecord = [
                SELECT Id, Name, Contract_Holder__c, Start_Date__c, End_Date__c
                FROM Contract__c
                WHERE Contract_Holder__r.Sandbox_Migration_Id__c = :ACCOUNT_TEST_NAME_CHILD
        ];
        String contractName = contractRecord.Name;
        contractRecord.Name = contractName.split('/')[0] + '/2';
        update contractRecord;
        
        Contract__c previousContract = new Contract__c(
                Approved__c = true,
                Contract_Holder__c = contractRecord.Contract_Holder__c,
                of_all_generation_units__c = 10,
                Total_Capacity_CY__c = 10,
                Start_Date__c = contractRecord.Start_Date__c.addYears(-1),
                End_Date__c = contractRecord.Start_Date__c.addMonths(-1),
                RecordTypeId = CONTRACT_PPA,
                Country__c = 'Germany',
                Name = 'test4'
        );
        insert previousContract;

        previousContract.Name = contractName;
        update previousContract;

        Test.startTest();

        Database.executeBatch(performanceIndicatorRollupBatch, 100);

        Test.stopTest();

        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPreviousVersions.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.corruptedPerformanceIndicatorsByIds.isEmpty());
        //System.assert(msPerformanceIndicatorRollupBatch.contractsIdsWithMissingPerformanceIndicators.isEmpty());

        // UNDO System.assert(![SELECT Id FROM Contract__c WHERE Id = :previousContract.Id AND of_P51_generation_units__c = NULL AND Total_Capacity_CY__c = NULL].isEmpty());
    }
}