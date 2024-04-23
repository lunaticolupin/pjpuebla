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

        return {
            getData: getData,
            postData: postData
        }
    }
);