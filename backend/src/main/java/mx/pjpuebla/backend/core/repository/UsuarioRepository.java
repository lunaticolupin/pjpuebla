package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import mx.pjpuebla.backend.core.entitiy.Usuario;


@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {
    public Usuario findByClave(String clave);
    public Usuario findById(int id);
    public boolean existsById(int id);
    public Usuario findByClaveAndPasswd(String clave, String passwd);
}
