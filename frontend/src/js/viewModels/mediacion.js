define(['../accUtils','jquery', 'webConfig','utils','knockout','ojs/ojarraydataprovider', 'ojs/ojbufferingdataprovider', 'ojs/ojkeyset', 'ojs/ojconverter-datetime', 
    'ojs/ojmodule-element-utils', 'ojs/ojasyncvalidator-regexp', 'ojs/ojvalidator-required', 'signals', 'ojs/ojlistdataproviderview', 'ojs/ojdataprovider',
    'ojs/ojknockout', 'oj-c/button', 'ojs/ojtable', 'oj-c/form-layout', 'oj-c/input-text', 'ojs/ojdatetimepicker','oj-c/select-single', 'oj-c/checkbox', 'ojs/ojvalidationgroup', 'sweetalert',
    'oj-c/text-area', 'ojs/ojtoolbar'
],
 function(accUtils, $, config, utils, ko, ArrayDataProvider, BufferingDataProvider, ojkeyset_1, ojconverter_datetime_1, ModuleElementUtils, AsyncRegExpValidator, RequiredValidator, 
    signals, ListDataProviderView, ojdataprovider_1) {
    class MediacionViewModel {
         constructor() {
            var self = this;
            var rootViewModel = ko.dataFor(document.getElementById('globalBody'));

            rootViewModel.validaSesion();

            self.urlBase = config.baseEndPoint + '/mediacion';

            /** Observables */
            self.solicitudes = ko.observableArray();
            self.solicitudSeleccionada = ko.observable();

            self.solicitudId = ko.observable();
            self.solicitudFolio = ko.observable();
            self.solicitudFecha = ko.observable();
            self.solicitudEsMediable = ko.observable(true);
            self.solicitudCanalizada = ko.observable(false);
            self.solicitudUsuario = ko.observable({nombre:"", apellidoPaterno:"", apellidoMaterno:""});
            self.solicitudInvitado = ko.observable({nombre:"", apellidoPaterno:"", apellidoMaterno:""});
            self.solicitudMateria = ko.observable();
            self.solicitudMateriaId = ko.observable();
            self.solicitudFechaSesion = ko.observable();
            self.solicitudDescripcion = ko.observable();
            self.solicitudEstatus = ko.observable();
            self.solicitudTipoApertura = ko.observable();
            self.solicitudTipoAperturaId = ko.observable();
            self.solicitudDetalle = ko.observable(false);
            self.usuarioPM = ko.observable(false);
            self.invitadoPM = ko.observable(false);
            self.tipoPersonaSeleccionada=ko.observable();
            self.personaSeleccionada = ko.observable();
            this.filtro = ko.observable();

            /** Catalogos */
            self.materias = ko.observableArray();
            self.tipoAperturas = ko.observableArray(
                [
                    {id: 1, clave: 'P', descripcion: 'Presencial', activo: true},
                    {id: 2, clave: 'L', descripcion: 'En Línea', activo: true}
                ]
            );

            self.estadoSolicitud = ko.observableArray([
                {value: 0, label: 'En Recepción'},
                {value: 1, label: "Por Determinar"}, 
                {value: 2, label: "Mediable"},
                {value: 3, label: "No Mediable"}
            ]);

            /** Data Providers */
            // this.dataProvider = new BufferingDataProvider(new ArrayDataProvider(self.solicitudes, {keyAttributes: 'id'}));
            this.materiasDP = new ArrayDataProvider(self.materias, {keyAttributes:'id'});
            this.tipoAperturaDP = new ArrayDataProvider(self.tipoAperturas, {keyAttributes: 'id'});
            this.estadoSolicitudDP = new ArrayDataProvider(self.estadoSolicitud, {keyAttributes: 'value'});

            this.dataProvider = ko.computed(()=>{
                let criterio = null;

                if (this.filtro() && this.filtro()!=''){
                    criterio = ojdataprovider_1.FilterFactory.getFilter({
                        filterDef: {text: this.filtro()}
                    })
                }

                const dataProvider = new ArrayDataProvider(self.solicitudes, {keyAttributes: 'id'});

                return new ListDataProviderView(dataProvider, {filterCriterion: criterio});
            }, this);

            /** variables y funciones Knockout */
            this.userInfoSignal = new signals.Signal();
            this.dataPDF = ko.observable();
            this.groupValid = ko.observable();

            self.mostrarForm = ko.computed(()=>{
                if (self.solicitudSeleccionada() || self.solicitudDetalle())
                    return true;
            });

            this.dateConverter = ((fecha)=>{
                return utils.parseFecha(fecha);
            });

            this.dateConverterInput = ko.observable(new ojconverter_datetime_1.IntlDateTimeConverter({
                timeZone: 'America/Mexico_City',
                pattern: 'dd/MM/yyyy'
            }));

            /** Eventos  */

            this.firstSelectedRowChangedListener = ((event) => {
                const itemContext = event.detail.value;

                if (itemContext && itemContext.data) {
                    const solicitud = itemContext.data;

                    self.parseSolicitud(solicitud);
                    self.solicitudDetalle(true);
                }
            });


            this.valueActionHandler = (event) => {
                const itemContext = event.detail.itemContext;
                const id = event.srcElement.id;

                if (itemContext && itemContext.data){
                    let item =  itemContext.data;

                    if (id==='selectMateria'){
                        self.solicitudMateria(item);
                    }

                    if (id==='selectTipoApertura'){
                        self.solicitudTipoApertura(item);
                    }
                    
                }
                
            };

            this.valueChangeHandler = (event) =>{
                const itemContext = event.detail;
                const id = event.srcElement.id;

                if (itemContext){
                    switch (id) {
                        case 'UsuarioPM': self.usuarioPM(itemContext.value); break;
                        case 'InvitadoPM': self.invitadoPM(itemContext.value); break;
                    }
                }
            }

            this.handleValueChanged = () =>{
                this.filtro(document.getElementById('filtro').rawValue);
            }

            self.moduleInfoPersona = ((tipo)=>{
                let viewPromise = ModuleElementUtils.createView({
                    viewPath: "views/mediacion/persona.html",
                });

                return viewPromise.then((personaView) => {
                    return {
                        view: personaView,
                        viewModel: {
                            persona: (tipo=='Usuario') ? self.solicitudUsuario : self.solicitudInvitado,
                            moral: (tipo=='Usuario') ? self.usuarioPM : self.invitadoPM,
                            tipoPersona: tipo,
                            valueChangeHandler: this.valueChangeHandler,
                            btnFindPersona: this.btnFindPersona,
                            btnPersonaDetalle: this.btnPersonaDetalle,
                            groupValid: this.groupValid
                        },
                    };
                }, (error) => {
                    Logger.error("Error during loading view: " + error.message);
                    return {
                        view: [],
                    };
                });
            });

            this.moduleDetallePersona = ModuleElementUtils.createConfig({name: 'catalogos/persona-detalle', params: {userInfoSignal: this.userInfoSignal}})

            this.requeridoValidator = [
                new RequiredValidator({
                    hint: "Dato Requerido",
                    messageDetail: "Proporcione el dato para el campo '{label}'",
                    messageSummary: "'{label}' es requerido",
                })
            ];

            this.curpValidator = [
                new AsyncRegExpValidator({
                    pattern: '^([A-Z][AEIOUX][A-Z]{2}\\d{2}(?:0[1-9]|1[0-2])(?:0[1-9]|[12]\\d|3[01])[HM](?:AS|B[CS]|C[CLMSH]|D[FG]|G[TR]|HG|JC|M[CNS]|N[ETL]|OC|PL|Q[TR]|S[PLR]|T[CSL]|VZ|YN|ZS)[B-DF-HJ-NP-TV-Z]{3}[A-Z\\d])(\\d)$',
                    messageDetail: 'Error en la CURP'
                })
            ];

            ko.computed(() => {
                this.userInfoSignal.dispatch(self.personaSeleccionada(),"mediacionSolicitud");
            }, this);


            this.connected = () => {
                accUtils.announce('Mediacion page loaded.', 'assertive');
                document.title = "Mediación";

                utils.waiting();

                Promise.all([
                    self.getMaterias(),
                    self.getSolicitudes()
                ]).finally(()=>{
                    utils.waiting(true);
                })

            };

            /**
             * Optional ViewModel method invoked after the View is disconnected from the DOM.
             */
            this.disconnected = () => {
                // Implement if needed
            };

            /**
             * Optional ViewModel method invoked after transition to the new View is complete.
             * That includes any possible animation between the old and the new View.
             */
            this.transitionCompleted = () => {
                // Implement if needed
            };

            self.parseSolicitud =((solicitud)=>{
                self.solicitudId(solicitud.id);
                self.solicitudFolio(solicitud.folio);
                self.solicitudFecha(solicitud.fechaSolicitud);
                self.solicitudEsMediable(solicitud.esMediable);
                self.solicitudCanalizada(solicitud.canalizado);
                self.solicitudUsuario(solicitud.usuarioPersona);
                self.usuarioPM(solicitud.usuarioPersona.personaMoral);
                self.solicitudInvitado(solicitud.invitadoPersona);
                self.invitadoPM(solicitud.invitadoPersona.personaMoral);
                self.solicitudMateria(solicitud.materia);
                self.solicitudMateriaId(solicitud.materia.id);
                self.solicitudFechaSesion(solicitud.fechaSesion);
                self.solicitudDescripcion(solicitud.descripcionConflicto);
                self.solicitudEstatus(solicitud.estatus);
                self.solicitudTipoApertura(solicitud.tipoApertura);
                self.solicitudTipoAperturaId(solicitud.tipoApertura.id);
            });

            self.fromSolicitud = (()=>{
                let solicitud = {
                    folio: 'NUEVA',
                    fechaSolicitud: self.solicitudFecha(),
                    esMediable: self.solicitudEsMediable(),
                    canalizado: self.solicitudCanalizada(),
                    usuarioPersona: self.solicitudUsuario(),
                    invitadoPersona: self.solicitudInvitado(),
                    materia: self.solicitudMateria(),
                    descripcionConflicto: self.solicitudDescripcion(),
                    estatus: self.solicitudEstatus(),
                    tipoApertura: self.solicitudTipoApertura()
                }

                return solicitud;
            });

            self.solicitudDetalle.subscribe((data)=>{
                if (data){
                    $('#solicitudes').hide();
                    return;
                }

                $('#solicitudes').show();
            });

            /** Botones */

            self.btnNuevaSolicitud = ((event)=>{
                self.solicitudDetalle(true);
                self.getJSONTemp();
            });
            
            self.btnPersonaDetalle= ((event)=>{

                const target = event.srcElement.id;

                if (!target){
                    return false;
                }

                const tipoPersona = target.replace("detalle","");

                self.personaSeleccionada(null);
                self.tipoPersonaSeleccionada(tipoPersona);

                if (tipoPersona=='Usuario'){
                    self.personaSeleccionada(self.solicitudUsuario());
                }

                if (tipoPersona=='Invitado'){
                    self.personaSeleccionada(self.solicitudInvitado());
                }

                document.getElementById("modalPersona").open();
            });

            self.btnGuardarSolicitud = ((event)=>{
                const valid = this._checkValidationGroup();

                if (!valid) {
                    return false;
                }

                self.postSolicitud();
            });

            self.btnCancelarSolicitud = (()=>{
                const element = document.getElementById('solicitudes');
                const currentRow = element.currentRow;

                if(currentRow) {                   
                    element.selected = { row: new ojkeyset_1.KeySetImpl(), column: new ojkeyset_1.KeySetImpl() };
                }
                
                self.solicitudSeleccionada(null);
                self.solicitudDetalle(false);
                self.personaSeleccionada(null);
                self.tipoPersonaSeleccionada(null);
            });

            self.btnEditarSolicitud = ((event, detail)=>{

                self.solicitudDetalle(true);
                self.solicitudSeleccionada({key: detail.item.key, data:detail.item.data});
                self.parseSolicitud(detail.item.data);              

                const element = document.getElementById('solicitudes');
                const seleccion = { 
                    row: new ojkeyset_1.KeySetImpl([detail.key]), 
                    column: new ojkeyset_1.KeySetImpl([detail.columnIndex]) };

                element.selected = seleccion;
            });

            this.btnClose=(event, detail)=> {
                const modalId = event.srcElement.offsetParent.id;

                if (modalId){
                    if (modalId == 'modalPersona'){
                        const url = config.baseEndPoint + '/personas/' + self.personaSeleccionada().id;

                        self.getPersona(url).then((response)=>{
                            if (self.tipoPersonaSeleccionada()=='Usuario'){
                                self.solicitudUsuario(response);
                            }

                            if (self.tipoPersonaSeleccionada()=='Invitado'){
                                self.solicitudInvitado(response);
                            }
                        }).catch((errors)=>{
                            console.log(errors);
                        });
                    }
                    document.getElementById(modalId).close();
                }
            }

            this.btnOpen= (event, detail) => {
                let solicitud;

                if (event.srcElement.id == "btnImprimir"){
                    solicitud = self.solicitudSeleccionada().data;
                }else{
                    solicitud = detail.item.data;
                }

                self.getReporte(solicitud).then(result => {
                    document.getElementById("modalPDF").open();
                })
                .catch(response => {
                    swal(response.message, JSON.stringify(response.errors), "error");
                });
            }

            self.btnFindPersona = ((event)=>{

                const tipoPersona = event.srcElement.id;

                self.personaSeleccionada(null);
                self.tipoPersonaSeleccionada(tipoPersona.replace("busca",""));

                const inputValor = new Promise((resolve, reject )=>{
                    swal({
                        title:"Buscar Persona",
                        content:{
                            element: "input",
                            attributes: {
                                placeholder:"CURP o RFC",
                                type: "text"
                            },
                        },
                    }).then((respuesta)=>{
                        if (respuesta && respuesta.length>0){
                            resolve(respuesta);
                        }else{
                            reject(null);
                        }
                    });
                });
                
                inputValor.then((data)=>{
                    const url = config.baseEndPoint + "/personas/find?value="+data;

                    self.getPersona(url).then((resolve, reject)=>{
                        utils.confirmar('Persona encontrada', `¿Selecciona a ${data} - ${resolve.nombreCompleto} como - ${self.tipoPersonaSeleccionada()}?`)
                            .then((confirmacion)=>{
                                if(confirmacion){
                                    if (this.tipoPersonaSeleccionada()=='Usuario'){
                                        self.solicitudUsuario(resolve);
                                    }
                                    
                                    if (this.tipoPersonaSeleccionada()=='Invitado'){
                                        self.solicitudInvitado(resolve);
                                    }
                                }
                            })
                            .catch((errors)=>{
                                swal('Persona', JSON.stringify(errors), 'error');
                            });
                    }).catch((errors)=>{
                        console.log(errors);
                    });
                });
                
            });

            /** REST */
            self.getSolicitudes = (()=>{
                const url = self.urlBase + '/solicitud';
                self.solicitudes([]);

                return utils.getData(url, {}).then((response) => {
                    if (response.success){
                        self.solicitudes(response.data);
                    }
                });
            });

            self.getMaterias = (()=>{
                const url = config.baseEndPoint + '/materias';
                
                return utils.getData(url, {}).then((response)=>{
                    if (response.success){
                        self.materias(response.data);
                    }
                });
            });

            self.getJSONTemp=(()=>{
                const url = self.urlBase + '/solicitud/template';

                utils.getData(url,{}).then((response)=>{
                    if (response.success){
                        self.solicitudSeleccionada(response.data);
                        self.parseSolicitud(response.data);
                    }
                })
            });
 
            self.postSolicitud =(()=>{
                const url = self.urlBase + '/solicitud/add';
                const data = self.fromSolicitud();

                utils.confirmar('Solicitud').then((confirmacion)=>{
                    if (confirmacion){
                        utils.postData(url, data).then((response)=>{                    
                            if (response.success){
                                const folio = response.data.folio;
        
                                self.getSolicitudes();
                                self.solicitudId(response.data.id);
                                swal("Solicitud Registrada","Folio: " + folio, "success");
        
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

            self.getReporte = ((data)=>{
                const params = {
                    "p_solicitud_id": data.id
                };

                const url = config.baseEndPoint + '/reportes/MediacionSolicitud';

                this.dataPDF(null);

                return new Promise ((resolve, reject)=>{
                    utils.getReporte(url, params).then((response)=>{

                        if (response.hasOwnProperty("error")){    
                            reject(response);
                        }
    
                        const blobUrl = URL.createObjectURL(response);
    
                        this.dataPDF(blobUrl+"#view=FitH");
    
                        resolve(true);
    
                    }).catch(errors =>{
                        swal("Error", JSON.stringify(errors), "error")
                    });
                });

            });

            self.getPersona=((url)=>{

                if (url){
                    utils.waiting();

                    return new Promise((resolve, reject) => {
                        utils.getData(url, {})
                        .then((response)=>{
                            utils.waiting(true);

                            if (response.success){
                                resolve(response.data);
                            }else{
                                swal('Persona', JSON.stringify(response.message), 'error');
                                reject(response.errors);
                            }
                        })
                        .catch((errors)=>{
                            utils.waiting(true);
                            swal('Persona', JSON.stringify(errors), 'error');
                        });
                    });
                }
            });

        }

        _checkValidationGroup() {
            const solicitud = document.getElementById('trackerSolicitud');
            const usuario = document.getElementById('trackerUsuario');
            const invitado = document.getElementById('trackerInvitado');

            if (solicitud.valid === 'valid' && usuario.valid === 'valid' && invitado.valid === 'valid') {
                return true;
            }
            else {
                solicitud.showMessages();
                usuario.showMessages();
                invitado.showMessages();

                //tracker.focusOn('@firstInvalidShown');
                return false;
            }
        }
     }

    /*
     * Returns an instance of the ViewModel providing one instance of the ViewModel. If needed,
     * return a constructor for the ViewModel so that the ViewModel is constructed
     * each time the view is displayed.
     */
    return MediacionViewModel;
  }
);