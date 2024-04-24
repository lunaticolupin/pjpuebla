package mx.pjpuebla.backend.response;

import java.util.ArrayList;

public class GenericResponse {
    private boolean success;
    private String message;
    private Object errors;
    private Object data;

    public GenericResponse(){
        success = false;
        message = "";
        errors = new ArrayList<>();
        data = null;
    }

    public GenericResponse(boolean success, String message, Object errors, Object data) {
        this.success = success;
        this.message = message;
        this.errors = errors;
        this.data = data;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Object getErrors() {
        return errors;
    }

    public void setErrors(Object errors) {
        this.errors = errors;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }
}
