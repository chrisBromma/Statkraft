global without sharing class  msLoginFormController {

    public msLoginFormController() {
    }

    @AuraEnabled
    public static void login(String username, String password, String startUrl) {
        try {
            User user = [SELECT Id, IsActive FROM User WHERE Username = :username OR Username =: username + Label.msPortalUsernameSufix LIMIT 1];

            if (!user.IsActive) {
                throw new SecurityException(Label.msLoginUserDeactivated);
            }else{
                UserLogin userLoginInfo = [SELECT IsFrozen, IsPasswordLocked FROM UserLogin WHERE UserId =: user.Id];
                if(userLoginInfo.IsFrozen){
                    throw new SecurityException(Label.msLoginUserFrozen);
                }
                else if(userLoginInfo.IsPasswordLocked){
                    throw new SecurityException(Label.portalLoginFormPasswordLockedMsg);
                }
            }

            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);

        } catch (SecurityException ex)
        {
            throw new AuraHandledException(ex.getMessage());
        }
        catch(Exception ex)
        {
            throw new AuraHandledException(Label.msLoginError);
        }
    }

    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }

    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }

    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }

}