define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider',
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", 
"oj-c/form-layout","sweetalert","oj-c/select-multiple"],
 function(ko, config, utils, ArrayDataProvider) {
    class moduloDetalleViewModel {
        constructor(params) {
            const userInfoSignal = params.userInfoSignal;
            var self = this

            this.serviceUrl = config.baseEndPoint+'/modulos'

            self.id = ko.observable()
            self.clave = ko.observable()
            self.descripcion = ko.observable()
            // self.permisosArray = ko.observable()
            self.permisosArray = []
            this.connected = () => {
                // self.permisosArray = []
                this.getModulos();
            };

            //Funcion para obtener los modulos y poder seleccionar el modulo padre
            this.getModulos = (()=>{
                let url = config.baseEndPoint + '/permisos/activos'
                utils.getData(url,params).then((response)=>{
                    if(response.data) {
                        if(self.permisosArray.length == 0)
                        {
                            let permisos
                            permisos = response.data                                                
                            permisos.forEach(element => {
                                self.permisosArray.push(element)
                            });
                        }                                      
                    }
                }).catch(error => swal(error))
            });

            // this.dataProviderPermisos = new ArrayDataProvider(self.permisosArray,
            //     {keyAttributes:'value'});
            this.dataProviderPermisos = new ArrayDataProvider(self.permisosArray,
                {keyAttributes:'value'});

            this.guardar = (()=>{
                let url = this.serviceUrl+"/save"

                let data = self.parseModuloSave()

                console.log(data)

                utils.postData(url,data).then((response)=>{
                    if(response.success) {
                        swal(response.message)
                        this.closeModalAgregar()
                        this.serviceUrl = config.baseEndPoint + '/modulos'
                    } else {
                        swal(JSON.stringify(response.errors))
                    }
                }).catch(error => swal(error))
            });

            this.parseModulo = ((data)=>{
                if(data) {
                    self.id(data.id)
                    self.clave(data.clave)
                    self.descripcion(data.descripcion)
                }
            });

            this.parseModuloSave = (() => {
                return {
                    id: self.id(),
                    clave: self.clave(),
                    descripcion: self.descripcion()
                }
            });

            userInfoSignal.add((modulo)=>{
                this.parseModulo(modulo)
            },this);
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
    }
    return moduloDetalleViewModel
});