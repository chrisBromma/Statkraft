public class FlowListMapGet {
    @InvocableMethod(Label='Flow Tool: Get list of records according to value in Map' Category='Flow Toolbox: 1-to-N List Mapping')
    public static Output[] getValue(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            Output obj = new Output();
            if (inputItem.flowMap != null && inputItem.key != null) {
                for (FlowMapElement loopObj : inputItem.flowMap) {
                    if (loopObj.key == inputItem.key) {
                        obj.outputValue = loopObj.recordList;
                        break;
                    }
                }
            }
            result.add(obj);
        }
        return result;
    }

    public class Input {
        @InvocableVariable(Label='Key (Value to get records from Map)' Required=true)
        public String key;

        @InvocableVariable(Label='Map to get records from' Required=true)
        public FlowMapElement[] flowMap;
    }

    public class Output {
        @InvocableVariable(Label='Resulting List of SObjects' Required=true)
        public List<SObject> outputValue;
    }
}