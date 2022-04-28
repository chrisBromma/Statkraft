@isTest
public with sharing class RecordTypeCachedProviderTest {
    @isTest static void goThroughMethods(){
        Application.RecordTypes.bySObjectType('Account');
        Application.RecordTypes.byDeveloperName(new Set<String>(new List<String>{'Account'}));
        Application.RecordTypes.byDeveloperName('Account', 'Account');
        Application.RecordTypes.byId(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId());
        Application.RecordTypes.getDefaultRecordTypeMappingForCurrentUser('Account');
        Application.RecordTypes.byDeveloperName('Account', new Set<String>(new List<String>{'Account'}));
    }
}