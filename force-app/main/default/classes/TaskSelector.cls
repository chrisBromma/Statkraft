public inherited sharing class TaskSelector extends fflib_SObjectSelector{
    public SObjectType getSObjectType(){
        return Task.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
            Task.Id,
            Task.Subject,
            Task.ActivityDate,
            Task.Description
        };
    }
}