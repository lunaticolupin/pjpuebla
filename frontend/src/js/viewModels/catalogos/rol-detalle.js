define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider',
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", 
"oj-c/form-layout","sweetalert","oj-c/select-multiple"],
    function(ko, config, utils, ArrayDataProvider) {
    class rolDetalleViewModel {
        constructor(params) {
            const userInfoSignal = params.userInfoSignal;

            var self = this

            this.serviceURL = config.baseEndPoint + '/roles'

            self.id = ko.observable();
            self.clave = ko.observable();
            self.descripcion = ko.observable();

            this.guardar = (()=>{
                let url = this.serviceURL+"/save";
                let data = self.parseRolSave();
                utils.postData(url,data).then((response)=>{
                    if(response.success) {
                        swal(response.message)|
                        this.closeModalAgregar()
                        this.serviceURL = config.baseEndPoint + '/roles'
                    } else {
                        alert(JSON.stringify(response.errors))
                    }                                      
                }).catch(error=> this.console.log(error))
            })
        
            this.parseRol = ((data)=>{
                if(data) {
                    self.id(data.id)
                    self.clave(data.clave)
                    self.descripcion(data.descripcion)
                }
            });

            this.parseRolSave = (() => {
                return {
                    id: self.id(),
                    clave: self.clave(),
                    descripcion: self.descripcion(),
                }
            });

            userInfoSignal.add((rol)=>{
                this.parseRol(rol)
            },this);

            this.eliminar = (() =>{
                let id = self.id();
                if(id == undefined || id == null) {
                    return false;
                }
                let url = this.serviceURL+"/delete/"+id

                utils.postData(url,{}).then((response)=>{
                    alert(response.message);
                }).catch(error => console.log(error))
            });
        }

        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
    }
    return rolDetalleViewModel
 })