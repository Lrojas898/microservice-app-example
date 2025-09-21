package com.elgris.usersapi.api;

import java.util.LinkedList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;

import io.jsonwebtoken.Claims;

@RestController()
@RequestMapping("/users")
public class UsersController {

    @Autowired
    private UserRepository userRepository;


    //commentario de prueba pipeline correcto dev para java
    @RequestMapping(value = "/", method = RequestMethod.GET)
    public List<User> getUsers() {
        List<User> response = new LinkedList<>();
        userRepository.findAll().forEach(response::add);

        return response;
    }

    @RequestMapping(value = "/{username}",  method = RequestMethod.GET)
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {

        Object requestAttribute = request.getAttribute("claims");
        if((requestAttribute == null) || !(requestAttribute instanceof Claims)){
            throw new RuntimeException("Did not receive required data from JWT token");
        }

        Claims claims = (Claims) requestAttribute;

        if (!username.equalsIgnoreCase((String)claims.get("username"))) {
            throw new AccessDeniedException("No access for requested entity");
        }

        return userRepository.findOneByUsername(username);
    }

}
