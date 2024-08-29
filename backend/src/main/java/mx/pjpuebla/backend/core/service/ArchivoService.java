package mx.pjpuebla.backend.core.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.DTO.FileInfoDto;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.core.repository.ArchivoRepository;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;
import mx.pjpuebla.backend.mediacion.service.AsistenciaService;
import mx.pjpuebla.backend.mediacion.service.SolicitudArchivoService;

@Service
@AllArgsConstructor
public class ArchivoService {
    private final ArchivoRepository repo;
    private final AsistenciaService asistenciaService;
    private final FormatoService formatoService;
    private final SolicitudArchivoService solicitudArchivoService;

    public Archivo save(Archivo a) {
        return this.repo.save(a);
    }

    public Archivo findById(Integer id) {
        Optional<Archivo> archivo = this.repo.findById(id);

        if (archivo.isPresent()) {
            return archivo.get();
        }

        return null;
    }


    public Integer registrarArchivosInvitaciones(Integer solicitud_id) {
        List<Formato> formatos = new ArrayList<>();
        Integer num_invitaciones = asistenciaService.numAsistencia(solicitud_id);
        
        System.out.println(num_invitaciones);

        // Obtener la lista de formatos según el número de invitaciones
        if (num_invitaciones == 1) {
            formatos = formatoService.findNombreReporte("Invitacion");
        } else if (num_invitaciones == 2) {
            formatos = formatoService.findNombreReporte("SegundaInvitacion");
        }

        // Iterar sobre la lista de formatos y realizar las operaciones
        for (Formato formato : formatos) {
            try {
                Archivo archivo = new Archivo();
                archivo.setTipo(formato.getDescripcion());
                archivo.setNombre("");
                archivo.setUsuario_creo("SISTEMA");
                save(archivo);

                SolicitudArchivo solicitudArchivo = new SolicitudArchivo();
                solicitudArchivo.setSolicitudId(solicitud_id);
                solicitudArchivo.setArchivoId(archivo.getId());
                solicitudArchivo.setFormato(formato.getId());
                solicitudArchivo.setEstatus(1);
                solicitudArchivo.setUsuarioCreo("SISTEMA");
                solicitudArchivoService.save(solicitudArchivo);
            } catch (Exception e) {
                return 0; // Retorna 0 inmediatamente si alguna operación falla
            }
        }

        return 1; // Retorna 1 si todas las operaciones fueron exitosas
    }

    public Long upload(MultipartFile file, String usuario) {
        if (file.isEmpty()) {
            return null;
        }

        String nombreArchivo = getNombre(file);
        String tipoArchivo = getTipo(file);
        byte[] dataArchivo = getBytes(file);

        return this.repo.uploadArchivo(nombreArchivo, tipoArchivo, dataArchivo, usuario);
    }

    @SuppressWarnings("unused")
    private Long uploadArchivo(String nombreArchivo, String tipoArchivo, byte[] dataArchivo, String usuario) {
        return this.repo.uploadArchivo(nombreArchivo, tipoArchivo, dataArchivo, usuario);
    }

    private byte[] getBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException | NullPointerException e) {
            return null;
        }

    }

    private String getTipo(MultipartFile file) {
        try {
            return file.getContentType();
        } catch (NullPointerException e) {
            return null;
        }
    }

    private String getNombre(MultipartFile file) {

        try {
            String nombre = file.getOriginalFilename();
            return URLEncoder.encode(nombre, StandardCharsets.UTF_8.toString());
        } catch (UnsupportedEncodingException | NullPointerException e) {
            return null;
        }

    }

    public List<FileInfoDto> getFileInfo(Integer solicitudId) {
        return repo.findFileInfoBySolicitudId(solicitudId);
    }

}
