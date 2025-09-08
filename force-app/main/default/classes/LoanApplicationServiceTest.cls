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
private class LoanApplicationServiceTest {

    @TestSetup
    static void setupData() {
        // Create a range of products
        insert new List<Product__c>{
            new Product__c(Name='FHA 30Y',   Min_Credit_Score__c=580, Base_Rate__c=6.25),
            new Product__c(Name='Conv 30Y',  Min_Credit_Score__c=620, Base_Rate__c=6.00),
            new Product__c(Name='Jumbo 30Y', Min_Credit_Score__c=700, Base_Rate__c=6.75),
            new Product__c(Name='VA 30Y',    Min_Credit_Score__c=600, Base_Rate__c=6.10),
            new Product__c(Name='USDA',      Min_Credit_Score__c=640, Base_Rate__c=6.20)
        };
    }

    /**
     * Borrower has Credit_Score__c 680, eligible products are those with Min_Credit_Score__c <= 680
     * Mock BorrowerSelector so the service picks up this borrower's score.
     */
    @IsTest(SeeAllData=false)
    private static void testReturnsOnlyEligibleProducts() {
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Set<Id> contactIds = new Set<Id>();
        // Fake borrower Contact with 680 Credit Score
        Id contactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Contact borrower = new Contact(
            Id = contactId,
            Email = 'borrower@example.com',
            Annual_Income__c = 120000,
            Credit_Score__c = 680
        );
        contactIds.add(contactId);

        // Mock BorrowerSelector
        BorrowerSelector mockBorrowerSel = (BorrowerSelector) mocks.mock(BorrowerSelector.class);
        mocks.startStubbing();
        mocks.when(mockBorrowerSel.selectByIds(contactIds)).thenReturn(borrower);
        mocks.stopStubbing();

        //Application.setBorrowerSelector(mockBorrowerSel);
        Application.Selector.setMock(mockBorrowerSel);

        LoanApplicationServiceImpl servImpl = new LoanApplicationServiceImpl();

        
        Test.startTest();
        Map<Id,Product__c> eligibleProducts = servImpl.getEligibleProductsByContact(contactIds);
        Test.stopTest();

        // Assert Product Map is not null
        System.assertNotEquals(null, eligibleProducts, 'Service should return a non-null list');
        
        Set<String> names = new Set<String>();
        for (Product__c p : eligibleProducts.values()) {
            names.add(p.Name);
        }

        System.assert(names.contains('FHA 30Y'),   'Should include FHA 30Y (580)');
        System.assert(names.contains('VA 30Y'),    'Should include VA 30Y (600)');
        System.assert(names.contains('Conv 30Y'),  'Should include Conv 30Y (620)');
        System.assert(names.contains('USDA'),      'Should include USDA (640)');
        System.assert(!names.contains('Jumbo 30Y'),'Should exclude Jumbo 30Y (700)');

        // Verify the selector was called exactly once with the right Id
        ((BorrowerSelector) mocks.verify(mockBorrowerSel, 1)).selectByIds(contactIds);
    }

    /**
     * Null contact Id -> expect the service to throw error.
     */
    @IsTest
    private static void negative_nullContactId_throws() {
        LoanApplicationServiceImpl svc = new LoanApplicationServiceImpl();
        Set<Id> contactIds = new Set<Id>{null};
        Boolean threw = false;
        
        Test.startTest();
        try {
            svc.getEligibleProductsByContact(contactIds);
        }catch (Exception exp) {
            System.debug('exp--->'+ exp.getMessage());
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Expected an exception when contactId is null.');
    }

    /**
     * Borrower not found (selector returns null)
     */
    @IsTest
    private static void negative_borrowerNotFound_throwsOrEmpty() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Id contactId = fflib_IDGenerator.generate(Contact.SObjectType);
        
        BorrowerSelector mockBorrowerSel = (BorrowerSelector) mocks.mock(BorrowerSelector.class);
        mocks.startStubbing();
        mocks.when(mockBorrowerSel.selectById(contactId)).thenReturn(null);
        mocks.stopStubbing();

        //Application.setBorrowerSelector(mockBorrowerSel);
        Application.Selector.setMock(mockBorrowerSel);

        LoanApplicationServiceImpl servImpl = new LoanApplicationServiceImpl();

        Boolean threwError = false;
        Map<Id,Product__c> eligibleProducts;
        Test.startTest();
        try {
            eligibleProducts = servImpl.getEligibleProductsByContact(null);
        } catch (Exception e) {
            threwError = true;
        }
        Test.stopTest();

        // Service throws when borrower is not found
        if (threwError) {
            ((BorrowerSelector) mocks.verify(mockBorrowerSel, 1)).selectById(contactId);
            return;
        }

        // If your service returns empty list instead, assert that contract:
        //System.assertEquals(0, eligibleProducts.size(),
        //    'If not throwing, service should return an empty list for unknown borrower.');
       // ((BorrowerSelector) mocks.verify(mockBorrowerSel, 1)).selectById(contactId);
    }
}