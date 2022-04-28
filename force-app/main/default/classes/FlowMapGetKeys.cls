public class FlowMapGetKeys {
    @InvocableMethod(label='Flow Tool: Get a List of all Keys used in a Map (Map.keySet())' category='Flow Toolbox: Mapping General')
    public static Output[] getkeys(Input[] inputs) {
        Output[] result = new List<Output>{};

        for (Input inputItem : inputs) {
            Output obj = new Output();
            string[] keySet = new List<string>{};

            for (FlowMapElement flowElem : inputItem.flowMap) {
                keySet.add(flowElem.key);
            }

            obj.keySet = keySet;
            result.add(obj);
        }
        return result;
    }
    /* Input(s) for Invocable method */
    public class Input {
        @InvocableVariable(label='Map to get keys from' required=true)
        public FlowMapElement[] flowMap;
    }

    /* Output(s) for Invocable method */
    public class Output {
        @InvocableVariable(label='List of Strings from Output' required=true)
        public string[] keySet;
    }
}