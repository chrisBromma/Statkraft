/**
 * Created by u52448 on 21.02.2021.
 */

@IsTest
private class msSolarOnboardingControllerTest {

    static final String FRAMEWORK_AGREEMENT_CONTRACT_TYPE = 'Framework Agreement';
    static final String WHITE_LBL_PROD_TYPE = 'White Label';
    static final Id PRICING_CMP_FIXED_FEE = SObjectType.Pricing_Component__c.getRecordTypeInfosByDeveloperName().get('Fixed_Fee').getRecordTypeId();

    @TestSetup
    private static void testSetup() {
        msTestDataFactory.createTestPortalContext();

        Account account = [SELECT Id FROM Account LIMIT 1];
        account.BvD_Catalyst_Status__c = 'Green';
        account.Catalyst_Company_ID__c = 'DE00000';
        update account;

        Contract__c parentWLContract = new Contract__c(
                RecordTypeId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Contract_PPA').getRecordTypeId(),
                Start_Date__c = Date.today().addDays(-20),
                End_Date__c = Date.today().addMonths(20),
                Contract_Holder__c = account.Id,
                Status__c = 'Active',
                Country__c = 'Germany',
                Approved__c = true,
                Name = 'ParentWLContract',
                Contract_Type_New__c = FRAMEWORK_AGREEMENT_CONTRACT_TYPE,
                Product_Type_New__c = WHITE_LBL_PROD_TYPE,
                Workflow_Type__c = 'New',
                Contract_Legal_Status__c = 'Standard Contract',
                Technology__c = 'Solar',
                Portal_PM__c = true
        );
        insert parentWLContract;

        Contact deContact = [SELECT Id, Name FROM Contact LIMIT 1];
        Contract_Role__c contractRole = new Contract_Role__c(
                RecordTypeId = msTestDataFactory.CONTRACT_ROLE_RECORD_TYPE,
                Role__c = 'Customer Portal',
                Contact__c = deContact.Id,
                Contract__c = parentWLContract.Id,
                Start_Date__c = parentWLContract.Start_Date__c,
                End_Date__c = parentWLContract.End_Date__c,
                Name='wlContractRole'
        );
        insert contractRole;

        Pricing_Component__c pc1 = new Pricing_Component__c(
                RecordTypeId = PRICING_CMP_FIXED_FEE,
                Name = 'WL pc 1',
                Contract__c = parentWLContract.Id,
                Value__c = 10,
                Start_Date__c = parentWLContract.Start_Date__c,
                End_Date__c = parentWLContract.End_Date__c
        );

        Pricing_Component__c pc2 = new Pricing_Component__c(
                RecordTypeId = PRICING_CMP_FIXED_FEE,
                Name = 'WL pc 2',
                Contract__c = parentWLContract.Id,
                Value__c = 20,
                Start_Date__c = parentWLContract.Start_Date__c,
                End_Date__c = parentWLContract.End_Date__c
        );

        List<Pricing_Component__c> pricingComponents = new List<Pricing_Component__c>{pc1, pc2};
        insert pricingComponents;

        Meter__c meter = new Meter__c(
                RecordTypeId = msUtility.METER_EXP_METER_REC_TYPE_ID,
                Status__c = 'Active',
                Name = 'solar meter',
                Country__c = 'Germany'
        );
        insert meter;

        Contract__c subContract = parentWLContract.clone(false, false, false, false);
        subContract.Name = 'sub-contract';
        subContract.Parent_Contract__c = parentWLContract.Id;
        subContract.Status__c = 'In Approval Process';
        subContract.Approved__c = false;
        subContract.Contract_Type_New__c = 'Sub-Contract';
        subContract.Legal_Capacity__c = 10;
        subContract.Start_Date__c = parentWLContract.Start_Date__c;
        subContract.End_Date__c = parentWLContract.End_Date__c;
        subContract.Country__c = 'Germany';
        subContract.Created_through_Portal__c = true;
        subContract.Portal_PM__c = true;
        insert subContract;

        MeterRegistration__c meterReg = new MeterRegistration__c (
                Name = 'MReg_',
                Contract__c = subContract.Id,
                Meter__c = meter.Id,
                Valid_from__c = Date.today(),
                Active__c = true,
                Country__c = 'Germany',
                Status__c = 'Completed'
        );
        insert meterReg;

        Blob file = Blob.valueOf('abc');
        ContentVersion v = new ContentVersion();
        v.VersionData = file;
        v.Title = 'SOFA_contract';
        v.PathOnClient ='/somepath.txt';
        insert v;

        v = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocumentLink testLink = new ContentDocumentLink();
        testLink.ContentDocumentId = v.ContentDocumentId;
        testLink.LinkedEntityId = subContract.Id;
        testLink.ShareType = 'I';
        insert testLink;
    }

    //GetPlantDetails tests
    @IsTest
    static void testGetPlantDetailsWhenMastrIdAlreadyExists() {

        String mastrId = 'SEE954519561531';
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        Meter__c solarMeter = new Meter__c(
                Name = 'SolarPlant1',
                Status__c = 'Active',
                Country__c = 'Germany',
                Marktstammdatenregister_ID__c = mastrId
        );
        insert solarMeter;

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.getPlantDetails(mastrId);
                System.assert(false);
            }
        } catch (AuraHandledException ex) {
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }
    }

    @IsTest
    static void testGetPlantDetailsWhenParentWLContractIsNotFound() {

        String mastrId = 'SE453453';
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuserOffice@statkraft.mindsquare.apex.testuser'];

        System.Test.startTest();

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.getPlantDetails(mastrId);
                System.assert(false);
            }
        } catch (AuraHandledException ex) {
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    @IsTest
    static void testGetPlantDetailsWhenMasterIdIsInvalid() {

        String mastrId = 'SE453453';
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();

        Test.setMock(WebServiceMock.class, new MockMastrWebService(false));

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.getPlantDetails(mastrId);
                System.assert(false);
            }
        } catch (AuraHandledException ex) {
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    @IsTest
    static void testGetPlantDetailsWhenMasterIdIsValid() {

        String mastrId = 'SEE906895175599';
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();

        Test.setMock(WebServiceMock.class, new MockMastrWebService(true));

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.PlantWrapper plantDetails = msSolarOnboardingController.getPlantDetails(mastrId);
                System.assertNotEquals(null, plantDetails);
            }
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    //savePlantDetails tests
    @IsTest
    static void testSavePlantDetailsWhenParentWLContractIsNotFound() {

        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.savePlantDetails(new msSolarOnboardingController.PlantDetails());
                System.assert(false);
            }
        } catch (AuraHandledException ex) {
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    @IsTest
    static void testSavePlantDetails() {

        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        System.Test.startTest();

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.savePlantDetails(getPlantDetails());
                System.assert(true);
            }
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    @IsTest
    static void testSavePlantDetailsWhenNewDsoIsEntered() {

        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];

        msSolarOnboardingController.PlantDetails plantDetails = getPlantDetails();
        plantDetails.networkOperator = 'other';
        plantDetails.networkOperatorId = 'other';
        plantDetails.otherNetworkOperator = 'New dso';

        System.Test.startTest();

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.savePlantDetails(plantDetails);
                System.assert(true);
            }
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    @IsTest
    static void testGetPlantsDatatableInfos(){
        User testUser = [SELECT Id FROM User WHERE Username = 'DEtestuser@statkraft.mindsquare.apex.testuser.statkraftportal'];
        Contract__c subContract = [SELECT Id from Contract__c where Contract_Type_New__c = 'Sub-Contract' LIMIT 1];

        System.Test.startTest();

        try {
            System.runAs(testUser) {
                msSolarOnboardingController.getPlantsDatatableInfos(new Id[]{subContract.Id});
                System.assert(true);
            }
        } catch (Exception ex) {
            System.assert(false);
        }

        System.Test.stopTest();
    }

    private static msSolarOnboardingController.PlantDetails getPlantDetails() {
        msSolarOnboardingController.PlantDetails plantDetails = new msSolarOnboardingController.PlantDetails();
        Account controlArea = [SELECT Id, Name FROM Account LIMIT 1];

        //Plant Info
        plantDetails.plantStatus = 'inOperation';
        plantDetails.mastrId = 'SEE908991342508';
        plantDetails.plantName = 'Strommax';
        plantDetails.projectNumber = null;
        plantDetails.meterRegistrationStatus = 'Completed';
        plantDetails.meterRegistrationValidFrom = Date.today();
        plantDetails.contractStartDate = Date.today().addDays(-20);
        plantDetails.contractEndDate = Date.today().addMonths(20);

        //Mains Connection
        plantDetails.marketLocationId = '01234567890';
        plantDetails.measurementLocationId = 'DE0007054228100000007490581831S01';
        plantDetails.sharedMeteringPoint = false;
        plantDetails.otherUsersOnSameMeter = null;
        plantDetails.eegSystemKey = 'E317810100000000000044794SXX00001';
        plantDetails.networkOperator = controlArea.Name;
        plantDetails.networkOperatorId = controlArea.Id;
        plantDetails.otherNetworkOperator = null;
        plantDetails.controlArea = controlArea.Name;
        plantDetails.controlAreaId = controlArea.Id;

        //Tech Specs
        plantDetails.installedCapacityKw = '6.87';
        plantDetails.remoteControlSolution = 'BTC';
        plantDetails.inclinationAngle = '20.00';
        plantDetails.orientation = '45.00';
        plantDetails.traceability = false;
        plantDetails.radioReceiverInstalled = false;
        plantDetails.facilityType = 'Building Mounted Solar PV';

        //Compensation Data
        plantDetails.commissioningDate = Date.today();
        plantDetails.eegEligibilityDate = Date.today();
        plantDetails.spvName = 'Solar onboarding Account';

        //Geo Data
        plantDetails.street = 'Nordstrasse';
        plantDetails.postCode = '42327';
        plantDetails.city = 'Wuppertal';
        plantDetails.province = 'NordrheinWestfalen';
        plantDetails.country = 'Deutschland';
        plantDetails.longitude = 0;
        plantDetails.latitude = 0;

        //battery info
        plantDetails.haveBattery = true;
        plantDetails.batteryManufacturer = 'LG';
        plantDetails.batteryModel = 'LG200';
        plantDetails.installedBatteryCapacity = '20';
        plantDetails.plannedBatteryUsage = Date.today();
        plantDetails.OtherBatteryInfos = 'Li-ion battery';

        return plantDetails;
    }
}