package com.alanturing.cpifp.holamundo.adapter.api;

import org.springframework.web.bind.annotation.RestController;

import com.alanturing.cpifp.holamundo.domain.Person;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;



@RestController
public class GreetingRest {
    
    @PostMapping("api/hola")
    public com.alanturing.cpifp.holamundo.domain.Greeting sayHello(@RequestBody Person person) {
        
        String saludo = "Hola " + person.getName() + " " + person.getSurname() + " ¿qué tal estas?";
        com.alanturing.cpifp.holamundo.domain.Greeting greeting 
        = new com.alanturing.cpifp.holamundo.domain.Greeting(saludo);
        
        return greeting ;
    }
 
}
