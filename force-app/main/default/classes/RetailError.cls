/**
 * This is a class created to handle custom exceptions for Retail track
 * @Author - Alisha  Mundaden
 */
public class RetailError {

    public class ClientSideException extends Exception{
    } 
    public class ServerSideException extends Exception{
    } 
    public class CustomException extends Exception{
    }
    
    //standard salesforce error response structure
    public class ErrorJsonResponse {
        public String statusCode = '1';
        public String errorCode;
        public String message;
        public ErrorJsonResponse(String errorCode, string message){
            this.errorCode = errorCode;
            this.message = message;
        }
    }
}