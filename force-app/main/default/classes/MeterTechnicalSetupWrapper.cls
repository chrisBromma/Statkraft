public class MeterTechnicalSetupWrapper {
    @AuraEnabled
    public String type;

    @AuraEnabled
    public Meter__c meter;

    @AuraEnabled
    public List<Generation_Unit__c> generationUnits;

    @AuraEnabled
    public MeterRegistration__c meterRegistration;

    @AuraEnabled
    public List<MeterTechnicalSetupWrapper> submeters;

    public Map<Id, MeterTechnicalSetupWrapper> submeterMap;

    public MeterTechnicalSetupWrapper() {
        generationUnits = new List<Generation_Unit__c>();
        submeters = new List<MeterTechnicalSetupWrapper>();
        submeterMap = new Map<Id, MeterTechnicalSetupWrapper>();
    }
}