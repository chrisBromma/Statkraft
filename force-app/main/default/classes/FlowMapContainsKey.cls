public class FlowMapContainsKey {
    @InvocableMethod(
        label='Flow Tool: Check if a Key comes is in Map (existience of certain String / Id) (Map.containsKey)'
        category='Flow Toolbox: Mapping General'
    )
    public static List<Boolean> containsKey(Input[] input) {
        system.debug(input);
        List<Boolean> results = new List<Boolean>();
        for (FlowMapElement loopObj : input[0].flowMap) {
            if (loopObj.key == input[0].key) {
                results.add(true);
                break;
            }
        }
        if (results.size() == 0) {
            results.add(false);
        }

        return results;
    }

    public class Input {
        @InvocableVariable(label='Key you want to check for' required=true)
        public string key;

        @InvocableVariable(label='Map to look for' required=true)
        public FlowMapElement[] flowMap;
    }
}