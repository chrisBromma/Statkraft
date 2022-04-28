public class CaseSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Case.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Case.Id,
            Case.Contract__c,
            Case.Subject
        };
    } 

}