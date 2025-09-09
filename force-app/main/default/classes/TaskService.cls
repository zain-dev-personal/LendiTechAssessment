public with sharing class TaskService {
    
    public static List<Task> prepareDocsTasks(List<Loan_Application__c> approvedLApps, String subject, String taskType){
		return service().prepareDocsTasks(approvedLApps, subject, taskType);
	}

    private static ITaskService service(){
		return (ITaskService) Application.Service.newInstance(ITaskService.class);
	}
}