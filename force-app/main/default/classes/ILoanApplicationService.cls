public interface ILoanApplicationService {
    
    Map<Id, Product__c> getEligibleProductsByContact(Set<Id> contactIds);
    void updateLoanStatus(List<Loan_Application__c> lApps, Map<Id, Product__c> prdByConLst);
}