public with sharing class TaskService {
    
    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps, String subject, String taskType){
		service().prepareDocsTasks(approvedLApps, subject, taskType);
	}

    private static ITaskService service(){
		return (ITaskService) Application.Service.newInstance(ITaskService.class);
	}
}