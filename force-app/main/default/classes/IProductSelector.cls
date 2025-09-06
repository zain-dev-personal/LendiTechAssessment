public interface IProductSelector extends fflib_ISObjectSelector{
    
    List<Product__c> selectByIds(Set<Id> idSet);
    Product__c selectById(Id recordId);
    Product__c selectBestEligibleProduct(Decimal borrowerCreditScore);
}