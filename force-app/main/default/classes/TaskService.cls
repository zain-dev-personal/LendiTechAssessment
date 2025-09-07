public with sharing class TaskService {
    
    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps){
		service().prepareDocsTasks(approvedLApps);
	}

    private static ITaskService service(){
		return (ITaskService) Application.Service.newInstance(ITaskService.class);
	}
}