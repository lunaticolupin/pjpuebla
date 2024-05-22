package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.core.entitiy.RolUsuario;
import mx.pjpuebla.backend.core.entitiy.RolUsuarioKey;
import mx.pjpuebla.backend.core.repository.RolUsuarioRepository;

@Service
@AllArgsConstructor

public class RolUsuarioService {

    private final RolUsuarioRepository repo;

    public List<RolUsuario> findAll() {
        return repo.findAll();
    }

    public RolUsuario save(RolUsuario ru) {
        return repo.save(ru);
    }

    // public RolUsuario findById(RolUsuarioKey id) {
    //     RolUsuario rol =  this.repo.findById(id);

    //     return rol;
    // }

    // public boolean delete(RolUsuarioKey ru) {
    //     try {
    //         this.repo.delete(ru);
    //         return true;
    //     } catch (Exception e) {
    //         e.printStackTrace();
    //         return false;
    //     }
    // }

    public boolean existsById(RolUsuarioKey id) {
        return this.repo.existsById(id);
    }

    public RolUsuario findById(RolUsuarioKey id) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'findById'");
    }

	// public Object findAll() {
	// 	// TODO Auto-generated method stub
	// 	throw new UnsupportedOperationException("Unimplemented method 'findAll'");
	// }
}
