define(['jquery', 'sweetalert'],
    ($) => {
        /**
         * params = {method: 'GET/POST', body: data, headers: headers}
         */
        _getData = async (url, params = {}) => {


            try {
                const respuesta = await fetch(url, params);
                const contentType = respuesta.headers.get("content-type");

                if (contentType && contentType.includes("application/pdf")) {
                    // Cuando se descarga un archivo
                    return respuesta.blob();
                } else {
                    return respuesta.json();
                }
            } catch (error) {
                return {
                    success: false,
                    error: error
                }
            }
        }

        _postData = async (url, data = {}) => {
            let params = {
                method: "POST",
                body: JSON.stringify(data),
                headers: {
                    "Content-Type": "application/json"
                }
            };

            $("#overlay").fadeIn(300);

            try {
                const respuesta = await fetch(url, params);

                $("#overlay").fadeOut(300);

                return respuesta.json();
            } catch (error) {

                $("#overlay").fadeOut(300);

                return {
                    success: false,
                    error: error
                }
            }
        }

        _postDataWithFiles = async (url, files = {}) => {
            // Crea un objeto FormData
            let formData = new FormData();

            // Añade cada archivo al FormData
            for (let key in files) {
                formData.append(key, files[key]);
            }

            let params = {
                method: "POST",
                body: formData,
                // No es necesario establecer el Content-Type ya que FormData se encarga de esto automáticamente
            };

            $("#overlay").fadeIn(300);

            try {
                const respuesta = await fetch(url, params);

                $("#overlay").fadeOut(300);

                // Si la respuesta es JSON, parsea y retorna el resultado
                const contentType = respuesta.headers.get("content-type");
                if (contentType && contentType.includes("application/json")) {
                    return respuesta.json();
                } else {
                    // Maneja otros tipos de respuestas si es necesario
                    return respuesta.text(); // O lo que necesites dependiendo de la respuesta
                }
            } catch (error) {
                $("#overlay").fadeOut(300);

                return {
                    success: false,
                    error: error
                };
            }
        }

        _getDocument = async (url, params) => {
            try {

                const response = await fetch(url, {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                // Verificar si la respuesta es exitosa
                if (response.ok) {
                    // Convertir la respuesta en un Blob y retornarla
                    const blob = await response.blob();
                    // Obtener el nombre del archivo desde el encabezado Content-Disposition
                    
                    const contentDisposition = response.headers.get('Content-Disposition');

                    let fileName = "documento.pdf"; // Valor por defecto en caso de que no se obtenga el nombre

                    if (contentDisposition) {
                        // Regex para capturar el nombre del archivo, manejando diferentes posibles formateos
                        const fileNameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
                        if (fileNameMatch && fileNameMatch[1]) {
                            fileName = fileNameMatch[1].replace(/['"]/g, ''); // Limpiar comillas si las tiene
                        }
                    }

                    return { blob, fileName };
                } else {
                    console.error("Error al descargar el archivo:", response.statusText);
                    return null;
                }
            } catch (error) {
                console.error("Error en la solicitud:", error);
                return null;
            }
        }


        _getReporte = async (url, data = {}) => {
            let params = {
                method: "POST",
                body: JSON.stringify(data),
                headers: {
                    "Content-Type": "application/json"
                }
            }

            let response;

            $("#overlay").fadeIn(300);

            try {
                const respuesta = await fetch(url, params);
                const contentType = respuesta.headers.get("content-type");

                if (contentType && contentType.includes("application/pdf")) {
                    // Cuando se descarga un archivo
                    response = respuesta.blob();
                } else {
                    //Ocurrio un error
                    response = respuesta.json();
                }
            } catch (error) {

                response = {
                    success: false,
                    error: error
                }
            }

            $("#overlay").fadeOut(300);

            return response;
        }

        _parseFecha = (fecha) => {
            const options = {
                month: '2-digit', day: '2-digit', year: 'numeric', timeZone: 'UTC'
            };

            return new Date(fecha).toLocaleDateString('es', options);
        }

        _parsePDF = (data) => {

        }

        _waiting = (stop = false) => {
            if (stop) {
                $("#overlay").fadeOut(300);
                return;
            }

            $("#overlay").fadeIn(300);
        }

        _confirmar = (async (title = "Confirmación", text = "¿Desea guardar la información?") => {
            return await swal(
                {
                    title: title,
                    text: text,
                    buttons: ["No", "Si"],
                    dangerMode: true
                }
            );
        });

        _checkValidationGroup = ((idValigGroup) => {
            const validGroup = document.getElementById(idValigGroup);

            if (validGroup.valid === 'valid') {
                return true;
            }
            else {
                validGroup.showMessages();
                validGroup.focusOn('@firstInvalidShown');
                return false;
            }
        });

        return {
            getData: _getData,
            postData: _postData,
            postDataFiles: _postDataWithFiles,
            getDocument: _getDocument,
            getReporte: _getReporte,
            parseFecha: _parseFecha,
            waiting: _waiting,
            confirmar: _confirmar,
            checkValidationGroup: _checkValidationGroup
        }
    }
);