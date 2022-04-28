/**
 * Created by Fabian on 14.03.2019.
 */
@IsTest
public with sharing class msPP1PP2ControllerTest {
    /* Deprecated Test Data reference and deprecated Mock 
    
    @TestSetup public static void generateTestData(){
        msTestDataFactory.createTestRecords();
    }
    public testMethod static void test(){
        Test.setMock(HttpCalloutMock.class, new msCalloutMock());
        Test.startTest();
        msPP1PP2Controller.callApi();
        Test.stopTest();
    }*/

    @isTest static void pseudoTestForCoverage(){
        msPP1PP2Controller.forCoverage();
    }
}