public interface ITaskService {
    
    void prepareDocsTasks(List<Loan_Application__c> approvedLApps, String subject, String taskType);
}