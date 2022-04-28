/****************************************************************************************************
* Class msPricingComponentHandlerTest
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   09.01.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   09.01.2019      	    Init version.
*****************************************************************************************************/

@IsTest
public with sharing class msPricingComponentHandlerTest {

    public static final Id FLOATING_ENERGY_PRICE_REC_TYPE_ID =
            Schema.SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Floating_Energy_Price').getRecordTypeId();
    public static final String PPA_CONTRACT_RECORD_TYPE =
            Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId();


    @TestSetup
    static void testSetup() {
        msBrytTestDataFactory.createTestRecords();
    }

    @IsTest
    static void testInsertMeritOrder() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, End_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Contract__c testContract=new Contract__c();
            testContract.Id=testPC.Contract__c;
            testContract.Contract_Type_New__c='Merchant PPA';
            testContract.Product_Type_New__c='Fixed Price w/GOO';
            update testContract;
            
            Pricing_Component__c testPC1 = new Pricing_Component__c();
            testPC1.Start_Date__c = testPC.Start_Date__c;
            testPC1.End_Date__c = testPC.End_Date__c;
            testPC1.Name = 'Test Price Component Factory to high';
            testPC1.Fixed_Volume__c = 99999;
            testPC1.Value__c = 1;
            testPC1.Index_Price__c = 'APX RPD';
            testPC1.Contract__c = testPC.Contract__c;
            testPC1.Settlement_Model__c='Product C';
            testPC1.RecordTypeId=FLOATING_ENERGY_PRICE_REC_TYPE_ID;
           
            insert testPC1;
            Pricing_Component__c testPCResult = [SELECT Id, Calc_Price_Downreg_EPEX_Negative__c, Calc_Price_Downreg_EPEX_Positive__c, Calc_Price_Prod_EPEX_Negative__c, Calc_Price_Prod_EPEX_Positive__c FROM Pricing_Component__c WHERE Id = :testPC1.Id];

            System.assertEquals(testPCResult.Calc_Price_Downreg_EPEX_Negative__c, 0);
            System.assertEquals(testPCResult.Calc_Price_Downreg_EPEX_Positive__c, 1);
            System.assertEquals(testPCResult.Calc_Price_Prod_EPEX_Negative__c, 0);
            System.assertEquals(testPCResult.Calc_Price_Prod_EPEX_Positive__c, 1);
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testInsert1() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, End_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Pricing_Component__c testPC1 = new Pricing_Component__c();
            testPC1.Start_Date__c = testPC.Start_Date__c;
            testPC1.End_Date__c = testPC.End_Date__c;
            testPC1.Name = 'Test Price Component Factory to high';
            testPC1.Fixed_Volume__c = 99999;
            testPC1.Value__c = 1;
            testPC1.Index_Price__c = 'APX RPD';
            testPC1.Contract__c = testPC.Contract__c;
            try {
                insert testPC1;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Capacity exceeded') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testInsert2() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, End_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Pricing_Component__c testPC2 = new Pricing_Component__c();
            testPC2.Start_Date__c = testPC.Start_Date__c;
            testPC2.End_Date__c = testPC.End_Date__c;
            testPC2.Name = 'Test Price Component Factory to low';
            testPC2.Fixed_Volume__c = -99999;
            testPC2.Value__c = 1;
            testPC2.Index_Price__c = 'APX RPD';
            testPC2.Contract__c = testPC.Contract__c;
            try {
                insert testPC2;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Capacity undercut') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }
    @IsTest
    static void testInsert3() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, End_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];
        Test.startTest();
        System.runAs(testUser) {
            Pricing_Component__c testPC3 = new Pricing_Component__c();
            testPC3.Start_Date__c = testPC.Start_Date__c.addDays(1);
            testPC3.End_Date__c = testPC.End_Date__c;
            testPC3.Name = 'Test Price Component Factory no ref Cap';
            testPC3.Fixed_Volume__c = 1;
            testPC3.Value__c = 1;
            testPC3.Index_Price__c = 'APX RPD';
            testPC3.Contract__c = testPC.Contract__c;
            try {
                insert testPC3;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Reference Capacity not found') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void editWorksTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            testPC.Fixed_Volume__c = 200;
            update testPC;
        }
        Test.stopTest();
    }

/* Cases not considered currently
    @IsTest
    static void deactivateTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            testPC.msBrytIsDeactivated__c = true;
            update testPC;
        }
        Test.stopTest();
    }

    @IsTest
    static void reactivateTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            testPC.msBrytIsDeactivated__c = true;
            update testPC;
            testPC.msBrytIsDeactivated__c = false;
            update testPC;
        }
        Test.stopTest();
    }*/

    @IsTest
    static void editExceedsTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            try {
                testPC.Fixed_Volume__c = 99999;
                update testPC;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Capacity exceeded') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void editUndercutsTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            try {
                testPC.Fixed_Volume__c = -99999;
                update testPC;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Capacity undercut') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void editNoCapacityTest() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            try {
                testPC.Fixed_Volume__c = 1;
                testPC.Start_Date__c = testPC.Start_Date__c.addDays(1);
                update testPC;
            } catch (Exception e) {
                Boolean expectedExceptionThrown = e.getMessage().contains('Reference Capacity not found') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testDelete() {
        User testUser = [SELECT Id, Name, ContactId FROM User WHERE Username = 'testuser@statkraft.mindsquare.user.dev'];
        Pricing_Component__c testPC = [SELECT Id, Start_Date__c, Contract__c, Fixed_Volume__c FROM Pricing_Component__c WHERE Name = 'Test Price Component Factory 1' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            delete testPC;
        }
        Test.stopTest();
    }

    @IsTest
    private static void testBlockOverlappingPCViaInsert() {
        Account testAccount = new Account();
        testAccount.Name = 'TestAccountTest';
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < 66; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+30),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract'
            ));
        }
        insert contractList;
        List<Pricing_Component__c> pricingComponentList = new List<Pricing_Component__c>();
        for (Integer i = 0; i < 33; i++) {
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+10),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc first' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(+11),
                    End_Date__c = Date.today().addDays(+21),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc second' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(+22),
                    End_Date__c = Date.today().addDays(+30),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc third' + i
            ));
        }
        for (Integer i = 33; i < 66; i++) {
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+10),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc first' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(+10),
                    End_Date__c = Date.today().addDays(+21),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc second' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(+21),
                    End_Date__c = Date.today().addDays(+30),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc third' + i
            ));
        }
        Test.startTest();
        List<Database.SaveResult> results = Database.insert(pricingComponentList,false);
        Test.stopTest();
        Integer successCount = 0;
        Integer failureCount = 0;
        for(Database.SaveResult result : results) {
            if(result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
            }
        }
        System.assertEquals(99, successCount, 'The amount of Pricing Components that are saved successfully is wrong');
        System.assertEquals(99, failureCount, 'The amount of Pricing Components that are blocked from saving is wrong');
    }

    @IsTest
    private static void testBlockOverlappingPCViaUpdate() {
        Account testAccount = new Account();
        testAccount.Name = 'TestAccountTest';
        testAccount.BillingCountry = 'Germany';
        testAccount.Customer_Type__c = 'not yet identified';
        testAccount.Customer_Segment_industry__c = 'Large industrials';
        insert testAccount;
        List<Contract__c> contractList = new List<Contract__c>();
        for (Integer i = 0; i < 66; i++) {
            contractList.add(new Contract__c(
                    RecordTypeId = PPA_CONTRACT_RECORD_TYPE,
                    Start_Date__c = Date.today().addDays(-20),
                    End_Date__c = Date.today().addDays(+30),
                    Contract_Holder__c = testAccount.Id,
                    Status__c = 'Active',
                    Country__c = 'Germany',
                    Approved__c = true,
                    Meter_Billing_Type__c = 'Sub-Meter Yearly',
                    Name = 'new Contract' + i,
                    RED_Contract_ID__c = 'new Contract'
            ));
        }
        insert contractList;
        List<Pricing_Component__c> pricingComponentList = new List<Pricing_Component__c>();
        for (Integer i = 0; i < 66; i++) {
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(-18),
                    End_Date__c = Date.today().addDays(9),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc first' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(12),
                    End_Date__c = Date.today().addDays(20),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc second' + i
            ));
            pricingComponentList.add(new Pricing_Component__c(
                    RecordTypeId = FLOATING_ENERGY_PRICE_REC_TYPE_ID,
                    Start_Date__c = Date.today().addDays(23),
                    End_Date__c = Date.today().addDays(28),
                    Contract__c = contractList[i].Id,
                    Country__c = 'Germany',
                    Name = 'new pc third' + i
            ));
        }
        insert pricingComponentList;

        for (Integer i = 0; i < 99; i++) {
            pricingComponentList[i].Start_Date__c = pricingComponentList[i].Start_Date__c.addDays(-1);
            pricingComponentList[i].End_Date__c = pricingComponentList[i].End_Date__c.addDays(1);
        }
        for (Integer i = 99; i < 198; i++) {
            pricingComponentList[i].Start_Date__c = pricingComponentList[i].Start_Date__c.addDays(-2);
            pricingComponentList[i].End_Date__c = pricingComponentList[i].End_Date__c.addDays(2);
        }
        Test.startTest();
        List<Database.SaveResult> results = Database.update(pricingComponentList,false);
        Test.stopTest();
        Integer successCount = 0;
        Integer failureCount = 0;
        for(Database.SaveResult result : results) {
            if(result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
            }
        }
        System.assertEquals(99, successCount, 'The amount of Pricing Components that are updated successfully is wrong');
        System.assertEquals(99, failureCount, 'The amount of Pricing Components that are blocked from update is wrong');
    }
}