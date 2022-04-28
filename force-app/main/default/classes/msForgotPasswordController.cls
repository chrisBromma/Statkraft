/****************************************************************************************************
* Class msForgotPasswordController
*
*   Create By	:   Steffen Naundorf (mindsquare GmbH)
*   Create Date	:   11.08.2019
*   Description	:	
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                        	   Date             	Description
*   * -----------------------------------------------------------------------------------------------                 
*   * Steffen Naundorf (mindsquare GmbH)   11.08.2019      	    Init version.
*****************************************************************************************************/

public without sharing class msForgotPasswordController {
    private static final String DEFAULT_SUFFIX = Label.msPortalUsernameSufix;
    public static final String COMMUNITY_USER_PROFILE_NAME = 'Global Customer Community User';

    @AuraEnabled
    public static void resetPassword(String username) {

        List<User> users = [
                SELECT Username
                FROM User
                WHERE (Username = :username OR Username = :username + DEFAULT_SUFFIX)
                AND ContactId != NULL
                AND IsActive = TRUE
                AND Profile.Name = :COMMUNITY_USER_PROFILE_NAME
                LIMIT 1
        ];

        if (!users.isEmpty()) {
            Site.forgotPassword(users[0].Username);
        } else {
            throw new AuraHandledException('username_invalid');
        }
    }
}