define(['../../accUtils', 'jquery', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals', 'ojs/ojkeyset', 
    "ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element', 'ojs/ojvalidationgroup', "ojs/ojswitch"], 
    function (accUtils, $, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, ojkeyset_1 ) {
        class mediadorlViewModel {
             constructor() {
                var self = this;
    
                self.mediadores = ko.observableArray();
                self.mediadores_select = ko.observableArray();
                self.baseUrl = config.baseEndPoint + '/mediacion/mediadores';
                self.mediadorSeleccionado = ko.observable();
                self.personas = ko.observableArray([]);
                
                self.mediadorDetalle = ko.observable(false);
                self.mediador_template = ko.observable({});
                this.ModuleElementUtils = ModuleElementUtils;
                this.dataProvider = new ArrayDataProvider(self.mediadores, {keyAttributes: 'id'});
                this.mediadoresDP = new ArrayDataProvider(self.mediadores_select, { keyAttributes: 'value' });
                this.userInfoSignal = new signals.Signal();
                self.dataProviderPersonas = new ArrayDataProvider(self.personas, {keyAttributes: 'value'})

                //Observables para formulario de mediador.
                self.id_mediador = ko.observable();
                self.numero = ko.observable();
                self.certificado = ko.observable();
                self.estatus = ko.observable();
                self.usuario = ko.observable();
                self.supervisado_por = ko.observable();
                
                
                this.groupValid = ko.observable();

                this.connected = () => {
                    accUtils.announce('Catalogos page loaded.', 'assertive');
                    document.title = "Catálogos / mediadores";
                    self.getmediadores(self.baseUrl); 
                    self.getPersonas(config.baseEndPoint + '/personas');
                    
                   
                };

                this.firstSelectedRowChangedListener = ((event) => {
                    const itemContext = event.detail.value;
    
                    if (itemContext && itemContext.data) {
                        const mediador = itemContext.data;
    
                        self.parseMediador(mediador);
                        self.mediadorDetalle(true);
                    }
                });

                self.mediadorDetalle.subscribe((data)=>{


                    if (data){
                        $('#mediadores').hide();
                        return;
                    }
    
                    $('#mediadores').show();
                });
    
    
                self.getmediadores = (url, params = {}) => {
                    utils.waiting();
    
                    utils.getData(url, params).then((response)=>{
                        
                        if (response.success){
                            self.mediadores(response.data);
                            
                            let mediadores_temp = [];
                            mediadores_temp.push({ value: '', label: "Sin supervisor" })
                            response.data.forEach(element => {
                                mediadores_temp.push({ value: element.id, label: element.usuario.nombreCompleto });
                            });
                            self.mediadores_select(mediadores_temp);   
                            
                             
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
    
                this.detallemediador = (event, detail) =>{
                   self.mediadorDetalle(true);
                   self.mediadorSeleccionado({ key: detail.item.key, data:detail.item.data });
                   self.parseMediador(detail.item.data);
                };
    
                this.agregarmediador = () =>{
                    self.mediadorDetalle(true);
                    self.getJSONTemp();
                   
                    //self.mediadorSeleccionado(newmediador);
                };
    
                this.muestraDetalle = (verDetalle=true) =>{
    
                    if (verDetalle){
                        $("#mediadores").hide();
                        $("#form-mediador").show();
                        return verDetalle;
                    }
    
                    $("#mediadores").show();
                    $("#form-mediador").hide();
                    self.mediadorSeleccionado(null);
                };

                self.getJSONTemp=(()=>{
                    const url = config.baseEndPoint + '/mediacion/mediadores/template';
               
                    
                    utils.getData(url,{}).then((response)=>{
                        if (response.success){
                           
                            self.parseMediador(response.data);
                            self.mediadorSeleccionado(response)
                        }
                    })
                });


                self.parseMediador = ((mediador) =>{
                    
                    
                    const id_supervisor = mediador.supervisadoPor ? mediador.supervisadoPor : ''
                    const id_usuario = mediador.usuario ? mediador.usuario.id : null
                    
                    self.id_mediador(mediador.id);
                    self.certificado(mediador.certificado);
                    self.estatus(mediador.estatus);
                    self.numero(mediador.numero);
                    
                    self.usuario(id_usuario);
                    self.supervisado_por(id_supervisor);
                })
                

                self.fromSolicitud = (()=>{
                    let mediador = {
                        
                        numero: self.numero(),
                        certificado: self.certificado(),
                        estatus: self.estatus() ? self.estatus() ? 1 : 0 : 0,
                        usuario: { id:self.usuario() },
                        supervisadoPor: self.supervisado_por() ? self.supervisado_por() : null
                    }
    
                    return mediador;
                });


                
                
                this.guardar = (()=>{
                    const valid = this._checkValidationGroup();

                    if (!valid) {
                        return false;
                    }

                     self.postMediador();

                });



                self.postMediador = (() => {
                    let url = self.baseUrl;
                    let opcion = self.id_mediador() ? '¿Desea actualizar la información?' :  "¿Desea guardar la información?";
                    let data = self.fromSolicitud();
                    self.id_mediador() ? url = url + '/save/' + self.id_mediador() : url = url + '/add';
                
                    if(self.id_mediador()){
                        let data_temp = data
                        data_temp['id'] = self.id_mediador();
                        data = data_temp;
                    }

                    utils.confirmar('Mediador', opcion).then((confirmacion)=>{
                        
                        if (confirmacion){
                            
                            utils.postData(url, data).then((response)=>{                    
                                if (response.success){
                                   
                                    self.getmediadores(self.baseUrl);
                                    self.mediadorSeleccionado(response);
                                    self.parseMediador(response.data);
                                    
                                    swal("Mediador Registrado","El mediador ha sido registrado exitosamente. ", "success");
            
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
                    const element = document.getElementById('mediadores');
                    const currentRow = element.currentRow;
                    
                    if(currentRow) {                   
                        element.selected = { row: new ojkeyset_1.KeySetImpl(), column: new ojkeyset_1.KeySetImpl() };
                    }

                    self.mediadorSeleccionado(null);
                    self.mediadorDetalle(null);
                    
                });

             }

             _checkValidationGroup() {
                const mediador = document.getElementById('trackerMediador');
               
    
                if (mediador.valid === 'valid') {
                    return true;
                }
                else {
                    mediador.showMessages();
                   
    
                    if (mediador.valid!=='valid'){
                        mediador.focusOn('@firstInvalidShown');
                    }
    
                    return false;
                }
            }
        }
    
        return mediadorlViewModel;
    });