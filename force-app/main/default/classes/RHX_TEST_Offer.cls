@isTest
public class RHX_TEST_Offer {
	@isTest static void RHX_Testmethod() {

        Opportunity offerRelatedOpp = new Opportunity();
        offerRelatedOpp.StageName ='Negotiation';
        offerRelatedOpp.CloseDate = Date.today()+7;
        offerRelatedOpp.Name = 'RHX Test Offer Opp';
        insert offerRelatedOpp;

        Offer__c testOffer = new Offer__c();
        testOffer.Opportunity__c = offerRelatedOpp.Id;
        insert testOffer;

        List<Offer__c> sourceList = new List<Offer__c>();
        sourceList.add(testOffer);
        
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}