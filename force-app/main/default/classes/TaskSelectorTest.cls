@isTest
private class TaskSelectorTest {
    @isTest
    private static void testGetSobjectType() {
        TaskSelector TaskSelector = (TaskSelector) Application.Selector.newInstance(Task.SObjectType);
        System.assertEquals('Task', String.valueOf(TaskSelector.getSObjectType()));
    }

    @isTest
    private static void testGetSObjectFieldList() {
        TaskSelector TaskSelector = (TaskSelector) Application.Selector.newInstance(Task.SObjectType);
        System.assertEquals(4, TaskSelector.getSObjectFieldList().size());
    }
}