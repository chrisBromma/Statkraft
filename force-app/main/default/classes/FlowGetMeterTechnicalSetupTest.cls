@isTest
public with sharing class FlowGetMeterTechnicalSetupTest {
    @TestSetup
    static void setup() {
        msTestDataFactory.createTestPortalContext();

        Meter__c parentMeter = createMeter('Parent Meter', null, 'Germany');
        insert parentMeter;

        Meter__c childMeter = createMeter('Child Meter', null, 'Germany');
        childMeter.RecordTypeId = Application.RecordTypes.byDeveloperName('Meter__c', 'Sub_Meter').Id;
        childMeter.Parent_Meter__c = parentMeter.Id;
        insert childMeter;

        Contract__c con = [SELECT Id FROM Contract__c WHERE Country__c = 'Germany' LIMIT 1];

        MeterRegistration__c meterReg = msGranularTestDataFactory.createTestMeterRegistrations(
            new List<Meter__c>{ childMeter }
        )[0];
        meterReg.Contract__c = con.Id;
        insert meterReg;

        List<Generation_Unit__c> generationUnits = msGranularTestDataFactory.createTestGenerationUnits(8, 'Germany');
        for (Generation_Unit__c gu : generationUnits) {
            gu.Name += 'DE';
            gu.Portfolio_ID__c += 'DE';
        }
        insert generationUnits;

        List<Meter2GenerationUnitRelationship__c> m2gs = msGranularTestDataFactory.createTestMeter2GURelationships(
            childMeter,
            generationUnits
        );
        insert m2gs;
    }

    @isTest static void testFlowInterviewWithAllTypes(){
        Meter__c newMeter = createMeter('Parent Meter 2', null, 'Germany');
        insert newMeter;

        List<FlowGetMeterTechnicalSetup.Input> interviewInputs = new List<FlowGetMeterTechnicalSetup.Input>();
        FlowGetMeterTechnicalSetup.Input nullInput = new FlowGetMeterTechnicalSetup.Input();
        nullInput.meterId = newMeter.Id;
        nullInput.meterRegistrationFields = 'Id, Meter__c, Balancing_Circle__c, Valid_From__c, Valid_To__c, Is_Valid__c';
        nullInput.meterFields = 'Id, Parent_Meter__c,Tertiary_Reserve__c, Prequalified_Secondary_Reserve_Capacity__c';
        nullInput.generationUnitFields = 'Id, Virtual_Power_Plant_Date__c,VPP_Control_Mode__c,VPP_Controle_mode_BLOCK__c, Control_Circuit_Id__c';
        interviewInputs.add(nullInput);
        
        List<Meter__c> standaloneMeters = [
            SELECT Id, Name
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Export_Meter' AND Name != 'Parent Meter'
            ORDER BY CreatedDate DESC
            LIMIT 2
        ];

        FlowGetMeterTechnicalSetup.Input standaloneInput = new FlowGetMeterTechnicalSetup.Input();
        standaloneInput.meterId = standaloneMeters[1].Id;
        
        interviewInputs.add(standaloneInput);

        Meter__c sharedMeter = [
            SELECT Parent_Meter__c
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Sub_Meter'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        FlowGetMeterTechnicalSetup.Input sharedInput = new FlowGetMeterTechnicalSetup.Input();
        sharedInput.meterId = sharedMeter.Parent_Meter__c;
        interviewInputs.add(sharedInput);

        List<FlowGetMeterTechnicalSetup.Output> interviewOutputs = FlowGetMeterTechnicalSetup.getMeterTechnicalSetup(interviewInputs);
        System.debug(JSON.serializePretty(interviewOutputs));
        System.assertEquals('empty',interviewOutputs[0].meterWrapper.type, 'Empty Technical Object not recognized');
        System.assertEquals('Export',interviewOutputs[1].meterWrapper.type, 'Export Technical Object not recognized');
        System.assertEquals('Shared',interviewOutputs[2].meterWrapper.type, 'Shared Technical Object not recognized');



    }

    @isTest static void testFlowInterviewWithAllTypes_CUSTOMINPUT(){
        Meter__c newMeter = createMeter('Parent Meter 2', null, 'Germany');
        insert newMeter;

        List<FlowGetMeterTechnicalSetup.Input> interviewInputs = new List<FlowGetMeterTechnicalSetup.Input>();
        FlowGetMeterTechnicalSetup.Input nullInput = new FlowGetMeterTechnicalSetup.Input();
        nullInput.meterId = newMeter.Id;
        interviewInputs.add(nullInput);
        
        List<Meter__c> standaloneMeters = [
            SELECT Id, Name
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Export_Meter' AND Name != 'Parent Meter'
            ORDER BY CreatedDate DESC
            LIMIT 2
        ];

        FlowGetMeterTechnicalSetup.Input standaloneInput = new FlowGetMeterTechnicalSetup.Input();
        standaloneInput.meterId = standaloneMeters[1].Id;
        interviewInputs.add(standaloneInput);

        Meter__c sharedMeter = [
            SELECT Parent_Meter__c
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Sub_Meter'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        FlowGetMeterTechnicalSetup.Input sharedInput = new FlowGetMeterTechnicalSetup.Input();
        sharedInput.meterId = sharedMeter.Parent_Meter__c;
        interviewInputs.add(sharedInput);

        List<FlowGetMeterTechnicalSetup.Output> interviewOutputs = FlowGetMeterTechnicalSetup.getMeterTechnicalSetup(interviewInputs);
        System.debug(JSON.serializePretty(interviewOutputs));
        System.assertEquals('empty',interviewOutputs[0].meterWrapper.type, 'Empty Technical Object not recognized');
        System.assertEquals('Export',interviewOutputs[1].meterWrapper.type, 'Export Technical Object not recognized');
        System.assertEquals('Shared',interviewOutputs[2].meterWrapper.type, 'Shared Technical Object not recognized');



    }

    private static Meter__c createMeter(String name, String Status, String country) {
        Meter__c newMeter = new Meter__c(
            Name = name,
            Status__c = Status,
            Alternative_Meter_ID__c = '12345678901',
            Country__c = country
        );
        return newMeter;
    }
}