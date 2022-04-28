/****************************************************************************************************
* Class msContractRoleCreaterController
*
*   Create By	:   Frank Nehler (mindsquare GmbH)
*   Create Date	:   09.01.2019
*   Description	:	Controller for the Contract Role Creator Component.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Frank Nehler                              09.01.2019          Init version.
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	First Version for Prod
*****************************************************************************************************/

public with sharing class msContractRoleCreaterController {
    /**
    * @description - This method retrieves all Entities related to a Contract identified by its Id.
    */
    @AuraEnabled
    public static List <Entity__c> getEntities (String contractId){
        List<Id> entIds = new List<Id>();
        List<Entity_Contract_Relationship__c> relations = new List<Entity_Contract_Relationship__c>([SELECT Entity__c FROM Entity_Contract_Relationship__c WHERE Contract__c = :contractId]);
        for (Entity_Contract_Relationship__c rel : relations){
            entIds.add(rel.Entity__c);
        }
        List<Entity__c> relatedEntities = new List<Entity__c>([SELECT Id, Name FROM Entity__c WHERE Id IN :entIds]);
        return relatedEntities;
    }
    /**
    * @description - This method retrieves all Entity Roles related to a Contact identified by its Id.
    */
    @AuraEnabled
    public static List<Entity_Role__c> getEntityRoles(Id contactId){

        return [SELECT Id, Name, Role__c, RecordType.Name, Entity__r.Name FROM Entity_Role__c WHERE Contact__c =:contactId];
    }
    /**
    * @description - This method retrieves all Record Types related to the Contract Role Object.
    */
    @AuraEnabled
    public static List <RecordType> getRecordTypesCon (){
        return [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Contract_Role__c'];
    }
    /**
    * @description - This method retrieves all Record Types related to the Entity Role Object.
    */
    @AuraEnabled
    public static List <RecordType> getRecordTypesEnt (){
        return [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Entity_Role__c'];
    }
    /**
    * @description - This method returns an empty Contract Role to be filled with data by the frontend.
    */
    @AuraEnabled
    public static Contract_Role__c emptyContractRole(){
        return new Contract_Role__c();
    }
    /**
    * @description - This method returns an empty Entity Role to be filled with data by the frontend.
    */
    @AuraEnabled
    public static Entity_Role__c emptyEntityRole(){
        return new Entity_Role__c();
    }
    /**
    * @description - This method returns an empty Entity Roles List to be filled with data by the frontend.
    */
    @AuraEnabled
    public static List<Entity_Role__c> emptyEntityRolesList(){
        return new List<Entity_Role__c>();
    }
    /**
    * @description - This method deletes a specified Entity Role.
    */
    @AuraEnabled
    public static Boolean deleteEntityRole(Entity_Role__c roleToDelete){
        Database.DeleteResult result = Database.delete(roleToDelete);
        if(result.isSuccess()){
            return true;
        }else{
            return false;
        }
    }
    /**
    * @description - This method saves the result of the process initiated by the Component. That is, a specified
    * Contract Role for a certain Contact, identified by its Id, as well an optional set of EntityRoles. Since some of
    * those might be already present in the System by design of the Component, they get filtered accordingly by Id.
    */
    @AuraEnabled
    public static Boolean saveResult(Id contactId, Contract_Role__c newContractRole, List<Entity_Role__c> newEntityRolesList){

        List<Entity_Role__c> actualNewEntityRoles = new List<Entity_Role__c>();
        newContractRole.Contact__c = contactId;
        for(Entity_Role__c roleItem : newEntityRolesList){
            if(roleItem.Id==null){
                roleItem.Contact__c = contactId;
                actualNewEntityRoles.add(roleItem);
            }
        }
        Savepoint sp = Database.setSavepoint();
            try{
                insert newContractRole;
                insert actualNewEntityRoles;
            }catch(DmlException e){
                Database.rollback(sp);
                throw new AuraHandledException(e.getMessage());
            }catch(Exception e){
                Database.rollback(sp);
                throw new AuraHandledException(e.getMessage());
            }
        return true;
    }
}