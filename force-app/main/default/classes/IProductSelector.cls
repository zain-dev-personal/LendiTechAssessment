public interface IProductSelector extends fflib_ISObjectSelector{

    List<Product__c> selectByIds(Set<Id> idSet);
    Product__c selectById(Id recordId);
    List<Product__c> selectAll();
    List<Product__c> selectAllProductByBaseRate();
    Database.QueryLocator queryLocatorSelectAll();
}