package mx.pjpuebla.backend.core.service;

import java.util.List;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.repository.MateriaRepository;

@Service
@AllArgsConstructor
public class MateriasService {
    private final MateriaRepository repository;

    public List<Materia> findAll(){
        return this.repository.findAll(); 
    }
}
