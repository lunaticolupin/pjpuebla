define([], 
    () => {
        /**
         * params = {method: 'GET/POST', body: data, headers: headers}
         */
        getData = async (url, params={}) => {

            try{
                const respuesta = await fetch(url, params);
                const contentType = respuesta.headers.get("content-type");

                if (contentType && contentType.includes("application/pdf")){
                    // Cuando se descarga un archivo
                    return respuesta.blob();
                }else{
                    return respuesta.json();
                }
            }catch(error){
                console.log(JSON.stringify(error));

                return {
                    success: false,
                    error: error
                }
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

            try{
                const respuesta = await fetch (url, params);

                return respuesta.json();
            }catch(error){
                console.log(error);

                return {
                    success: false,
                    error: error
                }
            }            
        }

        getReporte = async (url, data={})=>{
            let params ={
                method: "POST",
                body: JSON.stringify(data),
                headers: {
                    "Content-Type": "application/json"
                }
            }

            try{
                const respuesta = await fetch (url, params);
                const contentType = respuesta.headers.get("content-type");

                if (contentType && contentType.includes("application/pdf")){
                    // Cuando se descarga un archivo
                    return respuesta.blob();
                }else{
                    //Ocurrio un error
                    return respuesta.json();
                }
            }catch(error){
                console.log(error);

                return {
                    success: false,
                    error: error
                }
            }

            
        }

        parseFecha = (fecha)=>{
            const options = {
                month: '2-digit', day: '2-digit', year: 'numeric', timeZone: 'UTC'
            };

            return new Date(fecha).toLocaleDateString('es', options);
        }

        parsePDF = (data)=>{

        }

        return {
            getData: getData,
            postData: postData,
            getReporte: getReporte,
            parseFecha: parseFecha
        }
    }
);