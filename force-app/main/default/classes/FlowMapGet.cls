public class FlowMapGet {
    @InvocableMethod(label='Flow Tool: Retrieve Record from Map with Field Value (Map.get(key))' category='Flow Toolbox: 1-to-1 Object Mapping')
    public static Output[] getValue(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            Output obj = new Output();
            obj.outputValue = null;
            for (FlowMapElement loopObj : inputItem.flowMap) {
                if (loopObj.key == inputItem.key) {
                    obj.outputValue = loopObj.record;
                    break;
                }
            }
            result.add(obj);
        }

        return result;
    }

    public class Input {
        @InvocableVariable(label='Field value you have used in your Map' required=true)
        public string key;

        @InvocableVariable(label='Map to get your record from' required=true)
        public FlowMapElement[] flowMap;
    }

    public class Output {
        @InvocableVariable(label='Retrieved value' required=true)
        public sObject outputValue;
    }
}