public with sharing class FlowSplitString {
    @InvocableMethod(label='Flow Tool: Split String based on a custom separator' category='Flow Toolbox')
    public static List<List<String>> stringSplit(List<Input> textAndSeparator) {
        List<List<String>> returnWrapper = new List<List<String>>();
        Input inputParameter = textAndSeparator.get(0);
        String text = inputParameter.text;
        String Separator = inputParameter.separator;
        List<String> returnList = new List<String>();
        if (String.isNotBlank(text) && text.contains(Separator)) {
            if (text.startsWith('[') && text.endsWith(']')) {
                text = text.removeStart('[').removeEnd(']');
            }
            returnList = text.split(Separator);
        } else {
            returnList = new List<String>{ text };
        }
        returnWrapper.add(returnList);
        return returnWrapper;
    }

    /* Input parameters for the Apex action */
    public class Input {
        @InvocableVariable(label='Your text to split' required=true)
        public string text;

        @InvocableVariable(label='Split at which string?' required=true)
        public string separator;
    }
}