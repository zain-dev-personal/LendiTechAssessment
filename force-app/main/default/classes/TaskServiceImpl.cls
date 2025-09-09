public inherited sharing class TaskServiceImpl implements ITaskService{
    /*
    * Create a task for each approved loan application
    * @param List<Loan_Application__c> approvedLApps
    * @return void
    */
    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps, String subject, String taskType) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Date today = Date.today();

        try{
            List<Task> taskToCreate = new List<Task>();
            for (Loan_Application__c loanApp : approvedLApps) {
                Task taskObj = new Task();
                taskObj.Subject = subject;
                taskObj.WhatId = loanApp.Id;
                taskObj.OwnerId = loanApp.OwnerId; 
                taskObj.Priority = 'Normal';
                taskObj.Type = taskType;
                taskObj.ActivityDate = DateUtility.addBusinessDays(today, 2); // add two business days
                taskObj.Status = 'Not Started';
                taskToCreate.add(taskObj);
            }
            uow.registerNew(taskToCreate);
            uow.commitWork();
        }catch(Exception exp){
            System.debug('exp-->' + exp.getMessage());
            throw exp;
        }       
    }   
}