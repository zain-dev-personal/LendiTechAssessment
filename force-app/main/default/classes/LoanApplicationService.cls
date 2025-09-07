public with sharing class LoanApplicationService {

    public static Map<Id, Product__c> getEligibleProductsByContact(Set<Id> contactIds){
		return service().getEligibleProductsByContact(contactIds);
	}

    private static ILoanApplicationService service(){
		return (ILoanApplicationService) Application.Service.newInstance(ILoanApplicationService.class);
	}	
}