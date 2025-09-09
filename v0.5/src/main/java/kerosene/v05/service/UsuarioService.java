package kerosene.v05.service;


import kerosene.v05.model.Usuario;
import kerosene.v05.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UsuarioService {

    @Autowired
    private final UsuarioRepository repository;



    public UsuarioService(UsuarioRepository repository) {
        this.repository = repository;
    }

    public List<Usuario> listar() { return repository.findAll(); }

    public Optional<Usuario> buscarPorId(Long id) { return repository.findById(id); }

    public Usuario criar(Usuario usuario) { return repository.save(usuario);}

    public void deletar(Long id) { repository.deleteById(id); }

    public List<Usuario> buscarPorNome(String username) { return repository.findByUsername(username); }
}
