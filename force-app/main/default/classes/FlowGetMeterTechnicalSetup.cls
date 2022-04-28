public with sharing class FlowGetMeterTechnicalSetup {
    @InvocableMethod(label='Get Meter Technical Setup From Meter Id' category='Flow Toolbox')
    public static List<Output> getMeterTechnicalSetup(List<Input> inputList) {
        List<Output> resultList = new List<Output>();
        System.debug(inputList);
        String meterFields = inputList[0].meterFields;
        String meterRegistrationFields = inputList[0].meterRegistrationFields;
        String generationUnitFields = inputList[0].generationUnitFields;

        Boolean useNonDefaultValues = false;
        if (
            String.isNotBlank(meterFIelds) &&
            String.isNotBlank(meterRegistrationFields) &&
            String.isNotBlank(generationUnitFields)
        ) {
            useNonDefaultValues = true;
            //Ensure that we have all the necessary data for mapping
            if (!meterFIelds.containsIgnoreCase('Parent_Meter__c')) {
                meterFields += ',Parent_Meter__c';
            }
            if (!meterRegistrationFields.containsIgnoreCase('Meter__c')) {
                meterRegistrationFields += ',Meter__c';
            }
        }
        Set<Id> meterIds = new Set<Id>();
        for (Input input : inputList) {
            meterIds.add(input.meterId);
        }

        Map<Id, MeterTechnicalSetupWrapper> mapIdToSetupWrapper = new Map<Id, MeterTechnicalSetupWrapper>();
        if (useNonDefaultValues) {
            mapIdToSetupWrapper = MeterTechnicalSetupGetter.getMeterStructureByMeterId(
                meterIds,
                meterFIelds,
                meterRegistrationFields,
                generationUnitFields
            );
        } else {
            mapIdToSetupWrapper = MeterTechnicalSetupGetter.getMeterStructureByMeterId(meterIds);
        }

        for (Input i : inputList) {
            Output o = new Output();
            if (mapIdToSetupWrapper.containsKey(i.meterId)) {
                o.meterWrapper = mapIdToSetupWrapper.get(i.meterId);
            } else {
                o.meterWrapper = MeterTechnicalSetupGetter.getEmptyWrapper(i.meterId);
            }
            resultList.add(o);
        }

        return resultList;
    }

    public class Input {
        @InvocableVariable(label='1. [VARIABLE] Meter Id')
        public String meterId;

        @InvocableVariable(label='2. [CONSTANT] Fields to retrieve from Meter Level (Leave empty for Default)')
        public String meterFields;

        @InvocableVariable(
            label='3. [CONSTANT] Fields to retrieve from Meter Registration Level (Leave empty for Default)'
        )
        public String meterRegistrationFields;

        @InvocableVariable(label='4. [CONSTANT] Fields to retrieve from GU Level (Leave empty for Default)')
        public String generationUnitFields;
    }

    public class Output {
        @InvocableVariable(label='Resulting Meter Object')
        public MeterTechnicalSetupWrapper meterWrapper;
    }
}