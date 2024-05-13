define([], 
    () => {
        /**
         * params = {method: 'GET/POST', body: data, headers: headers}
         */
        getData = async (url, params={}) => {

            const respuesta = await fetch(url, params);
            const contentType = respuesta.headers.get("content-type");

            if (contentType && contentType.includes("application/pdf")){
                // Cuando se descarga un archivo
                return respuesta.blob();
            }else{
                return respuesta.json();
            }
        }

        postData = async (url, data = {}) => {
            let params = {
                method: "POST",
                body: JSON.stringify(data),
                headers: {
                    "Content-Type": "application/json"
                }
            };

            const respuesta = await fetch (url, params);

            return respuesta.json();
        }

        parseFecha = (fecha)=>{
            const options = {
                month: '2-digit', day: '2-digit', year: 'numeric', timeZone: 'UTC'
            };

            return new Date(fecha).toLocaleDateString('es', options);
        }

        return {
            getData: getData,
            postData: postData,
            parseFecha: parseFecha
        }
    }
);