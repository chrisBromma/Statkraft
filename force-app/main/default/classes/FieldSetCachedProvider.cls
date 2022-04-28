/****************************************************************************************************
 * Class FieldSetCachedProvider
 *
 *   Created By	    :   Fabian Murk (mindsquare AG)
 *   Create Date	:   2021-12-14
 *   Description	:   Singleton class that caches FieldSets
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	                Date             	Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Fabian Murk (mindsquare AG)	                        2021-12-14       	Init version.
 *****************************************************************************************************/
public with sharing class FieldSetCachedProvider {
    public static Map<Schema.DescribeSObjectResult, Map<String, Schema.FieldSet>> fieldSetsBySObjectType = 
            new Map<Schema.DescribeSObjectResult, Map<String, Schema.FieldSet>>();

    public static Map<String, Schema.FieldSet> getBySObjectType(Schema.DescribeSObjectResult inputSObjectType) {
        if(fieldSetsBySObjectType.get(inputSObjectType) == null) {
            fieldSetsBySObjectType.put(inputSObjectType, inputSObjectType.FieldSets.getMap());
        } 
        return fieldSetsBySObjectType.get(inputSObjectType);
    }
}