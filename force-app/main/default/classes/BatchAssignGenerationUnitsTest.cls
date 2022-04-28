/****************************************************************************************************
* Class BatchAssignGenerationUnitsTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-04-09
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-04-09       	Init version.
*****************************************************************************************************/

@IsTest
private class BatchAssignGenerationUnitsTest {
    static final Date today = Date.today();
    static final Date threeYearsAgoStart = today.addYears(-3).toStartOfMonth();
    static final Date threeYearsAgoEnd = today.addYears(-3).addMonths(1);
    static final Date twoYearsAgoStart = today.addYears(-2).toStartOfMonth();
    static final Date twoYearsAgoEnd = today.addYears(-2).addMonths(1);
    static final Date inOneYearStart = today.addYears(1).toStartOfMonth();
    static final Date inOneYearEnd = today.addYears(1).addMonths(1).toStartOfMonth();
    static final Integer BATCH_SIZE = 200;

    @IsTest
    static void createAssignments_TestStatic_Bulk() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_MergeAndSplit(BATCH_SIZE);
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();
        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(13, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');

            ListMapContainer contractIdToGenUnitAssignments = new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);
            for (Generation_Unit_Assignment__c assignmentItem : genUnit.Generation_Unit_Assignments__r) {
                contractIdToGenUnitAssignments.addToMap(assignmentItem.Contract__c, assignmentItem);
            }
            List<Generation_Unit_Assignment__c> earliestAssignments = contractIdToGenUnitAssignments.get(testData.earliestContract.Id);
            List<Generation_Unit_Assignment__c> earlyAssignments = contractIdToGenUnitAssignments.get(testData.earlyContract.Id);
            List<Generation_Unit_Assignment__c> currentAssignments = contractIdToGenUnitAssignments.get(testData.currentContract.Id);
            List<Generation_Unit_Assignment__c> laterAssignments = contractIdToGenUnitAssignments.get(testData.laterContract.Id);

            System.assertEquals(1, earliestAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.earliestContract.Start_Date__c, earliestAssignments[0].Start_Date__c);
            System.assertEquals(testData.earliestContract.End_Date__c, earliestAssignments[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, earliestAssignments[0].Generation_Unit_Ownership__r.Asset_Owner__c);

            System.assertEquals(3, earlyAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.earlyContract.Start_Date__c, earlyAssignments[0].Start_Date__c);
            System.assertEquals(testData.earlyContract.Start_Date__c.addDays(4), earlyAssignments[0].End_Date__c);
            System.assertEquals(null, earlyAssignments[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.earlyContract.Start_Date__c.addDays(5), earlyAssignments[1].Start_Date__c);
            System.assertEquals(testData.earlyContract.End_Date__c.addDays(-5), earlyAssignments[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, earlyAssignments[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.earlyContract.End_Date__c.addDays(-4), earlyAssignments[2].Start_Date__c);
            System.assertEquals(testData.earlyContract.End_Date__c, earlyAssignments[2].End_Date__c);
            System.assertEquals(null, earlyAssignments[2].Generation_Unit_Ownership__c);

            System.debug('currentAssignments');
            System.debug(currentAssignments);
            System.assertEquals(7, currentAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, currentAssignments[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c, currentAssignments[0].End_Date__c);
            System.assertEquals(null, currentAssignments[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(1), currentAssignments[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(1), currentAssignments[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, currentAssignments[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addMonths(2).addDays(1), currentAssignments[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), currentAssignments[2].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, currentAssignments[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-4), currentAssignments[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-3), currentAssignments[3].End_Date__c);
            System.assertEquals(null, currentAssignments[3].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-2), currentAssignments[4].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-1), currentAssignments[4].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, currentAssignments[4].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c, currentAssignments[5].Start_Date__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(1), currentAssignments[5].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, currentAssignments[5].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(2), currentAssignments[6].Start_Date__c);
            System.assertEquals(null, currentAssignments[6].End_Date__c);
            System.assertEquals(null, currentAssignments[6].Generation_Unit_Ownership__c);

            System.assertEquals(2, laterAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.laterContract.Start_Date__c, laterAssignments[0].Start_Date__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(1), laterAssignments[0].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, laterAssignments[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(2), laterAssignments[1].Start_Date__c);
            System.assertEquals(null, laterAssignments[1].End_Date__c);
            System.assertEquals(null, laterAssignments[1].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    static void createAssignments_TestInstantiated_Bulk() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_MergeAndSplit(BATCH_SIZE);
        enableTriggers();

        Test.startTest();

        Database.executeBatch(new BatchAssignGenerationUnits(), BATCH_SIZE);

        Test.stopTest();

        List<Generation_Unit__c> genUnits = testData.getGenUnits();
        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(13, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');

            ListMapContainer contractIdToGenUnitAssignments = new ListMapContainer(Generation_Unit_Assignment__c.SObjectType);
            for (Generation_Unit_Assignment__c assignmentItem : genUnit.Generation_Unit_Assignments__r) {
                contractIdToGenUnitAssignments.addToMap(assignmentItem.Contract__c, assignmentItem);
            }
            List<Generation_Unit_Assignment__c> earliestAssignments = contractIdToGenUnitAssignments.get(testData.earliestContract.Id);
            List<Generation_Unit_Assignment__c> earlyAssignments = contractIdToGenUnitAssignments.get(testData.earlyContract.Id);
            List<Generation_Unit_Assignment__c> currentAssignments = contractIdToGenUnitAssignments.get(testData.currentContract.Id);
            List<Generation_Unit_Assignment__c> laterAssignments = contractIdToGenUnitAssignments.get(testData.laterContract.Id);

            System.assertEquals(1, earliestAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.earliestContract.Start_Date__c, earliestAssignments[0].Start_Date__c);
            System.assertEquals(testData.earliestContract.End_Date__c, earliestAssignments[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, earliestAssignments[0].Generation_Unit_Ownership__r.Asset_Owner__c);

            System.assertEquals(3, earlyAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.earlyContract.Start_Date__c, earlyAssignments[0].Start_Date__c);
            System.assertEquals(testData.earlyContract.Start_Date__c.addDays(4), earlyAssignments[0].End_Date__c);
            System.assertEquals(null, earlyAssignments[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.earlyContract.Start_Date__c.addDays(5), earlyAssignments[1].Start_Date__c);
            System.assertEquals(testData.earlyContract.End_Date__c.addDays(-5), earlyAssignments[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, earlyAssignments[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.earlyContract.End_Date__c.addDays(-4), earlyAssignments[2].Start_Date__c);
            System.assertEquals(testData.earlyContract.End_Date__c, earlyAssignments[2].End_Date__c);
            System.assertEquals(null, earlyAssignments[2].Generation_Unit_Ownership__c);

            System.debug('currentAssignments');
            System.debug(currentAssignments);
            System.assertEquals(7, currentAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, currentAssignments[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c, currentAssignments[0].End_Date__c);
            System.assertEquals(null, currentAssignments[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(1), currentAssignments[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(1), currentAssignments[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, currentAssignments[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addMonths(2).addDays(1), currentAssignments[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), currentAssignments[2].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, currentAssignments[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-4), currentAssignments[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-3), currentAssignments[3].End_Date__c);
            System.assertEquals(null, currentAssignments[3].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-2), currentAssignments[4].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-1), currentAssignments[4].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, currentAssignments[4].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c, currentAssignments[5].Start_Date__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(1), currentAssignments[5].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, currentAssignments[5].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(2), currentAssignments[6].Start_Date__c);
            System.assertEquals(null, currentAssignments[6].End_Date__c);
            System.assertEquals(null, currentAssignments[6].Generation_Unit_Ownership__c);

            System.assertEquals(2, laterAssignments.size(), 'Split was not as expected');
            System.assertEquals(testData.laterContract.Start_Date__c, laterAssignments[0].Start_Date__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(1), laterAssignments[0].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, laterAssignments[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.laterContract.Start_Date__c.addDays(2), laterAssignments[1].Start_Date__c);
            System.assertEquals(null, laterAssignments[1].End_Date__c);
            System.assertEquals(null, laterAssignments[1].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullOverlapUnfollowedOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullOverlapUnfollowedClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullOverlapUnfollowedClosedAndFollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addYears(1),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_DoubleOverlapClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(5),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_DoubleOverlapOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(5),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialUnfollowedOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialUnfollowedClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialThenBreakThenFollowedOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(10),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(9), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(10), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialThenBreakThenFollowedClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(10),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(9), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(10), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialThenFollowedOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_LeftOverlapPartialThenFollowedClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_RightClosedOverlapUnfollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_RightOpenOverlapUnfollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(2, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_RightOpenOverlapFollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(10),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(9), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(10), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_RightClosedOverlapFollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(10),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(9), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(10), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleWithEarlierAndBreakOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(2)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(4, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(2), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(3), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleWithEarlierAndBreakClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(2)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(4, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(2), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(3), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleWithEarlierNoBreakOpen() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_FullInsideSingleWithEarlierNoBreakClosed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_NoOwnership() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_BadDataIntersection() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.End_Date__c.addDays(5)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(3, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_TripleInClosedBreaks() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earliestOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(4)));
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(-3),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(5, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-4), genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-3), genUnit.Generation_Unit_Assignments__r[4].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[4].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[4].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_TripleInOpenBreaks() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earliestOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(4)));
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(-3),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(5, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-4), genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-3), genUnit.Generation_Unit_Assignments__r[4].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[4].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[4].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_TripleInClosedFollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, true);

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earliestOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(4)));
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    testData.currentContract.End_Date__c.addDays(-6)));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(-5),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(4, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-6), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.End_Date__c.addDays(-5), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(testData.currentContract.End_Date__c, genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_TripleInOpenFollowed() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.earliestOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(-6),
                    testData.currentContract.Start_Date__c.addDays(4)));
            ownerships.add(createOwnership(
                    testData.earlyOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(6),
                    null));
            ownerships.add(createOwnership(
                    testData.laterOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addDays(9),
                    null));
        }
        insert ownerships;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(4, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(4), genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.earliestOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(5), genUnit.Generation_Unit_Assignments__r[1].End_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[1].Generation_Unit_Ownership__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(6), genUnit.Generation_Unit_Assignments__r[2].Start_Date__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(8), genUnit.Generation_Unit_Assignments__r[2].End_Date__c);
            System.assertEquals(testData.earlyOwner.Id, genUnit.Generation_Unit_Assignments__r[2].Generation_Unit_Ownership__r.Asset_Owner__c);
            System.assertEquals(testData.currentContract.Start_Date__c.addDays(9), genUnit.Generation_Unit_Assignments__r[3].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[3].End_Date__c);
            System.assertEquals(testData.laterOwner.Id, genUnit.Generation_Unit_Assignments__r[3].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_NoEntryAssignment() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;
        delete [SELECT Id FROM Generation_Unit_Assignment__c];
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_SuperfluousAssignmentDeletion() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;

        List<Generation_Unit_Assignment__c> legacyAssignments = new List<Generation_Unit_Assignment__c>();
        for (Id genUnitId : testData.genUnitIds) {
            legacyAssignments.add(createAssignment(
                    testData.currentContract.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(1),
                    testData.currentContract.End_Date__c.addDays(2)
            ));
        }
        insert legacyAssignments;
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(1, genUnit.Generation_Unit_Assignments__r.size(), 'Split was not as expected');
            System.assertEquals(testData.currentContract.Start_Date__c, genUnit.Generation_Unit_Assignments__r[0].Start_Date__c);
            System.assertEquals(null, genUnit.Generation_Unit_Assignments__r[0].End_Date__c);
            System.assertEquals(testData.currentOwner.Id, genUnit.Generation_Unit_Assignments__r[0].Generation_Unit_Ownership__r.Asset_Owner__c);
        }
    }

    @IsTest
    private static void createAssignments_Test_SuperfluousAssignmentDeletionNoAssignmentsNoM2G() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;

        List<Generation_Unit_Assignment__c> legacyAssignments = new List<Generation_Unit_Assignment__c>();
        for (Id genUnitId : testData.genUnitIds) {
            legacyAssignments.add(createAssignment(
                    testData.currentContract.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(1),
                    testData.currentContract.End_Date__c.addDays(2)
            ));
        }
        insert legacyAssignments;
        delete [SELECT Id FROM Meter2GenerationUnitRelationship__c];
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(0, genUnit.Generation_Unit_Assignments__r.size(), 'Deletion was not as expected');
        }
    }

    @IsTest
    private static void createAssignments_Test_SuperfluousAssignmentDeletionNoAssignmentsNoMR() {
        disableTriggers();
        AssignmentTestData testData = test_Setup_Split(BATCH_SIZE, false);
        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Id genUnitId : testData.genUnitIds) {
            ownerships.add(createOwnership(
                    testData.currentOwner.Id,
                    genUnitId,
                    testData.currentContract.Start_Date__c.addYears(-1),
                    null));
        }
        insert ownerships;

        List<Generation_Unit_Assignment__c> legacyAssignments = new List<Generation_Unit_Assignment__c>();
        for (Id genUnitId : testData.genUnitIds) {
            legacyAssignments.add(createAssignment(
                    testData.currentContract.Id,
                    genUnitId,
                    testData.currentContract.End_Date__c.addDays(1),
                    testData.currentContract.End_Date__c.addDays(2)
            ));
        }
        insert legacyAssignments;
        delete [SELECT Id FROM MeterRegistration__c];
        enableTriggers();

        Test.startTest();

        BatchAssignGenerationUnits.assignGenerationUnits(testData.genUnitIds);

        Test.stopTest();
        List<Generation_Unit__c> genUnits = testData.getGenUnits();

        for (Generation_Unit__c genUnit : genUnits) {
            System.assertEquals(0, genUnit.Generation_Unit_Assignments__r.size(), 'Deletion was not as expected');
        }
    }

    private class AssignmentTestData {
        Account earliestOwner { get; set; }
        Account earlyOwner { get; set; }
        Account currentOwner { get; set; }
        Account laterOwner { get; set; }

        Contract__c earliestContract { get; set; }
        Contract__c earlyContract { get; set; }
        Contract__c currentContract { get; set; }
        Contract__c laterContract { get; set; }

        Meter__c earlyMeter { get; set; }
        Meter__c currentMeterBeforeClone { get; set; }
        Meter__c currentMeterAfterClone { get; set; }
        Meter__c laterMeter { get; set; }

        Set<Id> genUnitIds { get; set; }

        public AssignmentTestData() {
            genUnitIds = new Set<Id>();
        }

        public List<Generation_Unit__c> getGenUnits() {
            return [
                    SELECT Id, (
                            SELECT Id, Start_Date__c, End_Date__c, Contract__c,
                                    Generation_Unit_Ownership__c, Generation_Unit_Ownership__r.Asset_Owner__c
                            FROM Generation_Unit_Assignments__r
                            ORDER BY Start_Date__c ASC
                    )
                    FROM Generation_Unit__c
                    WHERE Id IN : this.genUnitIds
            ];
        }
    }


    private static AssignmentTestData test_Setup_Split(Integer batchSize, Boolean closed) {
        AssignmentTestData testData = new AssignmentTestData();

        List<Account> accounts = new List<Account>();
        testData.earliestOwner = createAccount('earliest Owner');
        accounts.add(testData.earliestOwner);
        testData.earlyOwner = createAccount('early Owner');
        accounts.add(testData.earlyOwner);
        testData.currentOwner = createAccount('current Owner');
        accounts.add(testData.currentOwner);
        testData.laterOwner = createAccount('later Owner');
        accounts.add(testData.laterOwner);
        insert accounts;

        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnits.add(createGenerationUnit('Unit ' + i));
        }
        insert gUnits;

        for (Generation_Unit__c genUnitItem : gUnits) {
            testData.genUnitIds.add(genUnitItem.Id);
        }

        List<Contract__c> contracts = new List<Contract__c>();
        testData.currentContract = createContract(twoYearsAgoEnd, inOneYearStart, testData.currentOwner.Id);
        contracts.add(testData.currentContract);
        insert contracts;

        Date endDate = null;
        if (closed) {
            endDate = testData.currentContract.End_Date__c;
        }

        List<Meter__c> meters = new List<Meter__c>();
        testData.currentMeterBeforeClone = createMeter('current before cloning Meter');
        meters.add(testData.currentMeterBeforeClone);
        insert meters;

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        meterRegs.add(createRegistration(
                testData.currentContract.Id,
                testData.currentMeterBeforeClone.Id,
                testData.currentContract.Start_Date__c,
                endDate,
                true));
        insert meterRegs;

        List<Meter2GenerationUnitRelationship__c> m2Gs = new List<Meter2GenerationUnitRelationship__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            m2Gs.add(createM2G(
                    testData.currentMeterBeforeClone.Id,
                    genUnitItem.Id,
                    testData.currentContract.Start_Date__c,
                    endDate,
                    false));
        }
        insert m2Gs;

        List<Generation_Unit_Assignment__c> legacyAssignments = new List<Generation_Unit_Assignment__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            legacyAssignments.add(createAssignment(
                    testData.currentContract.Id,
                    genUnitItem.Id,
                    testData.currentContract.Start_Date__c.addDays(-1),
                    testData.currentContract.End_Date__c
            ));
        }
        insert legacyAssignments;

        return testData;
    }

    private static AssignmentTestData test_Setup_MergeAndSplit(Integer batchSize) {

        AssignmentTestData testData = new AssignmentTestData();

        List<Account> accounts = new List<Account>();
        testData.earliestOwner = createAccount('earliest Owner');
        accounts.add(testData.earliestOwner);
        testData.earlyOwner = createAccount('early Owner');
        accounts.add(testData.earlyOwner);
        testData.currentOwner = createAccount('current Owner');
        accounts.add(testData.currentOwner);
        testData.laterOwner = createAccount('later Owner');
        accounts.add(testData.laterOwner);
        insert accounts;

        List<Generation_Unit__c> gUnits = new List<Generation_Unit__c>();
        for (Integer i = 0; i < batchSize; i++) {
            gUnits.add(createGenerationUnit('Unit Name that provokes a length overflow in the assignments to shorten ' + i));
        }
        insert gUnits;

        for (Generation_Unit__c genUnitItem : gUnits) {
            testData.genUnitIds.add(genUnitItem.Id);
        }

        List<Contract__c> contracts = new List<Contract__c>();
        testData.earliestContract = createContract(threeYearsAgoStart, threeYearsAgoEnd, testData.earliestOwner.Id);
        contracts.add(testData.earliestContract);
        testData.earlyContract = createContract(twoYearsAgoStart, twoYearsAgoEnd, testData.earlyOwner.Id);
        contracts.add(testData.earlyContract);
        testData.currentContract = createContract(twoYearsAgoEnd, inOneYearStart, testData.currentOwner.Id);
        contracts.add(testData.currentContract);
        testData.laterContract = createContract(inOneYearStart, inOneYearEnd, testData.laterOwner.Id);
        contracts.add(testData.laterContract);
        insert contracts;

        List<Generation_Unit_Ownership__c> ownerships = new List<Generation_Unit_Ownership__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            ownerships.add(createOwnership(testData.earliestOwner.Id, genUnitItem.Id, testData.earliestContract.Start_Date__c.addDays(-1), testData.earliestContract.End_Date__c));
            ownerships.add(createOwnership(testData.earlyOwner.Id, genUnitItem.Id, testData.earlyContract.Start_Date__c.addDays(5), testData.earlyContract.End_Date__c.addDays(-5)));
            ownerships.add(createOwnership(testData.earlyOwner.Id, genUnitItem.Id, testData.currentContract.Start_Date__c.addDays(1), null));
            ownerships.add(createOwnership(testData.currentOwner.Id, genUnitItem.Id, testData.currentContract.Start_Date__c.addDays(5), testData.currentContract.End_Date__c.addDays(-5)));
            ownerships.add(createOwnership(testData.currentOwner.Id, genUnitItem.Id, testData.currentContract.End_Date__c.addDays(-2), testData.currentContract.End_Date__c.addDays(-1)));
            ownerships.add(createOwnership(testData.laterOwner.Id, genUnitItem.Id, testData.laterContract.Start_Date__c, testData.laterContract.Start_Date__c.addDays(1)));
        }
        insert ownerships;

        List<Meter__c> meters = new List<Meter__c>();
        testData.earlyMeter = createMeter('early Meter');
        meters.add(testData.earlyMeter);
        testData.currentMeterBeforeClone = createMeter('current before cloning Meter');
        meters.add(testData.currentMeterBeforeClone);
        testData.currentMeterAfterClone = createMeter('current after cloning Meter');
        meters.add(testData.currentMeterAfterClone);
        testData.laterMeter = createMeter('later Meter');
        meters.add(testData.laterMeter);
        insert meters;

        List<MeterRegistration__c> meterRegs = new List<MeterRegistration__c>();
        meterRegs.add(createRegistration(
                testData.earliestContract.Id,
                testData.earlyMeter.Id,
                testData.earliestContract.Start_Date__c,
                testData.earliestContract.End_Date__c,
                true));
        meterRegs.add(createRegistration(
                testData.earlyContract.Id,
                testData.earlyMeter.Id,
                testData.earlyContract.Start_Date__c,
                testData.earlyContract.End_Date__c,
                true));
        meterRegs.add(createRegistration(
                testData.currentContract.Id,
                testData.currentMeterBeforeClone.Id,
                testData.currentContract.Start_Date__c,
                testData.currentContract.Start_Date__c.addMonths(2),
                true));
        meterRegs.add(createRegistration(
                testData.currentContract.Id,
                testData.currentMeterAfterClone.Id,
                testData.currentContract.Start_Date__c.addMonths(2).addDays(1),
                testData.currentContract.End_Date__c,
                false));
        meterRegs.add(createRegistration(
                testData.currentContract.Id,
                testData.currentMeterAfterClone.Id,
                testData.currentContract.Start_Date__c.addMonths(2).addDays(2),
                null,
                true));
        meterRegs.add(createRegistration(
                testData.laterContract.Id,
                testData.laterMeter.Id,
                testData.laterContract.Start_Date__c,
                null,
                true));
        insert meterRegs;

        List<Meter2GenerationUnitRelationship__c> m2Gs = new List<Meter2GenerationUnitRelationship__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            m2Gs.add(createM2G(
                    testData.earlyMeter.Id,
                    genUnitItem.Id,
                    testData.earliestContract.Start_Date__c,
                    testData.earliestContract.End_Date__c,
                    false));
            m2Gs.add(createM2G(
                    testData.earlyMeter.Id,
                    genUnitItem.Id,
                    testData.earlyContract.Start_Date__c,
                    testData.earlyContract.End_Date__c,
                    false));
            m2Gs.add(createM2G(
                    testData.currentMeterBeforeClone.Id,
                    genUnitItem.Id,
                    testData.currentContract.Start_Date__c,
                    testData.currentContract.Start_Date__c.addDays(1),
                    false));
            m2Gs.add(createM2G(
                    testData.currentMeterAfterClone.Id,
                    genUnitItem.Id,
                    testData.currentContract.Start_Date__c.addDays(2),
                    null,
                    true));
            m2Gs.add(createM2G(
                    testData.laterMeter.Id,
                    genUnitItem.Id,
                    testData.laterContract.Start_Date__c,
                    testData.laterContract.End_Date__c,
                    false));
            m2Gs.add(createM2G(
                    testData.laterMeter.Id,
                    genUnitItem.Id,
                    testData.laterContract.Start_Date__c,
                    null,
                    false));
            m2Gs.add(createM2G(
                    testData.laterMeter.Id,
                    genUnitItem.Id,
                    testData.laterContract.Start_Date__c.addDays(2),
                    null,
                    false));
        }
        insert m2Gs;

        List<Generation_Unit_Assignment__c> legacyAssignments = new List<Generation_Unit_Assignment__c>();
        for (Generation_Unit__c genUnitItem : gUnits) {
            legacyAssignments.add(createAssignment(
                    testData.earlyContract.Id,
                    genUnitItem.Id,
                    testData.earlyContract.Start_Date__c,
                    testData.earlyContract.End_Date__c
            ));
        }
        insert legacyAssignments;

        return testData;
    }

    private static Account createAccount(String nameEntry) {
        return new Account (
                Name = nameEntry,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials');
    }

    private static Generation_Unit__c createGenerationUnit(String nameEntry) {
        return new Generation_Unit__c(
                Name = nameEntry,
                Annual_Production__c = 0,
                Installed_Capacity__c = 0,
                Country__c = 'Germany'
        );
    }

    private static Generation_Unit_Ownership__c createOwnership(Id accountId, Id genUnitId, Date startDate, Date endDate) {
        return new Generation_Unit_Ownership__c(
                Asset_Owner__c = accountId,
                Generation_Unit__c = genUnitId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }

    private static Contract__c createContract(Date startDate, Date endDate, Id contractHolder) {
        String status = 'Active';
        if (endDate < today) {
            status = 'Expired';
        } else if (today < startDate) {
            status = 'Draft';
        }
        return new Contract__c(
                Start_Date__c = startDate,
                End_Date__c = endDate,
                Status__c = status,
                Approved__c = true,
                Contract_Holder__c = contractHolder,
                Name = 'Will be overwritten',
                RecordTypeId = '0121v00000034VoAAI',
                Country__c = 'Germany',
                Contracted_Capacity__c = 0,
                Contracted_Annual_Production__c = 0
        );
    }

    private static Meter__c createMeter(String nameEntry) {
        return new Meter__c(
                Name = nameEntry,
                Alternative_Meter_ID__c = '12345678901',
                Country__c = 'Germany'
        );
    }

    private static MeterRegistration__c createRegistration(Id contractId, Id meterId, Date startDate, Date endDate, Boolean active) {
        return new MeterRegistration__c (
                Name = 'MeterReg',
                Contract__c = contractId,
                Meter__c = meterId,
                Volume_Share__c = 100,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private static Meter2GenerationUnitRelationship__c createM2G(Id meterId, Id genUnitId, Date startDate, Date endDate, Boolean active) {
        return new Meter2GenerationUnitRelationship__c(
                Name = 'Test Name Over 10',
                Generator_Unit__c = genUnitId,
                Meter__c = meterId,
                Valid_from__c = startDate,
                Valid_to__c = endDate,
                Active__c = active,
                Country__c = 'Germany');
    }

    private static Generation_Unit_Assignment__c createAssignment(Id contractId, Id genUnitId, Date startDate, Date endDate) {
        return new Generation_Unit_Assignment__c(
                Contract__c = contractId,
                Generation_Unit__c = genUnitId,
                Start_Date__c = startDate,
                End_Date__c = endDate
        );
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.disableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.disableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.disableObject(Generation_Unit_Ownership__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
        TriggerHandlerExtension.enableObject(Meter2GenerationUnitRelationship__c.SObjectType);
        TriggerHandlerExtension.enableObject(MeterRegistration__c.SObjectType);
        TriggerHandlerExtension.enableObject(Generation_Unit_Ownership__c.SObjectType);
    }
}