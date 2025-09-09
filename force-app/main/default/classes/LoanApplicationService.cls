public with sharing class LoanApplicationService {

    public static Map<Id, Product__c> getEligibleProductsByContact(Set<Id> contactIds){
		return service().getEligibleProductsByContact(contactIds);
	}

    public static List<Loan_Application__c> updateLoanStatus(List<Loan_Application__c> lApps, Map<Id, Product__c> prdByConLst){
		return service().updateLoanStatus(lApps, prdByConLst);
	}

    private static ILoanApplicationService service(){
		return (ILoanApplicationService) Application.Service.newInstance(ILoanApplicationService.class);
	}	
}