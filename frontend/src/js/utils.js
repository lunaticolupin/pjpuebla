define(['jquery','sweetalert'], 
    ($) => {
        /**
         * params = {method: 'GET/POST', body: data, headers: headers}
         */
        _getData = async (url, params={}) => {

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

        _postData = async (url, data = {}) => {
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

        _getReporte = async (url, data={})=>{
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

        _parseFecha = (fecha)=>{
            const options = {
                month: '2-digit', day: '2-digit', year: 'numeric', timeZone: 'UTC'
            };

            return new Date(fecha).toLocaleDateString('es', options);
        }

        _parsePDF = (data)=>{

        }

        _waiting = (stop=false)=>{
            if (stop){
                $("#overlay").fadeOut(300);
                return;
            }

            $("#overlay").fadeIn(300);
        }

        _confirmar = ( async(title = "Confirmación", text = "¿Desea guardar la información?") => {
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
            getReporte: _getReporte,
            parseFecha: _parseFecha,
            waiting: _waiting,
            confirmar: _confirmar,
            checkValidationGroup: _checkValidationGroup
        }
    }
);