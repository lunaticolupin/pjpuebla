define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider',
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", 
"oj-c/form-layout","sweetalert","oj-c/select-multiple"],
    function(ko, config, utils, ArrayDataProvider) {
        class rolModuloPermisoViewModel {
            constructor(params){
                const userInfoSignal = params.userInfoSignal;
                
                var self = this

                this.serviceURL = config.baseEndPoint + '/rolmodulopermisos'

                self.rol_id = ko.observable()
                self.modulo_id = ko.observable()
                self.permiso_id = ko.observable()
                self.estatus = ko.observable(1)

                self.rolesArray = []
                self.modulosArray= []
                self.permisosArray = []
    
                this.connected = () => {
                    this.getModulos()
                    this.getRoles()
                    this.getPermisos()
                }

                this.parseRolModulo = ((data)=>{
                    if(data) {
                        self.rol_id(data.id)
                    }
                });

                userInfoSignal.add((rolmodulopermiso)=>{
                    this.parseRolModulo(rolmodulopermiso)
                },this);


                this.parseRolModuloPermisoSave = (() => {
                    return {
                        id:{
                            rolId: self.rol_id(),
                            moduloId: self.modulo_id(),
                            permisoId: self.permiso_id(),
                            // estatus: 1
                        },
                        estatus: self.estatus()
                    }
                });
                //Funcion guardar registro
                this.guardar = (()=>{
                    let url = this.serviceURL+"/save";
                    let data = self.parseRolModuloPermisoSave();
                    utils.postData(url,data).then((response)=>{
                        if(response.success) {
                            swal(response.message)
                            this.closeModalAgregar()
                            // this.serviceURL = config.baseEndPoint + '/roles'
                        } else {
                            alert(JSON.stringify(response.errors))
                        }                                      
                    }).catch(error=> alert(error))
                })
                //Fin funcion guardar registro


                //Funcion obtener los roles activos
                this.getRoles = (()=>{
                    let url = config.baseEndPoint + '/roles/activos'
                    utils.getData(url).then((response)=>{
                        if(response.data) {
                            if(self.rolesArray.length == 0)
                            {
                                let roles
                                roles = response.data                                                
                                roles.forEach(element => {
                                    self.rolesArray.push(element)
                                });
                            }                                       
                        }
                    }).catch(error => swal(error))
                });
                //Fin funcion obtener roles activos

                //Funcion para obtener los permisos activos
                this.getPermisos = (()=>{
                    let url = config.baseEndPoint + '/permisos/activos'
                    utils.getData(url).then((response)=>{
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
                //fin funcion obtener permisos activos
    

                //Funcion para obtener el listado de los módulos activos 
                this.getModulos = (()=>{
                    let url = config.baseEndPoint + '/modulos/activos'
                    utils.getData(url).then((response)=>{
                        if(response.data) {
                            if(self.modulosArray.length == 0)
                            {
                                let modulos
                                modulos = response.data                                                
                                modulos.forEach(element => {
                                    self.modulosArray.push(element)
                                });
                            }                                       
                        }
                    }).catch(error => alert(error))
                });
                //Fin funcion obtener modulos activos
    

                //Se crean los dataProviders para poder visualizar en los combos
                this.dataProviderModulos = new ArrayDataProvider(self.modulosArray,
                    {keyAttributes:'id'});

                this.dataProviderPermisos = new ArrayDataProvider(self.permisosArray,
                    {keyAttributes:'id'});
    
                this.dataProviderRoles = new ArrayDataProvider(self.rolesArray,
                    {keyAttributes:'id'});
            }
            closeModalAgregar(event) {
                document.getElementById("modalAsignar").close();
            }

        }
        return rolModuloPermisoViewModel
    })