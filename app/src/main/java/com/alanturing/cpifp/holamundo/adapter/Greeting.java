package com.alanturing.cpifp.holamundo.adapter;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class Greeting {
    
    @GetMapping("hola")
    public String sayHello()  {
        return "saludo";
    }

}
