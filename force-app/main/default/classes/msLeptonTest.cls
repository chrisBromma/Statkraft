/****************************************************************************************************
* Class msLeptonTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-04-08
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-04-08       	Init version.
*****************************************************************************************************/

@IsTest
private class msLeptonTest {
    @IsTest
    static void flowObjectComposerTest() {
        List<Case> newCases = new List<Case>{
                new Case(Status = 'New')
        };
        Test.startTest();
        newCases = (List<Case>) msLepton.flowObjectComposer(newCases);
        Test.stopTest();
        //No assert possible, since we can't recreate the illegal flow SObject definitions in an IDE.
    }

    @IsTest
    static void setFieldsFromFieldSetTest() {
        List<Case> newCases = new List<Case>{
                new Case(Status = 'New')
        };
        Test.startTest();
        newCases = (List<Case>) msLepton.setFieldsFromFieldSet(newCases, new List<String>{
                'Subject', 'Status'
        });
        Test.stopTest();
        System.assertEquals(null, newCases[0].Subject);
    }

    @IsTest
    static void maxTests() {
        Date lower = Date.today().addDays(-1);
        Date higher = Date.today();
        Test.startTest();
        Date shouldBeHigher = msLepton.max(lower, higher);
        Date shouldBeHigherToo = msLepton.max(null, higher);
        Date shouldBeSymmetric = msLepton.max(higher, lower);
        Date shouldBeLower = msLepton.max(lower, null);
        Test.stopTest();
        System.assertEquals(higher, shouldBeHigher);
        System.assertEquals(higher, shouldBeHigherToo);
        System.assertEquals(higher, shouldBeSymmetric);
        System.assertEquals(lower, shouldBeLower);
    }

    @IsTest
    static void maxWithInfinityTests() {
        Date lower = Date.today().addDays(-1);
        Date higher = Date.today();
        Test.startTest();
        Date shouldBeHigher = msLepton.maxWithInfinity(lower, higher);
        Date shouldBeNull = msLepton.maxWithInfinity(null, higher);
        Date shouldBeSymmetric = msLepton.maxWithInfinity(higher, lower);
        Date shouldBeNullToo = msLepton.maxWithInfinity(lower, null);
        Test.stopTest();
        System.assertEquals(higher, shouldBeHigher);
        System.assertEquals(null, shouldBeNull);
        System.assertEquals(higher, shouldBeSymmetric);
        System.assertEquals(null, shouldBeNullToo);
    }

    @IsTest
    static void minTests() {
        Date lower = Date.today().addDays(-1);
        Date higher = Date.today();
        Test.startTest();
        Date shouldBeLower = msLepton.min(lower, higher);
        Date shouldBeHigher = msLepton.min(null, higher);
        Date shouldBeSymmetric = msLepton.min(higher, lower);
        Date shouldBeLowerToo = msLepton.min(lower, null);
        Test.stopTest();
        System.assertEquals(lower, shouldBeLower);
        System.assertEquals(higher, shouldBeHigher);
        System.assertEquals(lower, shouldBeSymmetric);
        System.assertEquals(lower, shouldBeLowerToo);
    }

    @IsTest
    static void checkDateIntersectionWithInfinityTest() {
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, null, null, null));
    }

    @IsTest
    static void addToMapTests() {
        Id randomId = UserInfo.getUserId();
        Map<Id, Set<Id>> mapIdSetId = new Map<Id, Set<Id>>();
        Map<Id, Set<String>> mapIdSetString = new Map<Id, Set<String>>();
        Map<Id, ListMapContainer> mapIdLMC = new Map<Id, ListMapContainer>();

        Test.startTest();

        msLepton.addToMap(randomId, randomId, mapIdSetId);
        msLepton.addToMap(randomId, 'test', mapIdSetString);
        msLepton.addToMap(randomId, randomId, new Account(), mapIdLMC);
        Test.stopTest();

        System.assert(mapIdSetString.get(randomId).contains('test'));
        System.assert(!mapIdLMC.get(randomId).get(randomId).isEmpty());
    }

    @IsTest
    static void castToSetId_Test() {
        Set<String> setOfStrings = new Set<String>();
        List<String> listOfStrings = new List<String>();
        setOfStrings.add('test');
        listOfStrings.add('test');
        setOfStrings.add(UserInfo.getUserId());
        listOfStrings.add(UserInfo.getUserId());

        Test.startTest();

        Set<Id> resultSet = msLepton.castToSetId(setOfStrings);
        Set<Id> resultList = msLepton.castToSetId(listOfStrings);
        Test.stopTest();

        System.assert(resultSet.contains(UserInfo.getUserId()), 'The set did not contain the valid Id entry');
        System.assert(resultList.contains(UserInfo.getUserId()), 'The set did not contain the valid Id entry');
    }

    @IsTest
    static void lastTest() {
        List<Integer> testList = new List<Integer>{
                1, 2, 3, 3, 3, 2
        };
        Test.startTest();
        Integer result = (Integer) msLepton.last(testList);
        Test.stopTest();
        System.assertEquals(2, result);
    }

    @IsTest
    static void formatTest() {
        Date today = Date.newInstance(1350, 05, 13);
        String dateFormatString = 'dd.MM.yyyy';
        Test.startTest();
        String result = msLepton.format(today, dateFormatString);
        Test.stopTest();
        System.assertEquals('13.05.1350', result, 'date not properly formatted');
    }

    @IsTest
    static void isLastTest() {
        List<Integer> emptyList = new List<Integer>();
        List<Integer> oneItemList = new List<Integer>{
                1350
        };
        System.assert(msLepton.isLast(-1, null));
        System.assert(msLepton.isLast(-1, emptyList));
        System.assert(!msLepton.isLast(0, emptyList));
        System.assert(msLepton.isLast(0, oneItemList));
        System.assert(!msLepton.isLast(1, oneItemList));
    }

    @IsTest
    static void checkDateIntersectionWithInfinity_Tests() {
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        Date yesterday = today.addDays(-1);
        //positives
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, today, null, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, null, tomorrow, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, null, null, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, null, null, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, null, today, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, tomorrow, null, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, tomorrow, today, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, null, null, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, null, today, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, tomorrow, today, null));
        System.assert(msLepton.checkDateIntersectionWithInfinity(null, tomorrow, today, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, tomorrow, null, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, tomorrow, yesterday, today));
        System.assert(msLepton.checkDateIntersectionWithInfinity(yesterday, today, today, tomorrow));
        System.assert(msLepton.checkDateIntersectionWithInfinity(yesterday, tomorrow, today, today));
        System.assert(msLepton.checkDateIntersectionWithInfinity(today, today, yesterday, tomorrow));
        //negatives
        System.assert(!msLepton.checkDateIntersectionWithInfinity(today, today, tomorrow, tomorrow));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(yesterday, today, tomorrow, tomorrow));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(tomorrow, tomorrow, today, today));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(null, today, tomorrow, tomorrow));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(today, today, tomorrow, null));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(null, yesterday, today, null));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(tomorrow, tomorrow, null, today));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(tomorrow, null, today, today));
        System.assert(!msLepton.checkDateIntersectionWithInfinity(tomorrow, null, null, today));
        //errors
        Boolean caught = false;
        try {
            msLepton.checkDateIntersectionWithInfinity(today, yesterday, null, null);
            System.assert(false, 'Should have thrown error');
        } catch (msLepton.msLeptonException e) {
            caught = true;
        } catch (Exception e) {
            System.assert(false, 'Should have thrown error');
        }
        System.assert(caught, 'Expected a different error');

        caught = false;
        try {
            msLepton.checkDateIntersectionWithInfinity(null, null, today, yesterday);
            System.assert(false, 'Should have thrown error');
        } catch (msLepton.msLeptonException e) {
            caught = true;
        } catch (Exception e) {
            System.assert(false, 'Should have thrown error');
        }
        System.assert(caught, 'Expected a different error');
    }

    @IsTest
    static void generateCommentFromSaveResultsTests() {
        List<User> currentUser = [SELECT Username FROM User WHERE Id = :UserInfo.getUserId()];
        List<Database.SaveResult> resultsSuccess = Database.update(currentUser);

        currentUser[0].Username = null;
        List<Database.SaveResult> resultsError = Database.update(currentUser, false);

        Test.startTest();
        String commentError = msLepton.generateCommentFromSaveResults(resultsError);
        String commentSuccess = msLepton.generateCommentFromSaveResults(resultsSuccess);
        Test.stopTest();

        System.assert(0 < commentError.length(), 'No error message generated');
        System.assert(commentError.contains(Label.batchLoggingErrorMessage), 'Comment does not generate error text');
        System.assert(0 < commentSuccess.length(), 'No success message generated');
        System.assertEquals(commentSuccess, Label.batchLoggingSuccessMessage, 'Comment does not generate success text');
    }
}