package kerosene.v05.controller;


import kerosene.v05.model.Usuario;
import kerosene.v05.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/usuarios")
public class UsuarioController {

    @Autowired
    private final UsuarioService service;

    public UsuarioController(UsuarioService service) {
        this.service = service;
    }

    @GetMapping("/list")
    public List<Usuario> listar(){return service.listar();}

    @GetMapping("/{id}")
    public Usuario buscar (@PathVariable long id ){return service.buscarPorId(id).orElse(null);}

    @PostMapping("/create")
    public Usuario criar(@RequestBody Usuario usuario) { return service.criar(usuario); }


}
