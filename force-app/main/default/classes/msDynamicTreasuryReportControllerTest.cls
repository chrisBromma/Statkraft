/**
 * Created by Steffen Naundorf on 16.07.2021.
 */
@IsTest
public with sharing class msDynamicTreasuryReportControllerTest {
    @IsTest static void testDeletionOfEmailFeedItems() {

        Test.startTest();
        msDynamicTreasuryReportController.ReportWrapper result = msDynamicTreasuryReportController.getReportMetadata('00O1v000008dFM0EAM', 'USD', Date.today());
        Test.stopTest();

        System.assert(result.data.size() > 0);
    }
    @IsTest(SeeAllData = true) static void testGetReports(){
        //Needs SeeAllData = true because you can't mock reports
        Test.startTest();
        msDynamicTreasuryReportController.ReportSetup reportSetup = msDynamicTreasuryReportController.getReports();
        Test.stopTest();

        System.assert(reportSetup.reportMap.values().size() > 0);
    }
}