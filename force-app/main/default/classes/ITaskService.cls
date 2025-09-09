public interface ITaskService {
    
    List<Task> prepareDocsTasks(List<Loan_Application__c> approvedLApps, String subject, String taskType);
}