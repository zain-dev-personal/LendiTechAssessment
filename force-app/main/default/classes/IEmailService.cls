public interface IEmailService {
    
    void sendEmail(String address, String body, String subject);
}