public with sharing class FlowCreateDummySObjects {
    @InvocableMethod(
        label='Flow Tool: Create Hollow SObject Dummies from List of Lookup Ids'
        category='Flow Toolbox'
        )
    public static Output[] extractSObjects(Input[] input) {
        Output[] result = new List<Output>{};

        for (Input inputItem : input) {
            Output op = new Output();
            List<SObject> outputSObjects = new List<SObject>();
            List<Id> lookupIds = new List<Id>();

            for (SObject loopObj : inputItem.records) {
                lookupIds.add(String.valueOf(loopObj.get(inputItem.lookupIdField)));
            }

            if (!lookupIds.isEmpty()) {
                Set<Id> lookupIdSet = new Set<Id>(lookupIds);
                SObjectType sobjType = lookupIds[0].getSObjectType();
                for (Id lookupId : lookupIdSet) {
                    SObject sobj = sobjType.newSObject(lookupId);
                    outputSObjects.add(sobj);
                }
            }

            op.records = outputSObjects;
            result.add(op);
        }

        return result;
    }

    public class Input {
        @InvocableVariable(label='1. List to extract records from' required=true)
        public sObject[] records;

        @InvocableVariable(label='2. Lookup Field for your SObjects (e.g. "Meter__c" for extracting Meter from Meter_Registration__c' required=true)
        public String lookupIdField;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='List of Dummy SObjects')
        public Sobject[] records;
    }
}