@isTest
	public class ai_customLookUpControllerTest {
        
        @isTest static void fetchLookUpValues(){
            
            Account_Role__c rolle = new Account_Role__c();
            String test1 = 'KTM';
            String test2 = 'Account_Role__c';
            try{
        		List < sObject > obj1=customLookUpController.fetchLookUpValues(test1, test2);
            	obj1.add(rolle);
                insert obj1;
        }
        catch (System.NullPointerException e) {
            System.debug('**** Error: ' + e.getMessage());
        }
            
        }    

}