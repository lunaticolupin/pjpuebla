define([
    'require',
    "knockout", "ojs/ojknockout", 'oj-c/button', 'oj-c/form-layout', 'oj-c/input-text', 'ojs/ojdatetimepicker','oj-c/select-single', 'oj-c/checkbox', 
    'oj-c/text-area', 'oj-c/radioset',
], (require, ko, ) => {
    class ConsultaModel{

        constructor(){
            //this.folio = ko.observable();
            this.PARAM_NAME = "folio";
            this.solicitud = ko.observable({
                id: -1
            });

            this.parseQueryParams = () => {
                // Remove leading '?' from document.location.search
                const search = document.location.search
                    ? document.location.search.substring(1)
                    : "";
                const params = [];
                search.split("&").forEach((param) => {
                    const pair = param.split("=");
                    params.push(pair);
                });
                return params;
            };

            this.queryParamFolio = this.parseQueryParams().filter((p) => {
                return p[0] === this.PARAM_NAME;
            });

            this.folio = ko.computed(()=>{
                const value = this.queryParamFolio;

                try{
                    return value[0][1];
                }catch(error){
                    return null;
                }
            });

            this.getSolicitud = (()=>{
                const folio = this.folio();

                if (folio){
                    fetch("http://localhost:8080/mediacion/solicitud/folio/"+folio)
                    .then(result => result.json())
                    .then((response)=>{
                        if (response.success){
                            this.solicitud(response.data);
                        }
                    });
                }
            });

            this.getSolicitud();
        }

    }

    return new ConsultaModel();
});