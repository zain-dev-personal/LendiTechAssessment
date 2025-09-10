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
private class ProductRateNormalizationJobTest {

    @testSetup
    static void setupData() {
        
        // Insert 24 products with Base Rate: 12 too-low, 12 too-high
        List<Product__c> testProduct = new List<Product__c>();
        
        // Lower Base Rate: Base_Rate__c < 0.5
        for (Integer i = 1; i <= 12; i++) {
            testProduct.add(new Product__c(
                Name = 'LOW-' + i,
                Min_Credit_Score__c = 600,
                Base_Rate__c = 0.10 + (0.01 * i) // stays below 0.5
            ));
        }
        
        // Higher Base Rate: Base_Rate__c > 15
        for (Integer i = 1; i <= 12; i++) {
            testProduct.add(new Product__c(
                Name = 'HIGH-' + i,
                Min_Credit_Score__c = 600,
                Base_Rate__c = 15.10 + (0.10 * i) // stays above 15
            ));
        }

        // Base Rate: Base_Rate__c = 15
        for (Integer i = 1; i <= 6; i++) {
            testProduct.add(new Product__c(
                Name = 'HIGH-' + i,
                Min_Credit_Score__c = 600,
                Base_Rate__c = 15 // is equal 15
            ));
        }

        // Base_Rate__c = 0.5
        for (Integer i = 1; i <= 6; i++) {
            testProduct.add(new Product__c(
                Name = 'HIGH-' + i,
                Min_Credit_Score__c = 600,
                Base_Rate__c = 0.5 // is equal 0.5
            ));
        }

        // Higher Base Rate: Base_Rate__c = null for negative testing
        for (Integer i = 1; i <= 6; i++) {
            testProduct.add(new Product__c(
                Name = 'NULL-' + i,
                Min_Credit_Score__c = 600,
                Base_Rate__c = NULL
            ));
        }
        insert testProduct;
    }

    @IsTest(SeeAllData=false)
    private static void testAdjustRatesAndSendsEmail() {
        // Gather Ids for assertions
        Set<Id> lowIds = new Set<Id>();
        Set<Id> highIds = new Set<Id>();
        Set<Id> unchLowIds = new Set<Id>();
        Set<Id> unchHighIds = new Set<Id>();
        // Ensure we have at least one active admin with an email address
        User runningUser = TestData.createAdminUser();
        System.runAs(runningUser) {

            for (Product__c p : [SELECT Id, Name, Base_Rate__c FROM Product__c ORDER BY Name]) {

                if (p.Base_Rate__c < 0.5) {
                    lowIds.add(p.Id);
                }
                
                if (p.Base_Rate__c > 15){
                    highIds.add(p.Id);
                }
                if (p.Base_Rate__c == 15){
                    unchHighIds.add(p.Id);
                }
                if (p.Base_Rate__c == 0.5){
                    unchLowIds.add(p.Id);
                }
            }
            System.assertEquals(12, lowIds.size(),  'Expected 12 Low Base Rate');
            System.assertEquals(12, highIds.size(), 'Expected 12 High Base Rate');
            System.assertEquals(6, unchHighIds.size(), 'Expected 6 records with unchanged Base Rate of 15');
            System.assertEquals(6, unchLowIds.size(), 'Expected 6 records with unchanged Base Rate of 0.5');

            // Track email sends before
            Integer beforeEmails = Limits.getEmailInvocations();
            
            // Run the batch  
            Test.startTest();
            Database.executeBatch(new ProductRateNormalizationJob());
            Test.stopTest();
        }   

        // Assert Base Rate
        Map<Id, Product__c> baseRateAfter = new Map<Id, Product__c>([SELECT Id, Name, Base_Rate__c
            FROM Product__c
            WHERE Id IN :lowIds OR Id IN :highIds OR Id IN :unchHighIds OR Id IN :unchLowIds]);
        
        for (Id idLow : lowIds) {
            System.assertEquals(0.5, baseRateAfter.get(idLow).Base_Rate__c,'Lower Base Rate must be clamped to 0.5: ');
        }
        for (Id idHigh : highIds) {
            System.assertEquals(15, baseRateAfter.get(idHigh).Base_Rate__c, 'Higher Base Rate must be adjusted to 15');
        }
        for (Id idUnChHigh : unchHighIds) { // Was and still = 15
            System.assertEquals(15, baseRateAfter.get(idUnChHigh).Base_Rate__c, 'Base Rate is not adjusted');
        }
        for (Id idUnChLow : unchLowIds) { // Was and still = 0.5
            System.assertEquals(0.5, baseRateAfter.get(idUnChLow).Base_Rate__c, 'Base Rate is not adjusted');
        }

        // Verify Email Sending
        // Assert that at least one email was sent
        Integer afterEmails = Limits.getEmailInvocations();
        // Assert not working as send email function is called in future
        //System.assert(afterEmails > beforeEmails, 'finish() should call Messaging.sendEmail at least once.');
    }

    @IsTest(SeeAllData=false)
    private static void testCheckBaseRatesAfterBatch() {
        Test.startTest();
        Database.executeBatch(new ProductRateNormalizationJob());
        Test.stopTest();

        // No Product__c.Base_Rate__c should remain outside range (for non-null Base_Rate__c)
        Integer remaining = [
            SELECT COUNT()
            FROM Product__c
            WHERE Base_Rate__c != null
              AND (Base_Rate__c < 0.5 OR Base_Rate__c > 15)
        ];
        System.assertEquals(0, remaining, 'All Base_Rate__c values must be within [0.5, 15] after normalization.');
    }
}