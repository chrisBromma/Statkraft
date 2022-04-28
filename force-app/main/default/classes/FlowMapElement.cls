public class FlowMapElement {
    
    @AuraEnabled
    public string key; //Map key
        
    @AuraEnabled
    public sObject record; //sObject attribute for sObject Map type

    @AuraEnabled
    public List<SObject> recordList;
    /* You can also choose to define a map key as something else
     * than an sObject type depending upon how you want your map to look like.
     */

    @AuraEnabled
    public string mappedSObjectField;

    public FlowMapElement(SObject record, String mappedSObjectField){
        this.key = (String) record.get(mappedSObjectField);
        this.record = record;
        this.mappedSObjectField = mappedSObjectField;
    }

    public FlowMapElement(String key, List<SObject> recordList, String mappedSObjectField){
        this.key = key;
        this.recordList = recordList;
        this.mappedSObjectField = mappedSObjectField;
    }
}