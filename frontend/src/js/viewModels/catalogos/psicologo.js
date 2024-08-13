define(['../../accUtils', 'jquery', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals', 'ojs/ojkeyset', 
    "ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element', 'ojs/ojvalidationgroup', "ojs/ojswitch"], 
    function (accUtils, $, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, ojkeyset_1 ) {
        class PsicologolViewModel {
             constructor() {
                var self = this;
    
                self.psicologos = ko.observableArray([]);
                self.baseUrl = config.baseEndPoint + '/mediacion/psicologos';
                self.psicologoSeleccionado = ko.observable();
                self.personas = ko.observableArray([]);
                
                self.psicologoDetalle = ko.observable(false);
                self.psicologo_template = ko.observable({});
                this.ModuleElementUtils = ModuleElementUtils;
                this.dataProvider = new ArrayDataProvider(self.psicologos, {keyAttributes: 'id'});
                this.userInfoSignal = new signals.Signal();
                self.dataProviderPersonas = new ArrayDataProvider(self.personas, {keyAttributes: 'value'})

                //Observables para formulario de psicologo.
                self.id_psicologo = ko.observable();
                self.numero = ko.observable();
                self.estatus = ko.observable();
                self.usuario = ko.observable();
               
                this.groupValid = ko.observable();

                this.connected = () => {
                    accUtils.announce('Catalogos page loaded.', 'assertive');
                    document.title = "Catálogos / psicologos";
                    self.getPsicologos(self.baseUrl); 
                    self.getPersonas(config.baseEndPoint + '/personas');
                };

                this.firstSelectedRowChangedListener = ((event) => {
                    const itemContext = event.detail.value;
    
                    if (itemContext && itemContext.data) {
                        const psicologo = itemContext.data;
    
                        self.parsePsicologo(psicologo);
                        self.psicologoDetalle(true);
                    }
                });

                self.psicologoDetalle.subscribe((data)=>{
                    
                    
                    if (data){
                        $('#psicologos').hide();
                        return;
                    }
    
                    $('#psicologos').show();
                });
    
    
                self.getPsicologos = (url, params = {}) => {
                    utils.waiting();
    
                    utils.getData(url, params).then((response)=>{
                       
                        
                        if (response.success){
                            self.psicologos(response.data);
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
    
                this.detallepsicologos = (event, detail) =>{
                   self.psicologoDetalle(true);
                   self.psicologoSeleccionado({ key: detail.item.key, data:detail.item.data });
                   self.parsePsicologo(detail.item.data);
                };
    
                this.agregarPsicologo = () =>{
                    self.psicologoDetalle(true);
                    self.getJSONTemp();
                   
                    //self.psicologoSeleccionado(newpsicologo);
                };

                self.getJSONTemp=(()=>{
                    const url = config.baseEndPoint + '/mediacion/psicologos/template';
                    
                    console.log(url);
                    
                    
                    utils.getData(url,{}).then((response)=>{
                        if (response.success){
                           
                            self.parsePsicologo(response.data);
                            self.psicologoSeleccionado(response)
                        }
                    })
                });


                self.parsePsicologo = ((psicologo) =>{
                    
                    const id_usuario = psicologo.usuario ? psicologo.usuario.id : null
                    
                    self.id_psicologo(psicologo.id);
                    self.estatus(psicologo.estatus);
                    self.numero(psicologo.numero);
                    
                    self.usuario(id_usuario);
                 
                })
                

                self.fromSolicitud = (()=>{
                    let psicologo = {
                        numero: self.numero(),
                        estatus: self.estatus() ? self.estatus() ? 1 : 0 : 0,
                        usuario: { id:self.usuario() }
                    }
    
                    return psicologo;
                });
                
                this.guardar = (()=>{
                    const valid = this._checkValidationGroup();

                    if (!valid) {
                        return false;
                    }

                     self.postPsicologo();

                });


                self.postPsicologo = (() => {
                    let url = self.baseUrl;
                    let opcion = self.id_psicologo() ? '¿Desea actualizar la información?' :  "¿Desea guardar la información?";
                    let data = self.fromSolicitud();
                    self.id_psicologo() ? url = url + '/save/' + self.id_psicologo() : url = url + '/add';
                    
                    if(self.id_psicologo()){
                        let data_temp = data
                        data_temp['id'] = self.id_psicologo();
                        data = data_temp;
                    }

                    utils.confirmar('Psicologo', opcion).then((confirmacion)=>{

                        if (confirmacion){
                            
                            utils.postData(url, data).then((response)=>{                    
                                if (response.success){
                                   
                                    self.getPsicologos(self.baseUrl);
                                    self.psicologoSeleccionado(response);
                                    self.parsePsicologo(response.data);
                                    
                                    swal("psicologo Registrado","El psicologo ha sido registrado exitosamente. ", "success");
            
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
                    const element = document.getElementById('psicologos');
                    const currentRow = element.currentRow;
                    console.log(currentRow)
                    if(currentRow) {                   
                        element.selected = { row: new ojkeyset_1.KeySetImpl(), column: new ojkeyset_1.KeySetImpl() };
                    }

                    self.psicologoSeleccionado(null);
                    self.psicologoDetalle(null);
                    

                });

             }

             _checkValidationGroup() {
                const psicologo = document.getElementById('trackerPsicologo');
               
    
                if (psicologo.valid === 'valid') {
                    return true;
                }
                else {
                    psicologo.showMessages();
                   
    
                    if (psicologo.valid!=='valid'){
                        psicologo.focusOn('@firstInvalidShown');
                    }
    
                    return false;
                }
            }
        }
    
        return PsicologolViewModel;
    });