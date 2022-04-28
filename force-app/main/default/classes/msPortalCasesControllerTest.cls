@IsTest
private class msPortalCasesControllerTest {

    @IsTest(SeeAllData=True) static void test() {

        String userId = (String) [SELECT Id FROM User LIMIT 1].Id;
        List<Contract__c> contractList = (List<Contract__c>) [SELECT Id FROM Contract__c LIMIT 5];

        List<String> contractIds = new List <String>();
        for(Integer i=0;i<contractList.size();i++){
            contractIds.add(contractList[i].Id);
        }

        List <Entity__c> plantList = (List<Entity__c>)[SELECT Id FROM Entity__c LIMIT 3];

        List<String> plantIds = new List <String>();
        for(Integer i=0;i<plantList.size();i++){
            plantIds.add(plantList[i].Id);
        }

        System.Test.startTest();
            msPortalCasesController.getCases(userId,contractIds,plantIds);

            System.Test.stopTest();
    }
}