define(['jquery'], 
    ($) => {
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

            $("#overlay").fadeIn(300);

            try{
                const respuesta = await fetch (url, params);

                $("#overlay").fadeOut(300);

                return respuesta.json();
            }catch(error){

                $("#overlay").fadeOut(300);

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

            let response;

            $("#overlay").fadeIn(300);

            try{
                const respuesta = await fetch (url, params);
                const contentType = respuesta.headers.get("content-type");

                if (contentType && contentType.includes("application/pdf")){
                    // Cuando se descarga un archivo
                    response = respuesta.blob();
                }else{
                    //Ocurrio un error
                    response = respuesta.json();
                }
            }catch(error){

                response = {
                    success: false,
                    error: error
                }
            }

            $("#overlay").fadeOut(300);

            return response;

            
        }

        parseFecha = (fecha)=>{
            const options = {
                month: '2-digit', day: '2-digit', year: 'numeric', timeZone: 'UTC'
            };

            return new Date(fecha).toLocaleDateString('es', options);
        }

        parsePDF = (data)=>{

        }

        waiting = (stop=false)=>{
            if (stop){
                $("#overlay").fadeOut(300);
                return;
            }

            $("#overlay").fadeIn(300);
        }

        return {
            getData: getData,
            postData: postData,
            getReporte: getReporte,
            parseFecha: parseFecha,
            waiting: waiting
        }
    }
);