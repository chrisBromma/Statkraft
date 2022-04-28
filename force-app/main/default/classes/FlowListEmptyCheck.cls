public with sharing class FlowListEmptyCheck {
    @InvocableMethod(label='Flow Tool: Check if SObject List is empty' category='Flow Toolbox')
    public static List<Boolean> checkIfListIsEmpty(Input[] inputList) {
        List<Boolean> result = new List<Boolean>();
        for (Input inputItem : inputList) {
            result.add(inputItem.listToCheck.isEmpty());
        }
        return result;
    }

    public class Input {
        @InvocableVariable(label='List of SObjects you want to check' required=true)
        public List<SObject> listToCheck;
    }
}