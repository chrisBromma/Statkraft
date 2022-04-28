/**
 * Created by Steffen Naundorf on 29.09.2021.
 */
@IsTest
public without sharing class OfferGenerationDashboardControllerTest {

    @IsTest(SeeAllData=true)//Calm down! I'm querying for Reports and I have no idea on how to create Reports in Apex ;)
    public static void testGetReports() {
        Test.startTest();
        List<Report>reports = OfferGenerationDashboardController.getReports();
        Test.stopTest();

        System.assert(reports.size() > 0);
    }

    @IsTest(SeeAllData=true)//Same as above. I'm working with Reports which can't be created via Apex (easily)
    public static void testCreateOffer() {
        Test.startTest();
        List<Report> reports = OfferGenerationDashboardController.getReports();
        for (Report report : reports) {
            OfferGenerationDashboardController.ReportWrapper result = OfferGenerationDashboardController.getReportMetadata(report.Id);
            if (result.data.size() > 0) {
                OfferGenerationDashboardController.createOffers(new List<OfferGenerationDashboardController.DataRow>{result.data[0]}, 'myOppName');
                System.assert(result.data[0].contractId!=null);
            }
        }

        Test.stopTest();
    }
}