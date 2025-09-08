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

    public static Map<String, SObject> createPersonAccountBorrower() {
        // Fetch the Person Account record type
        Id personRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account pa = new Account(
            RecordTypeId = personRtId,
            LastName     = 'Smith',
            FirstName    = 'John',
            PersonEmail  = 'john.smith@example.com'
        );
        insert pa;
        // The system automatically creates the related Contact
        Contact borrowerContact = [SELECT Id, Email, Annual_Income__c, Credit_Score__c
                                    FROM Contact
                                    WHERE AccountId = :pa.Id
                                    LIMIT 1];
        borrowerContact.Annual_Income__c = 120000;
        borrowerContact.Credit_Score__c  = 720;
        update borrowerContact;

        return new Map<String, SObject>{
            'Account' => pa,
            'Contact' => borrowerContact
        };
    }
}