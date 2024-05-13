package mx.pjpuebla.backend.core.service;

import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.core.repository.UsuarioRepository;

@Service
@AllArgsConstructor
public class UsuarioService {
    private final UsuarioRepository repo;

    public Usuario findById(Integer id){
        Optional<Usuario> usuario = this.repo.findById(id);

        if (usuario.isPresent()){
            return usuario.get();
        }

        return null;
    }

    public Usuario findByClave(String clave){
        if (repo.findByClave(clave).isPresent()){
            return this.repo.findByClave(clave).get();
        }
        
        return null;
    }

    public List<Usuario> findAll(){
        return this.repo.findAll();
    }

    public Usuario save(Usuario item){
        if (item==null){
            return item;
        }

        return this.repo.save(item);
    }

    public boolean existsById(Integer id){
        return this.repo.existsById(0);
    }

    public boolean deleteById(Integer id){
        try{
            this.repo.deleteById(id);
            return true;
        }catch(Exception e){
            e.printStackTrace();
            return false;
        } 
        
    }

    public void registrarLogin(Usuario usuario){
        usuario.setLastLogin(new Date());

        this.repo.save(usuario);
    }

}
