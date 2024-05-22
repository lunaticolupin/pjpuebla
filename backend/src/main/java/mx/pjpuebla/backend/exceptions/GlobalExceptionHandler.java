package mx.pjpuebla.backend.exceptions;
//import java.util.Arrays;

import java.util.Arrays;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingServletRequestParameterException;
//import org.springframework.web.bind.MissingRequestHeaderException;
//import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
//import org.springframework.web.multipart.MaxUploadSizeExceededException;

import mx.pjpuebla.backend.response.GenericResponse;

//import pjpuebla.exhortos.response.GenericResponse;

@ControllerAdvice
public class GlobalExceptionHandler{

    //Mostrar mensaje de error en caso de algún problema con el formato de JSON
    @ExceptionHandler(HttpMessageNotReadableException.class) // exception handled
    public ResponseEntity<GenericResponse> handleExceptions( HttpMessageNotReadableException e) {
        return ResponseEntity.badRequest().body(new GenericResponse(false, "ERROR. El formato no es el correcto", Arrays.asList(e.getMessage()), null));

    }

    //Mostrar mensaje de error en caso de la falta de parametros en la petición (Request)
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<GenericResponse> handleExceptionsMissingRequestParameter(MissingServletRequestParameterException e) {
        return ResponseEntity.badRequest().body(new GenericResponse(false,"ERROR. Faltan parámetros", Arrays.asList(e.getMessage()), null));
    }

    //Mostrar mensaje de error en caso de la falta de parametros en el encabezado (Header)
    /*@ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<GenericResponse> handleExceptionsMissingHeaderParameter(MissingRequestHeaderException e) {
        HttpStatus status = HttpStatus.BAD_REQUEST; 
        return new ResponseEntity<>(
            new GenericResponse(false,"ERROR. Faltan parámetros", Arrays.asList(e.getMessage()), null),status
        );
    }

    //Mostrar mensaje de error en caso rebasar el tamaño de archivo
    @ExceptionHandler(MaxUploadSizeExceededException.class) 
    public ResponseEntity<GenericResponse> handleMaxSizeException(MaxUploadSizeExceededException e){
        HttpStatus status = HttpStatus.NOT_ACCEPTABLE; 
        return new ResponseEntity<>(
            new GenericResponse(false,"ERROR. El archivo no puede ser procesado", Arrays.asList(e.getMessage()), null),status
        );
    }

    //Mostrar mensaje de error en caso de la falta de argumentos
    @ExceptionHandler(IllegalArgumentException.class) 
    public ResponseEntity<GenericResponse> handleIllegalArgumentException(IllegalArgumentException e){
        HttpStatus status = HttpStatus.BAD_REQUEST; 
        return new ResponseEntity<>(
            new GenericResponse(false,"ERROR. Faltan argumentos", Arrays.asList(e.getMessage()), null),status
        );
    }*/
}