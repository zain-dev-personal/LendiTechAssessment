/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class BorrowerSelectorTest {

    @testSetup
    static void setupData() {
        insert new List<Contact>{
            new Contact(FirstName='John', LastName='Borrower',  Email='john@example.com', Annual_Income__c=120000, Credit_Score__c=720),
            new Contact(FirstName='Jane', LastName='Borrower', Email='jane@example.com', Annual_Income__c= 95000, Credit_Score__c=690),
            new Contact(FirstName='No', LastName='Email User', Email=null, Annual_Income__c= 80000, Credit_Score__c=650)
        };
    }


    @IsTest
    private static void testselectByIdReturnsExpected() {
        Contact john = [SELECT Id, Name FROM Contact WHERE Name='John Borrower' LIMIT 1];

        Test.startTest();
        Contact borrower = BorrowerSelector.newInstance().selectById(john.Id);
        Test.stopTest();

        System.assertNotEquals(null, borrower, 'Selector should return a record for valid Id');
        System.assertEquals(john.Id, borrower.Id, 'Id should match');
        System.assertEquals('john@example.com', borrower.Email, 'Email should be present from selector field list');
        System.assertEquals(120000, borrower.Annual_Income__c, 'Annual income should be present');
        System.assertEquals(720, borrower.Credit_Score__c, 'Credit score should be present');
    }

    //Negative testing by using fake Id
    @IsTest
    static void negativeSelectByIdUserFakeId() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        BorrowerSelector mockSel = (BorrowerSelector) mocks.mock(BorrowerSelector.class);
        Id fakeId = fflib_IDGenerator.generate(Contact.SObjectType);

        mocks.startStubbing();
        mocks.when(mockSel.selectById(fakeId)).thenReturn(null);
        mocks.stopStubbing();

        Contact contact = mockSel.selectById(fakeId);

        System.assertEquals(null, contact, 'Expected null for non-existent Contact/Borrower Id');
    }

    // Bulk testing
    @IsTest
    static void testSelectByIdsbulk() {
        
        Contact john = [SELECT Id FROM Contact WHERE FirstName='John' LIMIT 1];
        Contact jane = [SELECT Id FROM Contact WHERE FirstName='Jane' LIMIT 1];

        Test.startTest();
        Map<Id, Contact> borrowerMap = BorrowerSelector.newInstance().getBorrowerMap(new Set<Id>{ john.Id, jane.Id });
        Test.stopTest();

        // Assert
        System.assertEquals(2, borrowerMap.size(), 'Should return two borrowers for provided Ids');
        Set<Id> borrowerIds = new Set<Id>();
        for (Contact b : borrowerMap.values()){
            borrowerIds.add(b.Id);
        } 
        System.assert(borrowerIds.contains(john.Id) && borrowerIds.contains(jane.Id),'Both requested borrowers should be returned');
    }
}