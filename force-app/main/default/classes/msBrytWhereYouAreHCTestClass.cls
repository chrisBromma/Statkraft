/****************************************************************************************************
* Class msBrytWhereYouAreHCTestClass
*
*   Create By	:   Fabian Kramer (mindsquare GmbH)
*   Create Date	:   07.03.2019
*   Description	:	Test for msBrytWhereYouAreHCBEC
* 	Coverage:       100%
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	    Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Fabian Kramer (mindsquare GmbH)		07.03.2019       	Init version.
*****************************************************************************************************/

@IsTest private with sharing class msBrytWhereYouAreHCTestClass {

    @TestSetup
    private static void createTestData() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    private static void createMonthWrappersTest() {
        User testUser = [SELECT Id FROM User WHERE Username='testuser@statkraft.mindsquare.user.dev'];

        Map<String,HttpResponse> endpointToResponseMap = new Map<String, HttpResponse>();
        String startDateThisMonth = String.valueOf(Datetime.newInstance(Date.today().toStartOfMonth(),Time.newInstance(0,0,0,0))).replace(' ','T');
        String startDateMonthP1 = String.valueOf(Datetime.newInstance(Date.today().addMonths(1).toStartOfMonth(),Time.newInstance(0,0,0,0))).replace(' ','T');
        String startDateMonthP2 = String.valueOf(Datetime.newInstance(Date.today().addMonths(2).toStartOfMonth(),Time.newInstance(0,0,0,0))).replace(' ','T');
        HttpResponse responseSuccess = new msCalloutMock.MockResponseBuilder()
                .setBody('[{"id":"UKPower-2020-Aug-Base",' +
                        '"productName":"Aug 20",' +
                        '"startTime":"2020-07-31T22:00:00Z",' +
                        '"endTime":"2020-08-31T22:00:00Z",' +
                        '"startDate":"'+ startDateThisMonth+'",' +
                        '"endDate":"2020-08-31T00:00:00",' +
                        '"publishTime":"2020-07-14T07:55:21",' +
                        '"expiryTime":"2020-07-14T15:00:00Z",' +
                        '"isValid":true,' +
                        '"market":"UKPower",' +
                        '"source":"curve",' +
                        '"period":"Month",' +
                        '"shape":"Base",' +
                        '"bid":30.072684,' +
                        '"offer":32.072684},' +
                        '{"id":"UKPower-2020-Sep-Base",' +
                        '"productName":"Sep 20",' +
                        '"startTime":"2020-08-31T22:00:00Z",' +
                        '"endTime":"2020-09-30T22:00:00Z",' +
                        '"startDate":"'+ startDateMonthP1+'",' +
                        '"endDate":"2020-09-30T00:00:00",' +
                        '"publishTime":"2020-07-14T07:55:21",' +
                        '"expiryTime":"2020-07-14T15:00:00Z",' +
                        '"isValid":true,' +
                        '"market":"UKPower",' +
                        '"source":"curve",' +
                        '"period":"Month",' +
                        '"shape":"Base",' +
                        '"bid":33.45,' +
                        '"offer":35.45},' +
                        '{"id":"UKPower-2020-Oct-Base",' +
                        '"productName":"Oct 20",' +
                        '"startTime":"2020-09-30T22:00:00Z",' +
                        '"endTime":"2020-10-31T23:00:00Z",' +
                        '"startDate":"'+ startDateMonthP2+'",' +
                        '"endDate":"2020-10-31T00:00:00",' +
                        '"publishTime":"2020-07-14T07:55:21",' +
                        '"expiryTime":"2020-07-14T15:00:00Z",' +
                        '"isValid":true,' +
                        '"market":"UKPower",' +
                        '"source":"curve",' +
                        '"period":"Month",' +
                        '"shape":"Base",' +
                        '"bid":36.30,' +
                        '"offer":38.30}]')
                .build();
        endpointToResponseMap.put(msUtility.getMetadata().BrytWhereYouAreEndpoint__c, responseSuccess);
        Test.setMock(HttpCalloutMock.class, new msCalloutMock(endpointToResponseMap));
        System.runAs(testUser) {
            Test.startTest();
            for(Contract__c contractItem : msBrytUtility.getUserDetails().contracts) {
                msBrytWhereYouAreHCBEC.createMonthWrappers(contractItem.Id);
            }
            Test.stopTest();
        }
    }
}