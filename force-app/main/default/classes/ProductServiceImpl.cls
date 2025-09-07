public with sharing class ProductServiceImpl implements IProductService{
    
    public static void sendEmail(String address, String body, String subject){
        EmailService.sendEmail(address, body, subject);
    }
}