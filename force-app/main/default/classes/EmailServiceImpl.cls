public with sharing class EmailServiceImpl implements IEmailService{
    
    public void sendEmail(String address, String body, String subject){
        try{
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] {address});
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        }catch(EmailException exp){
            throw new EmailException(exp);
        }      
    }
}