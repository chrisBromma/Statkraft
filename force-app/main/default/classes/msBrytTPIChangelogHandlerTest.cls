/****************************************************************************************************
 * Class msBrytTPIChangelogHandlerTest
 *
 *   Create By	 : Christian Gottlieb(mindsquare GmbH)
 *   Create Date : 11.04.2019
 *   Description : Test class for the Trigger Handler msBrytTPIChangelogHandler
 *
 *   Modification Log:
 *   -------------------------------------------------------------------------------------------------
 *   * Developer                        	Date		Description
 *   * -----------------------------------------------------------------------------------------------
 *   * Christian Gottlieb (mindsquare GmbH)	11.04.2019	Init version.
 *****************************************************************************************************/
@IsTest
public with sharing class msBrytTPIChangelogHandlerTest {
    @IsTest
    public static void testRun(){
        msBrytTPIChangelog__c changelog = new msBrytTPIChangelog__c();
        changelog.msUser__c = UserInfo.getUserId();
        changelog.msChangelog__c = 'test';
        insert changelog;
        update changelog;
        delete changelog;
        undelete changelog;
    }

}