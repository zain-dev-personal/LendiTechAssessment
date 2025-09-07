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
        
        // Ensure we have at least one active admin with an email address
        User usr = TestData.createAdminUser();

        // Insert 24 products: 12 too-low, 12 too-high
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
        insert testProduct;
    }

    @IsTest(SeeAllData=false)
    static void testAdjustRates_and_sendsEmail() {
        // Gather Ids for assertions
        Set<Id> lowIds = new Set<Id>();
        Set<Id> highIds = new Set<Id>();
        
        for (Product__c p : [SELECT Id, Name, Base_Rate__c FROM Product__c ORDER BY Name]) {

            if (p.Base_Rate__c < 0.5) {
                lowIds.add(p.Id);
            }
             
            if (p.Base_Rate__c > 15){
                highIds.add(p.Id);
            }
        }
        System.assertEquals(12, lowIds.size(),  'Expected 12 LOW products');
        System.assertEquals(12, highIds.size(), 'Expected 12 HIGH products');

        // Track email sends before
        Integer beforeEmails = Limits.getEmailInvocations();

        // Run the batch (small scope to exercise multiple execute() calls)
        Test.startTest();
        Database.executeBatch(new ProductRateNormalizationJob(), 5);
        Test.stopTest();

        // Assert Base Rate
        Map<Id, Product__c> baseRateAfter = new Map<Id, Product__c>([SELECT Id, Name, Base_Rate__c
            FROM Product__c
            WHERE Id IN :lowIds OR Id IN :highIds]);

        for (Id idLow : lowIds) {
            System.assertEquals(
                0.5, baseRateAfter.get(idLow).Base_Rate__c,
                'LOW product must be clamped to 0.5: ' + baseRateAfter.get(idLow).Name
            );
        }
        for (Id idHigh : highIds) {
            System.assertEquals(15, baseRateAfter.get(idHigh).Base_Rate__c, 'HIGH product must be clamped to 15: ' + baseRateAfter.get(idHigh).Name);
        }

        // Verify Email Sending
        // Assert that at least one email was sent
        Integer afterEmails = Limits.getEmailInvocations();
        System.assert(afterEmails > beforeEmails, 'finish() should call Messaging.sendEmail at least once.');
    }
}