/**
 * Sandbox initialization class
 * 1. retrieve the id of this class via SOQL: SELECT Id FROM ApexClass WHERE Name = 'PrepareSandbox'
 * 2. use the id in the ApexClassId field of your sandbox definition file.
 */
global class PrepareSandbox implements SandboxPostCopy {

    /**
     * Runs some logic after a sandbox is created:
     * create users with the System Administrator profile
     */
    global void runApexClass(SandboxContext context) {
        activateUsers();
        resetQueueAdresses();
    }

    global static void activateUsers() {
        String myHostStr = System.Url.getSalesforceBaseUrl().getHost();
        Integer startIndex = myHostStr.indexOf('--') + 2;
        Integer endIndex = myHostStr.indexOf('.');
        string sandboxName = myHostStr.mid(startIndex, endIndex - startIndex);

        List<Sandbox_User__mdt> sbxUsers = [SELECT DeveloperName, Base_Username__c, Sandbox_Name__c FROM Sandbox_User__mdt WHERE Sandbox_Name__c = null OR Sandbox_Name__c = :sandboxName];
        List<String> usernames = new List<String>();

        for (Sandbox_User__mdt sbxUser : sbxUsers) {
            usernames.add(sbxUser.Base_Username__c + '.' + sandboxName);
        }

        List<User>users = [SELECT Id, Username, Email FROM User WHERE Username IN:usernames];
        if (Test.isRunningTest()) {
            users = [SELECT Id, Username, Email FROM User WHERE Profile.Name = 'System Administrator' LIMIT 20];
        }

        for (User tempUser : users) {
            tempUser.Email = tempUser.Email.replace('.invalid', '');
        }
        update users;

        if (!Test.isRunningTest()) {
            for (User sbxUser : users) {
                System.resetPassword(sbxUser.Id, true);
            }
        }
    }

    global static void resetQueueAdresses() {
        List<Group> groups = [SELECT Id, Name, Email FROM Group WHERE Type = 'Queue' AND Email != ''];
        for (Group tempGroup : groups) {
            tempGroup.Email = null;
        }
        update groups;
    }
}