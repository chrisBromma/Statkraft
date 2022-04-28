public class FlowHasUserPermissionSet {
    @InvocableMethod(label='Flow Tool: Permission Set check' description='Checks if User has all named Permission Sets' category='Flow Toolbox')
    public static List<Boolean> hasUserPermissionSets(List<Input> inputList) {
        List<String> permissionSetAPINameList = inputList[0].permissionSetNames.split(',');
        List<Boolean> outputWrapper = new List<Boolean>();
        Boolean hasPermission;
        Id currentUser = UserInfo.getUserId();
        List<PermissionSetAssignment> permissionSetAssignmentList = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :currentUser AND PermissionSet.Name IN :(permissionSetAPINameList)
        ];
        hasPermission = permissionSetAssignmentList.size() == permissionSetAPINameList.size() ? true : false;
        for (Input i : inputList) {
            outputWrapper.add(hasPermission);
        }
        return outputWrapper;
    }

    public class Input {
        @InvocableVariable(label='Comma-Separated (no spaces) List of Permission Set Names (API)')
        public String permissionSetNames;
    }
}