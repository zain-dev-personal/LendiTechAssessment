public interface ILoanApplicationService {
    
    Map<Id, Product__c> getEligibleProductsByContact(Set<Id> contactIds);
}