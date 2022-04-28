/****************************************************************************************************
* Class OfferHandlerTest
*
*   Create By	:   Christian Gottlieb (mindsquare AG)
*   Create Date	:   2021-03-25
*   Description	:	---
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	                Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Christian Gottlieb (mindsquare AG)	            2021-03-25       	Init version.
*****************************************************************************************************/

@IsTest
private class OfferHandlerTest {
    private static final Date THIS_DAY = Date.today();
    private static final Id PC_CERTIFICATE_PRICE_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Pricing_Component__c', 'Certificate_Price').Id;
    private static final Id PC_FIXED_PRICE_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Pricing_Component__c', 'Fixed_Fee').Id;
    private static final Id OFFER_PPA_EXTENSION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Extension').Id;
    public static final Id OFFER_PPA_NEGOTIATION_REC_TYPE_ID =
            Application.RecordTypes.byDeveloperName('Offer__c', 'PPA_Negotiation').Id;
    public static Map<String, Schema.FieldSet> OFFER_FIELDSETS_BY_DEVELOPERNAME = 
            FieldSetCachedProvider.getBySObjectType(SObjectType.Offer__c);

    @IsTest
    private static void closeExtraordinary_singleTest_Insert() {
        Test.startTest();
        List<Offer__c> offers = createOfferClosureTestDataSet(1, 'Extraordinary', 'Closed Lost');
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        List<Pricing_Component__c> pcs = getUpdatedPCs(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
            System.assertEquals(offerItem.Contract_s_Termination_Reason__c, offerItem.Base_Contract__r.Contract_s_Termination_Reason__c);
            System.assertEquals(THIS_DAY, offerItem.Base_Contract__r.End_Date__c);
        }
        Integer counter = 0;
        for(Pricing_Component__c pcItem : pcs) {
            if(pcItem.End_Date__c == THIS_DAY) {
                counter++;
            }
        }
        System.assertEquals(2, counter);
    }

    @IsTest
    private static void closeExtraordinary_singleTest_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, 'Extraordinary', 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Lost';
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        List<Pricing_Component__c> pcs = getUpdatedPCs(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
            System.assertEquals(offerItem.Contract_s_Termination_Reason__c, offerItem.Base_Contract__r.Contract_s_Termination_Reason__c);
            System.assertEquals(THIS_DAY, offerItem.Base_Contract__r.End_Date__c);
        }
        Integer counter = 0;
        for(Pricing_Component__c pcItem : pcs) {
            if(pcItem.End_Date__c == THIS_DAY) {
                counter++;
            }
        }
        System.assertEquals(2, counter);
    }

    @IsTest
    private static void closeExtraordinary_bulkTest_Update() {
        Integer Bulk_Size = 5;
        disableTriggers();
        List<Offer__c> offers = createOfferClosureTestDataSet(Bulk_Size, 'Extraordinary', 'Document Generation');
        enableTriggers();
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Lost';
            offerItem.Resulting_Termination_Status__c = 'Terminated by customer';
            offerItem.Cancellation_Date__c = Date.today();
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        List<Pricing_Component__c> pcs = getUpdatedPCs(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
            System.assertEquals(offerItem.Contract_s_Termination_Reason__c, offerItem.Base_Contract__r.Contract_s_Termination_Reason__c);
            System.assertEquals(THIS_DAY, offerItem.Base_Contract__r.End_Date__c);
        }
        Integer counter = 0;
        for(Pricing_Component__c pcItem : pcs) {
            if(pcItem.End_Date__c == THIS_DAY) {
                counter++;
            }
        }
        System.assertEquals(Bulk_Size * 2, counter);
    }

    @IsTest
    private static void closeExtraordinary_singleTest_Undelete() {
        disableTriggers();
        List<Offer__c> offers = createOfferClosureTestDataSet(1, 'Extraordinary', 'Closed Lost');
        delete offers;
        enableTriggers();
        Test.startTest();
        undelete offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        List<Pricing_Component__c> pcs = getUpdatedPCs(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
            System.assertEquals(offerItem.Contract_s_Termination_Reason__c, offerItem.Base_Contract__r.Contract_s_Termination_Reason__c);
            System.assertEquals(THIS_DAY, offerItem.Base_Contract__r.End_Date__c);
        }
        Integer counter = 0;
        for(Pricing_Component__c pcItem : pcs) {
            if(pcItem.End_Date__c == THIS_DAY) {
                counter++;
            }
        }
        System.assertEquals(2, counter);
    }

    @IsTest
    private static void closeUnknown_singleTest_Insert() {
        Test.startTest();
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Closed Lost');
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
        }
    }

    @IsTest
    private static void closeUnknown_singleTest_Undelete() {
        disableTriggers();
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Closed Lost');
        delete offers;
        enableTriggers();
        Test.startTest();
        undelete offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
        }
    }

    @IsTest
    private static void closeUnknown_singleTest_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Lost';
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
        }
    }

    @IsTest
    private static void closeUnknown_bulkTest_Update() {
        Integer Bulk_Size = 5;
        disableTriggers();
        List<Offer__c> offers = createOfferClosureTestDataSet(Bulk_Size, 'Extraordinary', 'Document Generation');
        enableTriggers();
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Lost';
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        offers = getUpdatedOffers(offers);
        for(Offer__c offerItem : offers) {
            System.assertEquals(offerItem.Resulting_Termination_Status__c, offerItem.Base_Contract__r.Termination_Status__c);
            System.assertEquals(offerItem.Contract_s_Termination_Reason__c, offerItem.Base_Contract__r.Contract_s_Termination_Reason__c);
            System.assertEquals(THIS_DAY, offerItem.Base_Contract__r.End_Date__c);
        }
    }

    @IsTest
    private static void passHistoricalDataOnUpdateTest() {
        List<Id> offerIds = createHistoricalDataTestDataSet(1);
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < 1; i++) {
            contracts.add(new Contract__c(
                    Name = 'test' + i,
                    RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Holder__c = accountId,
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
        }
        insert contracts;

        List<Offer__c> offers = [SELECT Id FROM Offer__c WHERE Id IN :offerIds];

        Test.startTest();

        for (Integer i = 0; i < 1; i++) {
            offers[i].Resulting_Contract__c = contracts[i].Id;
        }
        update offers;

        Test.stopTest();

        ContentVersion historicalData = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Attachement_Type__c = 'Historical Data'
        ];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :historicalData.ContentDocumentId
        ];

        Set<Id> connectedSObjectIds = new Set<Id>();
        for (ContentDocumentLink establishedLink : establishedLinks) {
            connectedSObjectIds.add(establishedLink.LinkedEntityId);
        }
        for (Integer i = 0; i < 1; i++) {
            System.assert(connectedSObjectIds.contains(offers[i].Id));
            System.assert(connectedSObjectIds.contains(contracts[i].Id));
        }
    }

    @IsTest
    private static void passHistoricalDataOnUpdateBulkTest() {
        Integer Bulk_Size = 5;
        List<Id> offerIds = createHistoricalDataTestDataSet(Bulk_Size);
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < Bulk_Size; i++) {
            contracts.add(new Contract__c(
                    Name = 'test' + i,
                    RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Holder__c = accountId,
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
        }
        insert contracts;

        List<Offer__c> offers = [SELECT Id FROM Offer__c WHERE Id IN :offerIds];

        Test.startTest();

        for (Integer i = 0; i < Bulk_Size; i++) {
            offers[i].Resulting_Contract__c = contracts[i].Id;
        }
        update offers;

        Test.stopTest();

        ContentVersion historicalData = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Attachement_Type__c = 'Historical Data'
        ];
        List<ContentDocumentLink> establishedLinks = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :historicalData.ContentDocumentId
        ];

        Set<Id> connectedSObjectIds = new Set<Id>();
        for (ContentDocumentLink establishedLink : establishedLinks) {
            connectedSObjectIds.add(establishedLink.LinkedEntityId);
        }
        for (Integer i = 0; i < Bulk_Size; i++) {
            System.assert(connectedSObjectIds.contains(offers[i].Id));
            System.assert(connectedSObjectIds.contains(contracts[i].Id));
        }
    }

    @IsTest
    private static void cwv_singleTest_Negotiation_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Won';
            offerItem.Country__c = 'Germany';
            offerItem.RecordTypeId = OFFER_PPA_NEGOTIATION_REC_TYPE_ID;
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Negotiation').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
        }
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            update offers;
            System.assert(false, 'The Validation was not triggered');
        } catch (DmlException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            System.assert(false, 'The Validation was not the cause for the DML to fail as expected');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'The Validation was not triggered');
    }

    @IsTest
    private static void cwv_singleTest_Extension_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Won';
            offerItem.Country__c = 'Germany';
            offerItem.RecordTypeId = OFFER_PPA_EXTENSION_REC_TYPE_ID;
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Extension').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
        }
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            update offers;
            System.assert(false, 'The Validation was not triggered');
        } catch (DmlException e) {
            exceptionThrown = true;
        } catch (Exception e) {
            System.assert(false, 'The Validation was not the cause for the DML to fail as expected');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'The Validation was not triggered');
    }

    @IsTest
    private static void cwv_singleTest_Negotiation_Passes_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Won';
            offerItem.Country__c = 'Germany';
            offerItem.RecordTypeId = OFFER_PPA_NEGOTIATION_REC_TYPE_ID;
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        //No assert, we just want to ensure that the validation does not trigger here
    }

    @IsTest
    private static void cwv_singleTest_AutoExtension_Passes_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Won';
            offerItem.Country__c = 'Germany';
            offerItem.Workflow_Type__c = 'Auto-Extension';
            offerItem.RecordTypeId = OFFER_PPA_EXTENSION_REC_TYPE_ID;
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Extension').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Extension_FWA').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Negotiation').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
            for (Schema.FieldSetMember field : OFFER_FIELDSETS_BY_DEVELOPERNAME.get('cwv_PPA_Negotiation_FWA').getFields()) {
                offerItem.put(field.getFieldPath(), null);
            }
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        //No assert, we just want to ensure that the validation does not trigger here
    }

    @IsTest
    private static void cwv_singleTest_Negotiation_FrameworkAgreement_Passes_Update() {
        List<Offer__c> offers = createOfferClosureTestDataSet(1, null, 'Document Generation');
        for(Offer__c offerItem : offers) {
            offerItem.Status__c = 'Closed Won';
            offerItem.Country__c = 'Germany';
            offerItem.Contract_Type_New__c = 'Framework Agreement';
            offerItem.Workflow_Type__c = 'New';
            offerItem.RecordTypeId = OFFER_PPA_NEGOTIATION_REC_TYPE_ID;
        }
        Test.startTest();
        update offers;
        Test.stopTest();
        //No assert, we just want to ensure that the validation does not trigger here
    }

    private static List<Id> createHistoricalDataTestDataSet(Integer amountOfPathsToTrace) {

        Account testAccount = new Account(
                Name = 'Test Account DE',
                RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Sandbox_Migration_Id__c = 'Test Account DE'
        );
        insert testAccount;
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            contracts.add(new Contract__c(
                    Name = 'test' + i,
                    RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Holder__c = testAccount.Id,
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
        }
        insert contracts;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            opportunities.add(new Opportunity(
                    Name = 'test' + i,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    StageName = 'New',
                    CloseDate = THIS_DAY,
                    AccountId = testAccount.Id
            ));
        }
        insert opportunities;

        List<Offer__c> offers = new List<Offer__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            offers.add(new Offer__c(
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    Opportunity__c = opportunities[i].Id,
                    Resulting_Contract__c = contracts[i].Id,
                    Reason_Offer_Lost__c = 'Price',
                    RecordTypeId = OFFER_PPA_EXTENSION_REC_TYPE_ID,
                    Workflow_Type__c = 'Amendment',
                    Contract_End_Date_Offer__c = THIS_DAY,
                    Resulting_Termination_Status__c = 'Automatic yearly extension',
                    Contract_Start_Date_Offer__c = Date.today(),
                    Meter_Billing_Type__c = 'Regular',
                    Billing_Model_Redispatch__c = 'Spitz',
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Facility_Description__c = 'Anaerobic Digestion',
                    Technology__c = 'Biofuel',
                    Offer_Installed_Capacity__c = 10,
                    BTR_Role__c = false,
                    BTR__c = testAccount.Id,
                    EIV__c = testAccount.Id,
                    Risk_Premium_DE__c = 0
            ));
        }
        insert offers;

        ContentVersion historicalData = new ContentVersion(
                ContentLocation = 'S', // S specify this document is in SF, use E for external files
                PathOnClient = 'Test', // The files name, extension is very important here which will help the file in preview.
                Title = 'Historical_Data', // Display name of the files
                VersionData = EncodingUtil.base64Decode('010'), // converting your binary string to Blog
                Attachement_Type__c = 'Historical Data'
        );
        insert historicalData;
        historicalData = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :historicalData.Id];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            links.add(new ContentDocumentLink(
                    LinkedEntityId = offers[i].Id,
                    ContentDocumentId = historicalData.ContentDocumentId
            ));
        }
        insert links;

        List<Id> offerIds = new List<Id>();
        for (Offer__c offerItem : offers) {
            offerIds.add(offerItem.Id);
        }
        return offerIds;
    }

    private static List<Offer__c> createOfferClosureTestDataSet(Integer amountOfPathsToTrace, String terminationReason, String initialStatus) {

        Account testAccount = new Account(
                Name = 'Test Account DE',
                RecordTypeId = msTestDataFactory.DE_ACC_RECORD_TYPE,
                BillingCountry = 'Germany',
                Customer_Type__c = 'not yet identified',
                Customer_Segment_industry__c = 'Large industrials',
                Sandbox_Migration_Id__c = 'Test Account DE'
        );
        insert testAccount;
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            contracts.add(new Contract__c(
                    Name = 'test' + i,
                    RecordTypeId = msTestDataFactory.PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = THIS_DAY.addYears(-10),
                    End_Date__c = THIS_DAY.addYears(2),
                    Contract_Holder__c = testAccount.Id,
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    RED_Contract_ID__c = 'GermanTestContract1',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Settlement_SubModel__c = null
            ));
        }
        insert contracts;

        List<Pricing_Component__c> pcToInsert = new List<Pricing_Component__c>();
        for (Contract__c ctrItem : contracts) {
            pcToInsert.add(new Pricing_Component__c(
                    Name = 'fixed old',
                    Start_Date__c = ctrItem.Start_Date__c,
                    End_Date__c = ctrItem.Start_Date__c.addMonths(1),
                    RecordTypeId = PC_FIXED_PRICE_REC_TYPE_ID,
                    Contract__c = ctrItem.Id
            ));
            pcToInsert.add(new Pricing_Component__c(
                    Name = 'fixed new',
                    Start_Date__c = ctrItem.Start_Date__c.addMonths(1).addDays(1),
                    End_Date__c = ctrItem.End_Date__c,
                    RecordTypeId = PC_FIXED_PRICE_REC_TYPE_ID,
                    Contract__c = ctrItem.Id
            ));
            pcToInsert.add(new Pricing_Component__c(
                    Name = 'cert old',
                    Start_Date__c = ctrItem.Start_Date__c,
                    End_Date__c = ctrItem.Start_Date__c.addMonths(1),
                    RecordTypeId = PC_CERTIFICATE_PRICE_REC_TYPE_ID,
                    Contract__c = ctrItem.Id
            ));
            pcToInsert.add(new Pricing_Component__c(
                    Name = 'cert new',
                    Start_Date__c = ctrItem.Start_Date__c.addMonths(1).addDays(1),
                    End_Date__c = ctrItem.End_Date__c,
                    RecordTypeId = PC_CERTIFICATE_PRICE_REC_TYPE_ID,
                    Contract__c = ctrItem.Id
            ));
        }
        insert pcToInsert;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            opportunities.add(new Opportunity(
                    Name = 'test' + i,
                    Start_Date__c = THIS_DAY.addDays(-20),
                    End_Date__c = Date.newInstance(THIS_DAY.year(), 12, 31),
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    StageName = 'New',
                    CloseDate = THIS_DAY,
                    AccountId = testAccount.Id
            ));
        }
        insert opportunities;

        List<Offer__c> offers = new List<Offer__c>();
        for (Integer i = 0; i < amountOfPathsToTrace; i++) {
            offers.add(new Offer__c(
                    Contract_Type_New__c = 'Feed in Tariff PPA',
                    Product_Type_New__c = 'Direct Marketing',
                    Country__c = 'Germany',
                    Opportunity__c = opportunities[i].Id,
                    Contract_s_Termination_Reason__c = terminationReason,
                    Status__c = initialStatus,
                    Base_Contract__c = contracts[i].Id,
                    Reason_Offer_Lost__c = 'Price',
                    RecordTypeId = OFFER_PPA_EXTENSION_REC_TYPE_ID,
                    Workflow_Type__c = 'Amendment',
                    Contract_End_Date_Offer__c = THIS_DAY,
                    Cancellation_Date__c = Date.today(),
                    Resulting_Termination_Status__c = 'Terminated by customer',
                    Contract_Start_Date_Offer__c = Date.today(),
                    Meter_Billing_Type__c = 'Regular',
                    Billing_Model_Redispatch__c = 'Spitz',
                    Balancing_Model_Redispatch__c = 'Prognosemodell',
                    Signal_Routing_Redispatch__c = 'Aufforderungsfall',
                    Facility_Description__c = 'Anaerobic Digestion',
                    Technology__c = 'Biofuel',
                    Offer_Installed_Capacity__c = 10,
                    BTR_Role__c = false,
                    BTR__c = testAccount.Id,
                    EIV__c = testAccount.Id,
                    Risk_Premium_DE__c = 0
            ));
        }
        insert offers;

        return offers;
    }

    private static List<Offer__c> getUpdatedOffers(List<Offer__c> offers) {
        Set<Id> offerIds = new Set<Id>();
        for (Offer__c offerItem : offers) {
            offerIds.add(offerItem.Id);
        }
        return [
                SELECT Id, Resulting_Termination_Status__c,
                        Contract_End_Date_Offer__c, Base_Contract__r.End_Date__c,
                        Base_Contract__r.Termination_Status__c, Base_Contract__c,
                        Contract_s_Termination_Reason__c, Base_Contract__r.Contract_s_Termination_Reason__c
                FROM Offer__c
                WHERE Id IN :offerIds
        ];
    }
    private static List<Pricing_Component__c> getUpdatedPCs(List<Offer__c> offers) {
        Set<Id> contractIds = new Set<Id>();
        for (Offer__c offerItem : offers) {
            contractIds.add(offerItem.Base_Contract__c);
        }
        return [
                SELECT Id, End_Date__c, RecordTypeId, Contract__r.End_Date__c
                FROM Pricing_Component__c
                WHERE Contract__c IN :contractIds
                ORDER BY End_Date__c DESC
        ];
    }

    private static void disableTriggers() {
        TriggerHandlerExtension.disableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.disableObject(Contract__c.SObjectType);
    }

    private static void enableTriggers() {
        TriggerHandlerExtension.enableObject(Offer__c.SObjectType);
        TriggerHandlerExtension.enableObject(Contract__c.SObjectType);
    }
}