@isTest
public with sharing class MeterTechnicalSetupGetterTest {
    @testSetup
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

    @isTest
    static void getMeterContextExportMeter() {
        Meter__c meter = [
            SELECT Id, Name
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Export_Meter' AND Name != 'Parent Meter'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<Id, MeterTechnicalSetupWrapper> setupWrappers = MeterTechnicalSetupGetter.getMeterStructureByMeterId(
            new Set<Id>(new List<Id>{ meter.Id })
        );
        MeterTechnicalSetupWrapper setupWrapper = setupWrappers.get(meter.Id);
        System.assertEquals(
            'Export',
            setupWrapper.type,
            'Meter Type was not determined correctly for Standalone Meter'
        );
    }

    @isTest
    static void getMeterContextSharedMeter() {
        Meter__c meter = [
            SELECT Parent_Meter__c
            FROM Meter__c
            WHERE RecordType.DeveloperName = 'Sub_Meter'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<Id, MeterTechnicalSetupWrapper> setupWrappers = MeterTechnicalSetupGetter.getMeterStructureByMeterId(
            new Set<Id>(new List<Id>{ meter.Parent_Meter__c })
        );
        MeterTechnicalSetupWrapper setupWrapper = setupWrappers.get(meter.Parent_Meter__c);
        System.assertEquals('Shared', setupWrapper.type, 'Meter Type was not determined correctly for Shared Meter');
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