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
private class ProductSelectorTest {

    @TestSetup
    static void setupData() {
        insert new List<Product__c>{
            new Product__c(Name='Test Product1', Min_Credit_Score__c=620, Base_Rate__c=6.00),
            new Product__c(Name='Test Product2', Min_Credit_Score__c=620, Base_Rate__c=5.75),
            new Product__c(Name='Test Product3', Min_Credit_Score__c=640, Base_Rate__c=5.25),
            new Product__c(Name='Test Product4', Min_Credit_Score__c=640, Base_Rate__c=5.40),
            new Product__c(Name='Test Product5', Min_Credit_Score__c=660, Base_Rate__c=5.55),
            new Product__c(Name='Test Product6', Min_Credit_Score__c=580, Base_Rate__c=6.25),
            new Product__c(Name='Test Product7', Min_Credit_Score__c=600, Base_Rate__c=6.10),
            new Product__c(Name='Test Product8', Min_Credit_Score__c=700, Base_Rate__c=6.75),
            new Product__c(Name='Test Product9', Min_Credit_Score__c=640, Base_Rate__c=6.20),
            new Product__c(Name='Test Product10', Min_Credit_Score__c=680, Base_Rate__c=5.90)
        };
    }

    @IsTest
    private static void testSelectByIdRunsExpected() {
        Product__c p = [SELECT Id, Name, Min_Credit_Score__c, Base_Rate__c
                           FROM Product__c
                           WHERE Name = 'Test Product1'
                           LIMIT 1];

        IProductSelector product = ProductSelector.newInstance();
        
        Test.startTest();
        Product__c got = product.selectById(p.Id);
        Test.stopTest();

        System.assertNotEquals(null, got, 'Expected a Product__c');
        System.assertEquals(p.Id, got.Id);
        System.assertEquals(620, got.Min_Credit_Score__c);
        System.assertEquals(6.00, got.Base_Rate__c);
    }

    @IsTest
    private static void negativetestSelectByIdUseFakeId() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        ProductSelector mockSel = (ProductSelector) mocks.mock(ProductSelector.class);
        Id fakeId = fflib_IDGenerator.generate(Product__c.SObjectType);

        mocks.startStubbing();
        mocks.when(mockSel.selectById(fakeId)).thenReturn(null);
        mocks.stopStubbing();

        Product__c product = mockSel.selectById(fakeId);

        System.assertEquals(null, product, 'Expected null for non-existent Product Id');
    }

    @IsTest(SeeAllData=false)
    private static void testSelectAllProductByBaseRate() {
        
        IProductSelector product = ProductSelector.newInstance();
        Test.startTest();
        List<Product__c> productsLst = product.selectAllProductByBaseRate();
        Test.stopTest();
        System.debug('productsLst.size() : ' + productsLst.size());
        System.assertEquals(true, productsLst.size() == 10); 
    }
}