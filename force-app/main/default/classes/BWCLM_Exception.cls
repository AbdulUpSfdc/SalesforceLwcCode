public class BWCLM_Exception extends Exception {
    public string error;

    public class ResponseWrapper{
        public Boolean success;
        public String result;
        public String error;

        public ResponseWrapper(Boolean success,String result,String error){
            this.success = success;
            this.result = result;
            this.error = error;
        }
    }

    public void BWCLM_Exception(String error){
        this.error = error;
    }
}