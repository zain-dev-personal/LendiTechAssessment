public with sharing class LoanApplicationService {
    
    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps){
		service().prepareDocsTasks(approvedLApps);
	}

    private static ILoanApplicationService service(){
		return (ILoanApplicationService) Application.Service.newInstance(ILoanApplicationService.class);
	}	
}