define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider',
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", 
"oj-c/form-layout","sweetalert"],
 function(ko, config, utils, ArrayDataProvider) {
    class permisoDetalleViewModel {
        constructor(params) {
            const userInfoSignal = params.userInfoSignal;

            var self = this

            this.serviceUrl = config.baseEndPoint+'/permisos'

            self.id = ko.observable()
            self.clave = ko.observable()
            self.descripcion = ko.observable()

            this.guardar = (()=>{
                let url = this.serviceUrl+"/save"

                let data = self.parsepermisoSave()

                console.log(data)

                utils.postData(url,data).then((response)=>{
                    if(response.success) {
                        swal(response.message)
                        this.closeModalAgregar()
                        this.serviceUrl = config.baseEndPoint + '/permisos'
                    } else {
                        swal(JSON.stringify(response.errors))
                    }
                }).catch(error => swal(error))
            });

            this.parsepermiso = ((data)=>{
                if(data) {
                    self.id(data.id)
                    self.clave(data.clave)
                    self.descripcion(data.descripcion)
                }
            });

            this.parsepermisoSave = (() => {
                return {
                    id: self.id(),
                    clave: self.clave(),
                    descripcion: self.descripcion()
                }
            });

            userInfoSignal.add((permiso)=>{
                this.parsepermiso(permiso)
            },this);
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
    }
    return permisoDetalleViewModel
});