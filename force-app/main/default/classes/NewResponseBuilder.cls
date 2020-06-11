/**
 * @author Sagie Twig
 * Following class serve common response in JSON format
 */
public with sharing class NewResponseBuilder {

  public static final String SUCCESS_TYPE_VALUE = 'success';
  public static final String ERROR_TYPE_VALUE = 'danger';

  private NewResponseBuilder() {}

  public static Response newInstance() {
    return new Response();
  }

  /**
   * Following class build step by step common response object
   */
  public class Response {

    public String responseType;
    public Object data;
    public String message;

    public Response() {}

    public Response setSuccess() {
      this.responseType = SUCCESS_TYPE_VALUE;
      return this;
    }

    public Response setError() {
      this.responseType = ERROR_TYPE_VALUE;
      return this;
    }
    
    public Response setError(String message) {
      this.responseType = ERROR_TYPE_VALUE;
      this.message = message;
      return this;
    }

    public Response setData(Object data) {
      this.data = data;
      return this;
    }

    public Response setMessage(String message) {
      this.message = message;
      return this;
    }

    public String stringify() {
      return JSON.serialize(this);
    }

  }


}