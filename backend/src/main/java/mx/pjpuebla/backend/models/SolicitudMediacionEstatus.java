package mx.pjpuebla.backend.models;

public enum SolicitudMediacionEstatus {
    RECEPCION("En Recepción"), POR_DETERMINAR("Por Determinar"), MEDIABLE("Mediable"), NO_MEDIABLE("No Mediable");

    private String title;

    SolicitudMediacionEstatus(String title) {
        this.title = title;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    
}
