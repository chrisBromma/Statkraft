public class FlowMapGetValues {
    @InvocableMethod(label='Flow Tool: Get all records in a Map (Map.values())' category='Flow Toolbox: 1-to-1 Object Mapping')
    public static Output[] getValues(Input[] inputs) {
        Output[] result = new List<Output>{};
        for (Input inputItem : inputs) {
            sObject[] records = new List<sObject>{};
            for (FlowMapElement obj : inputItem.flowMap) {
                records.add(obj.record);
            }
            Output obj = new Output();
            obj.records = records;
            result.add(obj);
        }
        return result;
    }

    /* Input(s) for Invocable method */
    public class Input {
        @InvocableVariable(label='Map to get records from' required=true)
        public FlowMapElement[] flowMap;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='Records from Map' required=true)
        public sObject[] records;
    }
}