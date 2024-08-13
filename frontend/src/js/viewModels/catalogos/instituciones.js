define(['../../accUtils', 'jquery', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals', 'ojs/ojkeyset', 
    "ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element', 'ojs/ojvalidationgroup', "ojs/ojswitch"], 
    function (accUtils, $, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, ojkeyset_1 ) {
        class institucionlViewModel {
             constructor() {
                var self = this;
    
                self.instituciones = ko.observableArray([]);
                self.baseUrl = config.baseEndPoint + '/instituciones';
                self.institucionSeleccionada = ko.observable();
                self.personas = ko.observableArray([]);
                
                self.institucionDetalle = ko.observable(false);
                self.institucion_template = ko.observable({});
                this.ModuleElementUtils = ModuleElementUtils;
                this.dataProvider = new ArrayDataProvider(self.instituciones, {keyAttributes: 'id'});
                this.userInfoSignal = new signals.Signal();
                self.dataProviderPersonas = new ArrayDataProvider(self.personas, {keyAttributes: 'value'})

                //Observables para formulario de institucion.
                self.id_institucion = ko.observable();
                self.clave = ko.observable();
                self.nombre = ko.observable();
                self.direccion = ko.observable();
                self.tipo = ko.observable();
                self.estatus = ko.observable();
                self.contacto = ko.observable();

               
                this.groupValid = ko.observable();

                this.connected = () => {
                    accUtils.announce('Catalogos page loaded.', 'assertive');
                    document.title = "Catálogos / instituciones";
                    self.getInstituciones(self.baseUrl); 
                    self.getPersonas(config.baseEndPoint + '/personas');
                };

                this.firstSelectedRowChangedListener = ((event) => {
                    const itemContext = event.detail.value;
    
                    if (itemContext && itemContext.data) {
                        const institucion = itemContext.data;
    
                        self.parseInstitucion(institucion);
                        self.institucionDetalle(true);
                    }
                });

                self.institucionDetalle.subscribe((data)=>{
                    
                    
                    if (data){
                        $('#instituciones').hide();
                        return;
                    }
    
                    $('#instituciones').show();
                });
    
    
                self.getInstituciones = (url, params = {}) => {
                    utils.waiting();
    
                    utils.getData(url, params).then((response)=>{
                       
                        
                        if (response.success){
                            self.instituciones(response.data);
                        }   
                       
                        
                        utils.waiting(stop=true);
                        
                    }).catch(error => {
                        utils.waiting(stop=true);
                        console.log(error)
                    });         
                }

                self.getPersonas = (url, params = {}) => {
                    utils.waiting();
    
                    utils.getData(url, params).then((response)=>{
                        
                        if (response.success){
                            let personas_temp = [];
                            

                            response.data.forEach(element => {
                                if(!element.personaMoral){
                                    personas_temp.push({value: element.id, label: element.nombre + ' ' + element.apellidoMaterno + ' ' + element.apellidoPaterno})
                                }   
                            });
                            self.personas(personas_temp);
                            
                            
                        }
    
                        utils.waiting(stop=true);
                        
                    }).catch(error => {
                        utils.waiting(stop=true);
                    });         
                }
    
                this.detalleInstituciones = (event, detail) =>{
                   self.institucionDetalle(true);
                   self.institucionSeleccionada({ key: detail.item.key, data:detail.item.data });
                   self.parseInstitucion(detail.item.data);
                };
    
                this.agregarInstitucion = () =>{
                    self.institucionDetalle(true);
                    self.getJSONTemp();
                   
                    //self.institucionSeleccionada(newinstitucion);
                };

                self.getJSONTemp=(()=>{
                    const url = config.baseEndPoint + '/instituciones/template';
                    
                    console.log(url);
                    
                    
                    utils.getData(url,{}).then((response)=>{
                        if (response.success){
                           
                            self.parseInstitucion(response.data);
                            self.institucionSeleccionada(response)
                        }
                    })
                });


                self.parseInstitucion = ((institucion) =>{
                    
                    self.id_institucion(institucion.id);
                    self.estatus(institucion.activo);
                    self.clave(institucion.clave);
                    self.contacto(institucion.contacto);
                    self.direccion(institucion.direccion);
                    self.nombre(institucion.nombre);
                    self.tipo(institucion.tipo);
                })
                

                self.fromSolicitud = (()=>{
                    let institucion = {
                        clave: self.clave(),
                        activo: self.estatus() ? self.estatus() ? 1 : 0 : 0,
                        nombre: self.nombre(),
                        tipo: self.tipo(),
                        contacto: self.contacto(),
                        direccion: self.direccion()
                    }
    
                    return institucion;
                });
                
                this.guardar = (()=>{
                    const valid = this._checkValidationGroup();

                    if (!valid) {
                        return false;
                    }

                     self.postInstitucion();

                });


                self.postInstitucion = (() => {
                    let url = self.baseUrl;
                    let opcion = self.id_institucion() ? '¿Desea actualizar la información?' :  "¿Desea guardar la información?";
                    let data = self.fromSolicitud();
                    self.id_institucion() ? url = url + '/save/' + self.id_institucion() : url = url + '/add';
                    
                    if(self.id_institucion()){
                        let data_temp = data
                        data_temp['id'] = self.id_institucion();
                        data = data_temp;
                    }

                    utils.confirmar('institucion', opcion).then((confirmacion)=>{

                        if (confirmacion){
                            
                            utils.postData(url, data).then((response)=>{                    
                                if (response.success){
                                   
                                    self.getInstituciones(self.baseUrl);
                                    self.institucionSeleccionada(response);
                                    self.parseInstitucion(response.data);
                                    
                                    swal("institución Registrada","La institución ha sido registrado exitosamente. ", "success");
            
                                    return true;
                                }
            
                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");
                            }).catch((response)=>{
                                const errores = JSON.stringify(response);
                                
                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                    });



                });
            
    
                this.cancelar = (()=>{
                    const element = document.getElementById('instituciones');
                    const currentRow = element.currentRow;
                    if(currentRow) {                   
                        element.selected = { row: new ojkeyset_1.KeySetImpl(), column: new ojkeyset_1.KeySetImpl() };
                    }

                    self.institucionSeleccionada(null);
                    self.institucionDetalle(null);
                    

                });

             }

             _checkValidationGroup() {
                const institucion = document.getElementById('trackerInstitucion');
               
    
                if (institucion.valid === 'valid') {
                    return true;
                }
                else {
                    institucion.showMessages();
                   
    
                    if (institucion.valid!=='valid'){
                        institucion.focusOn('@firstInvalidShown');
                    }
    
                    return false;
                }
            }
        }
    
        return institucionlViewModel;
    });