@IsTest
public with sharing class ListMapContainerTest {
    @IsTest
    static void testTwoContainersWithDifferentSObjectTypes() {
        ListMapContainer mapContact = new ListMapContainer(Contact.SObjectType);
        ListMapContainer mapContract = new ListMapContainer(Contract__c.SObjectType);

        Contact newContact = new Contact(LastName = 'test');
        Contact newContact2 = new Contact(LastName = 'test2');

        mapContact.addToMap('accountId1', newContact);
        mapContact.addToMap('accountId2', newContact2);

        Contract__c cont = new Contract__c(Name = 'ppatest');
        Contract__c cont2 = new Contract__c(Name = 'ppa2test2');

        mapContract.addToMap('accountId1', cont);
        mapContract.addToMap('accountId1', cont2);

        List<Contact> contactListTest = new List<Contact>{
                newContact
        };
        List<Contact> contactListTest2 = new List<Contact>{
                newContact2
        };
        List<Contract__c> contractListTest = new List<Contract__c>{
                cont, cont2
        };

        System.assertEquals(new Map<String, List<Contact>>{
                'accountId1' => contactListTest, 'accountId2' => contactListTest2
        }, mapContact.getMap());
        System.assertEquals(new Map<String, List<Contract__c>>{
                'accountId1' => contractListTest
        }, mapContract.getMap());
    }

    @IsTest
    static void testWrongSObjectType() {
        ListMapContainer mapContact = new ListMapContainer(Contact.SObjectType);

        Exception ex;
        try {
            mapContact.addToMap('Test', new Account());
        } catch (Exception e) {
            ex = e;
        }

        Exception ex2;
        try {
            mapContact.put('test', new List<Account>());
        } catch (Exception e) {
            ex2 = e;
        }

        System.assert(ex != null);
        System.assert(ex2 != null);
    }

    @IsTest
    static void testMapFunctions() {
        ListMapContainer mapContact = new ListMapContainer(Contact.SObjectType);

        System.assertEquals(new List<Contact>(), mapContact.get('test'));
        System.assert(!mapContact.containsKey('test'));
        System.assertEquals(Contact.SObjectType, mapContact.getSObjectType());

        Contact newCon = new Contact(LastName = 'Test1');
        mapContact.addToMap('test1', newCon);
        mapContact.put('test2', new List<Contact>{new Contact()});

        System.assertEquals(new List<Contact>{
                newCon
        }, mapContact.get('test1'));

        System.assertEquals(new Set<String>(new List<String>{
                'test1', 'test2'
        }), mapContact.keySet());

        System.assertEquals(1, mapContact.get('test2').size());
    }
}