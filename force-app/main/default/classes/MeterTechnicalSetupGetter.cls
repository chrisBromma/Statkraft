public without sharing class MeterTechnicalSetupGetter {
    public static final String DEFAULT_FIELDS_METERREGISTRATION = 'Id, Meter__c, Balancing_Circle__c, Valid_From__c, Valid_To__c, Is_Valid__c';
    public static final String DEFAULT_FIELDS_METER = 'Id, Parent_Meter__c,Tertiary_Reserve__c, Prequalified_Secondary_Reserve_Capacity__c';
    public static final String DEFAULT_FIELDS_GENERATION_UNIT = 'Id, Virtual_Power_Plant_Date__c,VPP_Control_Mode__c,VPP_Controle_mode_BLOCK__c, Control_Circuit_Id__c';

    

    public static Map<Id, MeterTechnicalSetupWrapper> getMeterStructureByMeterId(Set<Id> meterIDs) {
        return getMeterStructureByMeterId(
            meterIds,
            DEFAULT_FIELDS_METER,
            DEFAULT_FIELDS_METERREGISTRATION,
            DEFAULT_FIELDS_GENERATION_UNIT
        );
    }

    /**
     * Used to fill blanks that result from certain Meters not being qualified for VPP Control Mode calculation1
     * @author Dennis Grzyb | 2022-01-11
     * @param meterId
     * @return MeterTechnicalSetupWrapper
     **/
    public static MeterTechnicalSetupWrapper getEmptyWrapper(id meterId) {
        MeterTechnicalSetupWrapper wrapper = new MeterTechnicalSetupWrapper();
        wrapper.meter = new Meter__c(Id = meterId);
        wrapper.type = 'empty';
        return wrapper;
    }

    public static Map<Id, MeterTechnicalSetupWrapper> getMeterStructureByMeterId(
        Set<Id> meterIds,
        String meterFields,
        String meterRegistrationFields,
        String generationUnitFields
    ) {
        Map<Id, MeterTechnicalSetupWrapper> mapIdToSetupWrapper = new Map<Id, MeterTechnicalSetupWrapper>();
        String m2gfields = relateGuFieldsToM2G(generationUnitFields);
        Map<Id, Id> mapToParentId = new Map<Id, Id>();
        Set<Id> qualifiedMeterIds = new Set<Id>();

        //First we qualify both Export and Sub-Meters by querying for Id OR Parent_Meter__c IN :meterIds. That way we have only valid inputs for the rest of the process.
        String queryQualifiedExportMeters =
            'SELECT ' +
            DEFAULT_FIELDS_METER +
            ' FROM Meter__c WHERE Id IN (SELECT Meter__c FROM MeterRegistration__c WHERE Is_Valid__c = true) AND Id IN (SELECT Meter__c FROM Meter2GenerationUnitRelationship__c WHERE Is_Valid__c = true) AND (Id IN :meterIds OR Parent_Meter__c IN :meterIds)';
        List<Meter__c> qualifiedExportMeters = Database.query(queryQualifiedExportMeters);
        for (Meter__c meter : qualifiedExportMeters) {
            String importedType = handleAddToSetupMap(mapIdToSetupWrapper, meter);
            qualifiedMeterIds.add(meter.Id);
            if (importedType == 'Shared') {
                qualifiedMeterIds.add(meter.Parent_Meter__c);
                mapToParentId.put(meter.Id, meter.Parent_Meter__c);
            } else {
                mapToParentId.put(meter.Id, meter.Id);
            }
        }

        String meterRegistrationQuery =
            'SELECT ' +
            meterRegistrationFields +
            ' FROM MeterRegistration__c WHERE Is_Valid__c = true AND Meter__c IN :qualifiedMeterIds';
        List<MeterRegistration__c> currentlyValidMeterRegistrations = Database.query(meterRegistrationQuery);
        for (MeterRegistration__c mReg : currentlyValidMeterRegistrations) {
            MeterTechnicalSetupWrapper setupWrapper = mapIdToSetupWrapper.get(mapToParentId.get(mReg.Meter__c));
            if (setupWrapper == null) {
                continue;
            }
            if (setupWrapper.meter.Id == mReg.Meter__c) {
                setupWrapper.meterRegistration = mReg;
            } else {
                setupWrapper.submeterMap.get(mReg.Meter__c).meterRegistration = mReg;
            }
            mapIdToSetupWrapper.put(mapToParentId.get(mReg.Meter__c), setupWrapper);
        }

        String m2gQuery =
            'SELECT ' +
            m2gfields +
            ' FROM Meter2GenerationUnitRelationship__c WHERE Is_Valid__c = true AND Meter__c IN :qualifiedMeterIds';
        List<Meter2GenerationUnitRelationship__c> validM2Gs = Database.query(m2gQuery);
        for (Meter2GenerationUnitRelationship__c m2g : validM2Gs) {
            MeterTechnicalSetupWrapper setupWrapper = mapIdToSetupWrapper.get(mapToParentId.get(m2g.Meter__c));
            if (setupWrapper.meter.Id == m2g.Meter__c) {
                setupWrapper.generationUnits.add(m2g.Generator_Unit__r);
            } else {
                setupWrapper.submeterMap.get(m2g.Meter__c).generationUnits.add(m2g.Generator_Unit__r);
            }
            mapIdToSetupWrapper.put(mapToParentId.get(m2g.Meter__c), setupWrapper);
        }

        for (Id meterId : mapIdToSetupWrapper.keySet()) {
            MeterTechnicalSetupWrapper setupWrapper = mapIdToSetupWrapper.get(meterId);
            setupWrapper.subMeters = setupWrapper.subMeterMap.values();
            mapIdToSetupWrapper.put(meterId, setupWrapper);
        }
        return mapIdToSetupWrapper;
    }

    private static String handleAddToSetupMap(Map<Id, MeterTechnicalSetupWrapper> setupMap, Meter__c meter) {
        Id parentId = meter.Id;
        String type = 'Export';
        if (meter.Parent_Meter__c != null) {
            type = 'Shared';
            parentId = meter.Parent_Meter__c;
        }

        MeterTechnicalSetupWrapper exportWrapper = new MeterTechnicalSetupWrapper();
        exportWrapper.type = type;

        if (setupMap.containsKey(parentId)) {
            exportWrapper = setupMap.get(parentId);
        }

        if (type == 'Shared') {
            exportWrapper.meter = new Meter__c(Id = meter.Parent_Meter__c);
            addSubmeterToSetup(exportWrapper, meter);
        } else {
            exportWrapper.meter = meter;
        }

        setupMap.put(parentId, exportWrapper);
        return type;
    }

    private static void addSubmeterToSetup(MeterTechnicalSetupWrapper exportWrapper, Meter__c meter) {
        MeterTechnicalSetupWrapper subMeter = new MeterTechnicalSetupWrapper();
        subMeter.type = 'Export';
        subMeter.meter = meter;
        exportWrapper.submeterMap.put(meter.Id, subMeter);
    }

    private static String relateGuFieldsToM2G(String generationUnitFields) {
        List<String> fields = generationUnitFields.split(',');
        List<String> newFields = new List<String>();
        for (String field : fields) {
            String newField = 'Generator_Unit__r.' + field.trim();
            newFields.add(newField);
        }
        newFields.add('Meter__c');
        return String.join(newFields, ',');
    }
}