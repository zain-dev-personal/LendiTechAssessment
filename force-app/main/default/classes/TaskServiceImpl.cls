public inherited sharing class TaskServiceImpl implements ITaskService{
    /*
    * Create a task for each approved loan application
    * @param List<Loan_Application__c> approvedLApps
    * @return void
    */
    public static void prepareDocsTasks(List<Loan_Application__c> approvedLApps) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        Date today = Date.today();

        for (Loan_Application__c loanApp : approvedLApps) {
            Task taskObj = new Task();
            taskObj.Subject = 'Prepare documents';
            taskObj.WhatId = loanApp.Id;
            taskObj.OwnerId = loanApp.OwnerId; 
            taskObj.Priority = 'Normal';
            taskObj.Type = 'Loan Application';
            taskObj.ActivityDate = DateUtility.addBusinessDays(today, 2); // add two business days
            taskObj.Status = 'Not Started';
            uow.registerNew(taskObj);
        }
        uow.commitWork();
    }   
}