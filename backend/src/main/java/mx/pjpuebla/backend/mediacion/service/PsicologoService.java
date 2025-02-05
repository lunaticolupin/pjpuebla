package mx.pjpuebla.backend.mediacion.service;

import java.lang.StackWalker.Option;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import jakarta.persistence.EntityNotFoundException;
import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Mediador;
import mx.pjpuebla.backend.mediacion.entitiy.Psicologo;
import mx.pjpuebla.backend.mediacion.repository.PsicologoRepository;

@Service
@AllArgsConstructor
public class PsicologoService {
    private final PsicologoRepository repo;

    public List<Psicologo> findAll() {
        return repo.findAll();
    }

    public Psicologo save(Psicologo p) {
        return repo.save(p);
    }

    public boolean esEliminable(Integer id) {
        Optional<Psicologo> psicologo = this.repo.findById(id);

        // Regresamos si el psicologo tiene un estatus de 1 que es el activo logico, si
        // es 0 en tonces no puede ser 'eliminado porque ya ha sido eliminado.'
        return psicologo.get().getEstatus() == 1;
    }

    public Boolean delete(Integer id) {
        Psicologo entidad = repo.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Psicólogo no encontrado con id: " + id)
                
                );

        entidad.setEstatus(0);
        repo.save(entidad);
        return true; // Se realizó la actualización
    }


    public Integer obtenerNumeroConsecutivoPsicologo(){
        Optional<Psicologo> psicologo = this.repo.findTopByOrderByNumeroDesc();
        
        return psicologo.isPresent() ? psicologo.get().getNumero() + 1 : 1;
    }

    public List<Psicologo> obtenerMPsicologosActivos() {
        return repo.findAllByEstatus(1);  // 1 representa el estatus activo
    }

}
