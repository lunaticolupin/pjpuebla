package mx.pjpuebla.backend.core.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Usuario;

public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {
    public Optional<Usuario> findByClave(String clave);
    public Usuario findById(int id);
    public boolean existsById(int id);
    public Usuario findByClaveAndPasswd(String clave, String passwd);
}
