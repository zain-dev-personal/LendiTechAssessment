public class TestData {
    
    public static User createAdminUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String uniq = String.valueOf(DateTime.now().getTime());
        User u = new User(
            Alias = 'adm' + uniq.substring(uniq.length()-5),
            Email = 'sysadmin+' + uniq + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'BatchAdmin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_AU',
            TimeZoneSidKey = 'Australia/Sydney',
            Username = 'sysadmin+' + uniq + '@example.com',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }
}