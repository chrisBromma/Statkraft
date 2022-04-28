/****************************************************************************************************
* Class msRedirectToCustomerPortal404Controller
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Controller for the Visual Force Page msRedirectToCustomerPortal404
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Init version.
*****************************************************************************************************/

public with sharing class msRedirectToCustomerPortal404Controller {
    public static PageReference redirect() {
        String communityId = [SELECT Id FROM Network WHERE Name = :'Customer Portal' LIMIT 1].Id;
        String baseURL = '';
        if (!Test.isRunningTest()) {
            ConnectApi.Community community = ConnectApi.Communities.getCommunity(communityId);
            baseURL = community.siteUrl;
        }
        PageReference retURL = new PageReference(baseURL + '/s');
        retURL.setRedirect(true);
        return retURL;
    }
}