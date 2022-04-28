/****************************************************************************************************
* Class msRedirectToCustomerPortal404ContTest
*
*   Create By	:   Christian Gottlieb (mindsquare GmbH)
*   Create Date	:   06.03.2019
*   Description	:	Test Class for msRedirectToCustomerPortal404Controller
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	        Date             	Description
*   * -----------------------------------------------------------------------------------------------
*   * Christian Gottlieb (mindsquare GmbH)		06.03.2019      	Init version.
*****************************************************************************************************/
@IsTest
public with sharing class msRedirectToCustomerPortal404ContTest {
    @IsTest
    public static void redirectTest() {
        PageReference reference = msRedirectToCustomerPortal404Controller.redirect();
    }
}