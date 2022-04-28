@isTest
public class FlowHasUserPermissionSetTest{
    @IsTest
    public static void testPermissionCheckPositive() {
        
        Boolean hasPermission;
        User u = new User(
                Username = 'TruefakeTest@user.com',
                LastName = 'fake user',
                Email = 'fake@user.com',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'de',
                Alias = 'fake',
                ProfileId = [SELECT Id FROM Profile WHERE Name='Read Only' LIMIT 1].Id
        );
        insert u;
        
        PermissionSet ps = new PermissionSet(Label = 'Test Permission', Name = 'test_permission');
        insert ps;
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        List<Boolean> resultWrapper;
        System.Test.startTest();
        System.runAs(u) {
            String listOfPermissionSetsToCheck = 'test_permission';
            FlowHasUserPermissionSet.Input input = new FlowHasUserPermissionSet.Input();
            input.permissionSetNames = listOfPermissionSetsToCheck;
            resultWrapper = FlowHasUserPermissionSet.hasUserPermissionSets(new List<FlowHasUserPermissionSet.Input>{input});
        }        
        System.Test.stopTest();

        System.assertEquals(resultWrapper.get(0), true);
    }

    @IsTest
    public static void testPermissionCheckNegative() {
        Boolean hasPermission;
        User u = new User(
                Username = 'TruefakeTest@user.com',
                LastName = 'fake user',
                Email = 'fake@user.com',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'de',
                Alias = 'fake',
                ProfileId = [SELECT Id FROM Profile WHERE Name='Read Only' LIMIT 1].Id
        );
        insert u;

        System.Test.startTest();
        List<Boolean> resultWrapper;
        System.runAs(u) {
            String listOfPermissionSetsToCheck = 'CSR_Check';
            FlowHasUserPermissionSet.Input input = new FlowHasUserPermissionSet.Input();
            input.permissionSetNames = listOfPermissionSetsToCheck;
            resultWrapper = FlowHasUserPermissionSet.hasUserPermissionSets(new List<FlowHasUserPermissionSet.Input>{input});
        }
        System.Test.stopTest();

        System.assertEquals(resultWrapper.get(0), false);
    }

    @IsTest
    public static void testPermissionCheckNegativeMultiplePemSets() {
        
        Boolean hasPermission;
        User u = new User(
                Username = 'TruefakeTest@user.com',
                LastName = 'fake user',
                Email = 'fake@user.com',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'de_DE',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'de',
                Alias = 'fake',
                ProfileId = [SELECT Id FROM Profile WHERE Name='Read Only' LIMIT 1].Id
        );
        insert u;


        
        PermissionSet ps = new PermissionSet(Label = 'Test Permission', Name = 'test_permission');
        insert ps;
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        System.Test.startTest();
        List<Boolean> resultWrapper;
        System.runAs(u) {
            String listOfPermissionSetsToCheck = 'test_permission,Bryt Flex Portal Administration Permissions';
            FlowHasUserPermissionSet.Input input = new FlowHasUserPermissionSet.Input();
            input.permissionSetNames = listOfPermissionSetsToCheck;
            resultWrapper = FlowHasUserPermissionSet.hasUserPermissionSets(new List<FlowHasUserPermissionSet.Input>{input});
        }        
        System.Test.stopTest();

        System.assertEquals(resultWrapper.get(0), false);
    }
}