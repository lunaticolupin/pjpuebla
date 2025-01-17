define(['../accUtils', 'jquery', 'webConfig', 'utils', 'knockout', 'ojs/ojarraydataprovider', 'ojs/ojkeyset', 'ojs/ojconverter-datetime',
    'ojs/ojmodule-element-utils', 'ojs/ojasyncvalidator-regexp', 'ojs/ojvalidator-required', 'signals', 'ojs/ojlistdataproviderview', 'ojs/ojdataprovider', 'text!models/mediacion.json', 'ojs/ojfilepickerutils',
    'ojs/ojknockout', 'oj-c/button', 'ojs/ojtable', 'oj-c/form-layout', 'oj-c/input-text', 'ojs/ojdatetimepicker', 'oj-c/select-single', 'ojs/ojvalidationgroup', 'sweetalert',
    'oj-c/text-area', 'ojs/ojtoolbar', 'oj-c/radioset', 'ojs/ojradioset', 'ojs/ojtoolbar', "oj-c/list-item-layout", "oj-c/list-view", "ojs/ojswitch", "ojs/ojoption", "ojs/ojmodule-element"
],
    function (accUtils, $, config, utils, ko, ArrayDataProvider, ojkeyset_1, ojconverter_datetime_1, ModuleElementUtils, AsyncRegExpValidator, RequiredValidator,
        signals, ListDataProviderView, ojdataprovider_1, catalogos_json, FilePickerUtils) {
        class MediacionViewModel {
            constructor() {
                var self = this;
                var rootViewModel = ko.dataFor(document.getElementById('globalBody'));

                self.catalogos = JSON.parse(catalogos_json);

                rootViewModel.validaSesion();

                self.urlBase = config.baseEndPoint + '/mediacion';

                console.log("urlbase",this.urlBase)
                this.ModuleElementUtils = ModuleElementUtils;
                /** Observables */ 
                self.solicitudes = ko.observableArray();
                self.solicitudSeleccionada = ko.observable();

                self.solicitudId = ko.observable();
                self.solicitudFolio = ko.observable();
                self.solicitudFecha = ko.observable();
                self.solicitudEsMediable = ko.observable();
                self.solicitudCanalizada = ko.observable(false);
                self.solicitudUsuario = ko.observable({ nombre: "", apellidoPaterno: "", apellidoMaterno: "" });
                self.solicitudInvitado = ko.observable({ nombre: "", apellidoPaterno: "", apellidoMaterno: "" });
                self.solicitudMateria = ko.observable();
                self.solicitudMateriaId = ko.observable();
                self.solicitudFechaSesion = ko.observable();
                self.solicitudDescripcion = ko.observable();
                self.solicitudEstatus = ko.observable();
                self.solicitudTipoApertura = ko.observable();
                self.solicitudTipoAperturaId = ko.observable();
                self.solicitudDetalle = ko.observable(false);
                self.solicitudMediable = ko.observable();
                self.solicitudCanalizada = ko.observable();
                self.institucion_seleccionada = ko.observable("");
                self.usuarioPM = ko.observable(false);
                self.invitadoPM = ko.observable(false);
                self.tipoPersonaSeleccionada = ko.observable();
                self.personaSeleccionada = ko.observable();
                self.solicitudProtocoloViolencia = ko.observable();
                self.estatusSolicitudDisabled = ko.observable();
                self.descripcionNoMediable = ko.observable();
                self.id_canalizacion = ko.observable();
                self.solicitudCanalizacion = ko.observable({});
                self.solicitudAsistencia = ko.observable({});
                self.asistencias = ko.observableArray();
                self.asistenciaSeleccionada = ko.observableArray();
                self.solicitudArchivos = ko.observableArray();
                self.archivoSeleccionado = ko.observable();
                self.esMediableDP = ko.observable()
                
            
                /* Funciones flecha para mostrar o ocultar formularios  */
                self.solicitudCanalizada.subscribe((value) => {
                    console.log("shusus",self.solicitudMediable())
                    // console.log("shusus",self.esMediableDP())
                    if (!self.documentos().some(item => item.nombre_documento == 'CANALIZACIÓN')) {
                        if (value) {
                            const documento = self.formatos().find(item => item.clave == 'F006');
                            addDocument(null, documento.descripcion, null, false, documento.esAcuse, documento.id);
                        }
                        
                    }
                    // value ? addDocument(8, "Canalización", true, "") : self.documentos.remove((item) => item.label === 'Canalización');
                });

                /** Catalogos */
                self.materias = ko.observableArray();
                self.instituciones = ko.observableArray();
                self.mediadores = ko.observableArray();
                self.tipoAperturas = self.catalogos.aperturas
                self.estadoSolicitud = ko.observableArray(self.catalogos.estadosSolicitudes);
                self.esMediableArray = self.catalogos.esMediable;
                self.protocoloViolencia = self.catalogos.protocolosViolencia;
                self.formatos = ko.observableArray();
                self.formatos_selected = ko.observableArray();
                self.documentos = ko.observableArray([]);
                self.formatoSeleccionado = ko.observable();

                self.mediadorSeleccionado  = ko.observable();

                /** variables y funciones Knockout */
                this.userInfoSignal = new signals.Signal();
                this.asistenciaInfoSignal = new signals.Signal();
                this.dataPDF = ko.observable();
                this.groupValid = ko.observable();
                this.frameHabilitado = rootViewModel.pdfViewerEnable;
                this.filtro = ko.observable();

                /** Data Providers */
                // this.dataProvider = new BufferingDataProvider(new ArrayDataProvider(self.solicitudes, {keyAttributes: 'id'}));
                this.materiasDP = new ArrayDataProvider(self.materias, { keyAttributes: 'id' });
                this.tipoAperturaDP = new ArrayDataProvider(self.tipoAperturas, { keyAttributes: 'id' });
                this.estadoSolicitudDP = new ArrayDataProvider(self.estadoSolicitud, { keyAttributes: 'value' });
                this.esMediableDP = new ArrayDataProvider(self.esMediableArray, { keyAttributes: 'value' });
                this.protocoloViolenciaDP = new ArrayDataProvider(self.protocoloViolencia, { keyAttributes: 'value' });
                this.mediadoresDP = new ArrayDataProvider(self.mediadores, { keyAttributes: 'value' });
                this.institucionesDP = new ArrayDataProvider(self.instituciones, { keyAttributes: 'value' });
                this.asistenciasDP = new ArrayDataProvider(self.asistencias, { keyAttributes: 'id' });
                this.documentosDP = ko.computed(() => new ArrayDataProvider(self.documentos(), { keyAttributes: 'value' }));
                this.formatosDP = new ArrayDataProvider(self.formatos_selected, { keyAttributes: 'value' })
                this.dataProvider = ko.computed(() => {
                    let criterio = null;

                    if (this.filtro() && this.filtro() != '') {
                        criterio = ojdataprovider_1.FilterFactory.getFilter({
                            filterDef: { text: this.filtro() }
                        })
                    }

                    const dataProvider = new ArrayDataProvider(self.solicitudes, { keyAttributes: 'id' });

                    return new ListDataProviderView(dataProvider, { filterCriterion: criterio });
                }, this);

                this.dateConverter = (fecha) => utils.parseFecha(fecha);

                this.dateConverterInput = ko.observable(new ojconverter_datetime_1.IntlDateTimeConverter({
                    timeZone: 'America/Mexico_City',
                    pattern: 'dd/MM/yyyy'
                }));

                this.dateTimeConverterInput = ko.observable(new ojconverter_datetime_1.IntlDateTimeConverter({
                    timeZone: 'America/Mexico_City',
                    pattern: 'dd/MM/yyyy HH:mm'
                }));

                this.maxFecha = new Date().toISOString();
                this.minFecha = ko.computed(() => {
                    let d = new Date();
                    let numDias = 1;

                    if (d.getDay() == 1) {
                        numDias = 3;
                    }

                    d.setDate(d.getDate() - numDias);

                    return d.toISOString().split('T')[0];
                }, this);



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

                    if (itemContext && itemContext.data) {
                        let item = itemContext.data;

                        if (id === 'selectMateria') {
                            self.solicitudMateria(item);
                        }

                        if (id === 'selectTipoApertura') {
                            self.solicitudTipoApertura(item);
                        }

                    }

                };

                this.valueChangeHandler = (event) => {
                    const itemContext = event.detail;
                    const id = event.srcElement.id;

                    if (itemContext) {
                        switch (id) {
                            case 'UsuarioPM': self.usuarioPM(itemContext.value); break;
                            case 'InvitadoPM': self.invitadoPM(itemContext.value); break;
                        }
                    }
                }

                this.handleValueChanged = () => {
                    this.filtro(document.getElementById('filtro').rawValue);
                }

                this.moduleInfoPersona = ((tipo) => {
                    let viewPromise = ModuleElementUtils.createView({
                        viewPath: "views/mediacion/persona.html",
                    });

                    return viewPromise.then((personaView) => {
                        return {
                            view: personaView,
                            viewModel: {
                                persona: (tipo == 'Usuario') ? self.solicitudUsuario : self.solicitudInvitado,
                                moral: (tipo == 'Usuario') ? self.usuarioPM : self.invitadoPM,
                                tipoPersona: tipo,
                                valueChangeHandler: this.valueChangeHandler,
                                btnFindPersona: this.btnFindPersona,
                                btnPersonaDetalle: this.btnPersonaDetalle,
                                groupValid: this.groupValid,
                                curpValidator: this.curpValidator
                            },
                        };
                    }, (error) => {
                        Logger.error("Error during loading view: " + error.message);
                        return {
                            view: [],
                        };
                    });
                });


                //agregar mediador y generar expediente
                self.generar_expediente = () => {
                    if(!self.mediadorSeleccionado()){
                        swal('Error: mediador no seleccionado', 'Es necesario seleccionar un mediador a asignar', 'warning');
                        return false;
                    }
                    
                    utils.confirmar('Mediador', '¿Esta usted seguro(a) de asignar este mediador y generar numero de expediente?').then(response =>{
                        const url = config.baseEndPoint + '/mediacion/expediente/create';
                        const data = {
                            solicitud_id: self.solicitudId(),
                            mediador_id: self.mediadorSeleccionado(),
                            solicitud_mediable: self.solicitudMediable()
                        } 
                        if(response){
                            utils.postDataFiles(url, data).then((response) => {

                                console.log(response);
                                
                                if (response.success) {
                                    swal('Exito', 'Mediador asignado con éxito', 'success')
                                    comprobarArchivos();
                                    return true;
                                }
                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");

                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                        
                    });
                }
                //fin mediador y expediente

                self.agregar_formato = () => {
                    if(!self.formatoSeleccionado()){
                        swal('Error: documento no seleccionado', 'Es necesario seleccionar un docuemnto a agregar', 'warning');
                        return false;
                    }
                    
                    utils.confirmar('Documento', '¿Esta usted seguro(a) de agregar el documento seleccionado?').then(response =>{
                        const url = config.baseEndPoint + '/archivos/create';
                        const data = {
                            solicitud_id: self.solicitudId(),
                            formato_id:self.formatoSeleccionado(),
                            usuario_creo: 'TEXT'
                        } 

                        console.log(data);

                        
                        if(response){
                            utils.postDataFiles(url, data).then((response) => {

                                console.log(response);
                                
                                if (response.success) {
                                    swal('Exito', 'El archivo ha sido agregado exitosamente', 'success')
                                    comprobarArchivos();
                                    return true;
                                }
                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");

                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                        
                    });
                }

                this.moduleDetallePersona = ModuleElementUtils.createConfig(
                    {
                        name: 'catalogos/persona-detalle',
                        params: {
                            userInfoSignal: this.userInfoSignal
                        }
                    })

                this.moduleDetalleAsistencia = ModuleElementUtils.createConfig(
                    {
                        name: 'mediacion/asistencia-detail',
                        params: { asistenciaInfoSignal: self.asistenciaInfoSignal }
                    });

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

                this.rfcValidator = [
                    new AsyncRegExpValidator({
                        pattern: '([A-ZÑ]|\\&){3,4}[0-9]{2}(0[1-9]|1[0-2])([12][0-9]|0[1-9]|3[01])[A-Z0-9]{3}$',
                        messageDetail: 'Error en el RFC'
                    })
                ];

                ko.computed(() => {
                    this.userInfoSignal.dispatch(self.personaSeleccionada(), "mediacionSolicitud");
                }, this);

                ko.computed(() => {
                    this.asistenciaInfoSignal.dispatch(self.asistenciaSeleccionada(), self.solicitudId());
                }, this)


                self.solicitudMediable.subscribe((value) => {   
                    console.log("val",value)
                    
                    self.solicitudProtocoloViolencia(null);
                    self.estadoSolicitud.removeAll();
                    switch (value) {
                        case 0:

                            self.estadoSolicitud([
                                { value: 0, label: 'En Recepción' },
                                { value: 1, label: 'En Dirección' }
                            ]);
                            self.estatusSolicitudDisabled(false);
                            self.solicitudCanalizada(false)
                            console.log(self.solicitudCanalizada())
                            break;

                        case 1:

                            self.estadoSolicitud([  
                                { value: 0, label: 'En Recepción' },
                                { value: 1, label: 'En Dirección' },
                                { value: 2, label: "Mediable" },
                                { value: 3, label: "No Mediable" },
                                { value: 4, label: "1ra invitación" },
                                { value: 5, label: "2da invitación" }
                            ])
                            self.estatusSolicitudDisabled(true);
                            self.solicitudCanalizada(false)

                            console.log(self.solicitudCanalizada())
                            break;

                        case 2:
                            self.estadoSolicitud([ { value: 3, label: "No Mediable" } ]);
                            self.solicitudEstatus(3);
                            self.estatusSolicitudDisabled(true);
                            break;
                    }
                })


                this.connected = () => {
                    accUtils.announce('Mediacion page loaded.', 'assertive');
                    document.title = "Mediación";

                    utils.waiting();

                    Promise.all([
                        self.getMaterias(),
                        self.getSolicitudes(),
                        self.getInstituciones(),
                        self.getMediadores(),
                        self.getFormatos()
                    ]).finally(() => {
                        utils.waiting(true);
                    });
                };

                self.parseSolicitud = (async (solicitud) => {
                    //limpeamos variable.
                    self.formatoSeleccionado(null);
                    self.solicitudId(solicitud.id);
                    self.solicitudFolio(solicitud.folio);
                    self.solicitudFecha(solicitud.fechaSolicitud);
                    self.solicitudMediable(solicitud.esMediable);
                    self.solicitudCanalizada(solicitud.canalizado);
                    self.solicitudUsuario(solicitud.usuarioPersona);
                    self.usuarioPM(solicitud.usuarioPersona.personaMoral);
                    self.solicitudInvitado(solicitud.invitadoPersona);
                    self.invitadoPM(solicitud.invitadoPersona.personaMoral);
                    self.solicitudMateria(solicitud.materia);
                    self.solicitudMateriaId(solicitud.materia.id);

                    self.solicitudDescripcion(solicitud.descripcionConflicto);

                    self.solicitudEstatus(solicitud.estatus);
                    self.solicitudTipoApertura(solicitud.tipoApertura);
                    self.solicitudTipoAperturaId(solicitud.tipoApertura.id);;

                    if (solicitud.id) {
                        //definiendo variables de canalización:
                        if (solicitud.canalizacion) {
                            self.id_canalizacion(solicitud.canalizacion.id);
                            self.descripcionNoMediable(solicitud.canalizacion.descripcion);
                            self.institucion_seleccionada(solicitud.canalizacion.institucion ? solicitud.canalizacion.institucion.id : '');
                        }

                        //Configurando fecha de sesión:

                        if (solicitud.fechaSesion) {
                            self.solicitudFechaSesion(new Date(solicitud.fechaSesion).toISOString());
                        } else { self.solicitudFechaSesion("") }
                    

                        //configurando asistencias /citas:
                        await self.getAsistencias();

                        //Configurando archivos
                        comprobarArchivos();
                    }


                });

                async function comprobarArchivos() {
                    // llamamos a los archivos que tenemos:
                    const url = config.baseEndPoint + '/archivos/list?solicitud_id=' + self.solicitudId();
                    const data = { solicitud_id: self.solicitudId() };
                    self.documentos.removeAll();
                    try {
                        const response = await utils.getData(url, data);
                        response.data.forEach(element => {
                            addDocument(element.archivoId, element.formatoDescripcion, element.fechaCreacion, element.existeDocumento, element.esAcuse, element.formatoId, element.solicitudArchivoId);
                        });


                    } catch (error) {
                        console.error("Error al obtener los archivos:", error);
                    }
                }

                function addDocument(id_documento, nombre_documento, fecha_creacion, existeDocumento = false, esAcuse = false, formatoId, solicitudArchivoID) {
                    // Verifica si ya existe un documento con el mismo formato

                    var exists = self.documentos().some(doc => doc.formatoId == formatoId);

                    // Si no existe, entonces realiza el push
                    if (!exists) {
                        self.documentos.push({
                            id_documento: id_documento,
                            nombre_documento: nombre_documento,
                            fecha_creacion: fecha_creacion,
                            existeDocumento: existeDocumento,
                            esAcuse: esAcuse,
                            formatoId: formatoId,
                            solicitudArchivoID: solicitudArchivoID
                        });
                    }
                }


                self.handleDialogClose = () => { self.getAsistencias(); };


                self.fromSolicitud = (() => {
                    let solicitud = {
                        folio: 'NUEVA',
                        fechaSolicitud: self.solicitudFecha(),
                        esMediable: self.solicitudMediable(),
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

                self.solicitudDetalle.subscribe((data) => {
                    if (data) {
                        $('#solicitudes').hide();
                        return;
                    }

                    $('#solicitudes').show();
                });

                self.generar_invitacion = () => {
                    var url_template = self.urlBase + '/asistencias/template';
                    var url_add = self.urlBase + '/asistencias/add';
                    var template = {}

                    utils.getData(url_template, {}).then((response) => {

                        if (response.success) {
                            utils.confirmar('Invitación', '¿Desea generar una nueva invitación?').then((confirmacion) => {
                                if (confirmacion) {
                                    template = response.data;
                                    template.solicitud = { id: self.solicitudId() };
                                    utils.postData(url_add, template).then((response) => {
                                        if (response.success) {
                                            swal("Invitación generada", "Se ha generado una nueva invitación", "success");
                                                self.getAsistencias();
                                                comprobarArchivos()
                                            return true;
                                        }
                                        const errores = JSON.stringify(response.errors);
                                        swal(response.message, errores, "error");
                                    }).catch((response) => {
                                        const errores = JSON.stringify(response);

                                        swal("Error al procesar la petición", errores, "error");
                                    });
                                }

                            })

                        }
                    })
                }

                self.invitacionActiva = ko.computed(() => {
                    const today = new Date().toISOString(); // Obtener la fecha y hora actuales en formato ISO completo
                    const selectedDate = self.solicitudFechaSesion() ?
                        new Date(self.solicitudFechaSesion()).toISOString() :
                        "";

                    console.log(today);
                    console.log(selectedDate);
                    console.log(today <= selectedDate);
                    
                    
                    
                    return today <= selectedDate; // Compara fecha y hora completas
                });

                /*
                self.solicitudProtocoloViolencia.subscribe((data) => {

                    switch (data) {
                        case "CV": self.solicitudMediable(2); break;
                        case "DV": self.solicitudMediable(1); break;
                        default: self.solicitudMediable(1);
                    }
                })
                    */

                /** Botones */

                self.btnNuevaSolicitud = ((event) => {
                    self.solicitudDetalle(true);
                    self.getJSONTemp();
                });

                self.btnPersonaDetalle = ((event) => {

                    const target = event.srcElement.id;

                    if (!target) {
                        return false;
                    }

                    const tipoPersona = target.replace("detalle", "");

                    self.personaSeleccionada(null);
                    self.tipoPersonaSeleccionada(tipoPersona);

                    if (tipoPersona == 'Usuario') {
                        self.personaSeleccionada(self.solicitudUsuario());
                    }

                    if (tipoPersona == 'Invitado') {
                        self.personaSeleccionada(self.solicitudInvitado());
                    }

                    document.getElementById("modalPersona").open();
                });

                self.btnGuardarSolicitud = ((event) => {
                    const valid = this._checkValidationGroup();

                    if (!valid) {
                        return false;
                    }

                    self.solicitudId() ? self.putSolicitud() : self.postSolicitud();
                });

                self.btnCancelarSolicitud = (() => {
                    const element = document.getElementById('solicitudes');
                    const currentRow = element.currentRow;

                    if (currentRow) {
                        element.selected = { row: new ojkeyset_1.KeySetImpl(), column: new ojkeyset_1.KeySetImpl() };
                    }

                    self.solicitudSeleccionada(null);
                    self.solicitudDetalle(false);
                    self.personaSeleccionada(null);
                    self.tipoPersonaSeleccionada(null);
                });

                self.btnEditarSolicitud = ((event, detail) => {
                    const url = config.baseEndPoint + '/mediacion/solicitud/getExpedienteMediador';
                        const data = {
                            solicitud_id: detail.item.data.id
                        }
                        utils.postDataFiles(url, data).then((response) => {

                            console.log("SOLMED",response.data.mediador);
                            
                            if (response.message == 'OK') {
                                self.mediadorSeleccionado(response.data.mediador.id)
                                // this.mediadorSeleccionado = response.data.mediador.id;
                                console.log("mediador",this.mediadorSeleccionado)
                                console.log("selfmediador",self.mediadorSeleccionado())
                                // self.mediadorSeleccionado() = response.data.mediador.id;   
                            }else {
                                this.mediadorSeleccionado = ''
                            }
                            // const errores = JSON.stringify(response.errors);
                            // swal(response.message, errores, "error");

                        })
                        // .catch((response) => {
                        //     const errores = JSON.stringify(response);

                        //     swal("Error al procesar la petición", errores, "error");
                        // });

                    //Funcionalidad boton editar
                    self.solicitudDetalle(true);
                    self.solicitudSeleccionada({ key: detail.item.key, data: detail.item.data });
                    self.parseSolicitud(detail.item.data);

                    const element = document.getElementById('solicitudes');
                    const seleccion = {
                        row: new ojkeyset_1.KeySetImpl([detail.key]),
                        column: new ojkeyset_1.KeySetImpl([detail.columnIndex])
                    };

                    element.selected = seleccion;
                    // console.log("id_solicitus",detail.item.data.id)
                });

                this.btnClose = (event, detail) => {
                    const modalId = event.srcElement.offsetParent.id;

                    if (modalId) {
                        if (modalId == 'modalPersona') {
                            const url = config.baseEndPoint + '/personas/' + self.personaSeleccionada().id;

                            self.getPersona(url).then((response) => {
                                if (self.tipoPersonaSeleccionada() == 'Usuario') {
                                    self.solicitudUsuario(response);
                                }

                                if (self.tipoPersonaSeleccionada() == 'Invitado') {
                                    self.solicitudInvitado(response);
                                }
                            }).catch((errors) => {
                                console.log(errors);
                            });
                        }
                        document.getElementById(modalId).close();
                    }
                }

                this.btnOpen = (event, detail) => {
                    let solicitud;
                    const element = event.srcElement.id;
                    const nombre_reporte = self.formatos().find(item => item.id == detail.data.formatoId).nombreReporte
                    detail.data.nombreReporte = nombre_reporte

                    if (element == "btnImprimir") {
                        solicitud = self.solicitudSeleccionada().data;
                    } else {
                        solicitud = detail.item.data;
                    }

                    self.getReporte(solicitud, detail.data).then(response => {
                        this.dataPDF(response);

                        if (this.frameHabilitado()) {
                            document.getElementById("modalPDF").open();
                            return true;
                        }


                        document.getElementById("btnDescargarPdf").click();
                    })
                        .catch(error => {
                            console.log(error);
                            swal(error.message, JSON.stringify(error.errors), "error");
                        });
                }

                this.selectListener = (files) => {
                    const registro = self.archivoSeleccionado();
                    const url = config.baseEndPoint + '/archivos/upload';
                    const fileData = {
                        file: files[0],
                        solicitud_id: self.solicitudId(),
                        formato_id: registro.formatoId,
                        usuario_creo: 'testing-front',
                        archivo_id: registro.id_documento
                    }



                    utils.confirmar('Archivo', '¿Desea subir el archivo ' + fileData.file.name + ' ?').then((confirmacion) => {

                        if (confirmacion) {
                            utils.postDataFiles(url, fileData).then((response) => {
                                if (response.success) {

                                    swal("Archivo Cargado", "El archivo se ha cargado exitosamente.", "success");
                                    comprobarArchivos();
                                    return true;
                                }

                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");
                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                    });


                };

                self.btnUploadFile = (event, detail) => {

                    self.archivoSeleccionado(detail.data);


                    FilePickerUtils.pickFiles(this.selectListener, {
                        accept: [],
                        capture: "none",
                        selectionMode: "single",
                    });
                }


                self.btnVerDocumento = (event, detail) => {
                    const url = config.baseEndPoint + '/archivos/download/' + detail.data.id_documento
                    let data = { id: detail.data.id_documento }

                    utils.getDocument(url, data).then(response => {
                        if (response) {
                            const { blob, fileName } = response;

                            // Crear un enlace de descarga
                            const downloadUrl = window.URL.createObjectURL(blob);
                            const a = document.createElement("a");
                            a.href = downloadUrl;
                            a.download = fileName; // Usar el nombre del archivo extraído del header
                            document.body.appendChild(a);
                            a.click();

                            // Remover el enlace después de la descarga
                            a.remove();
                            window.URL.revokeObjectURL(downloadUrl);
                            console.log('ya obtuve el documento.');
                            
                        } else {
                            console.error("No se pudo obtener el documento.");
                        }
                    });
                }

                self.btnEliminarDocumento = (event, detail) => {
                    const url = config.baseEndPoint + '/archivos/delete'
                    let data = { 
                        archivoId: detail.data.id_documento,
                        solicitudArchivoId: detail.data.solicitudArchivoID,
                        usuarioActualizo: 'TEST' };

                        console.log( detail.data);
                        

                    utils.confirmar('Confirmación', '¿Desea eliminar el archivo cargado?').then((response) => {
                        if (response) {
                            utils.postData(url, data).then((response) => {
                                if (response.success) {
                                    swal('Exito', 'El archivo ha sido eliminado exitosamente', 'success')
                                    comprobarArchivos();
                                    return true;
                                }
                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");

                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });


                        }

                    })
                }

                this.btnOpenDetailAsistencia = (event, detail) => {
                    self.asistenciaSeleccionada(detail.item.data);
                    document.getElementById("modalAsistencia").open();
                }

                self.btnFindPersona = ((event) => {

                    const tipoPersona = event.srcElement.id;

                    self.personaSeleccionada(null);
                    self.tipoPersonaSeleccionada(tipoPersona.replace("busca", ""));

                    const inputValor = new Promise((resolve, reject) => {
                        swal({
                            title: "Buscar Persona",
                            content: {
                                element: "input",
                                attributes: {
                                    placeholder: "CURP o RFC",
                                    type: "text"
                                },
                            },
                        }).then((respuesta) => {
                            if (respuesta && respuesta.length > 0) {
                                resolve(respuesta);
                            } else {
                                reject(null);
                            }
                        });
                    });

                    inputValor.then((data) => {
                        const url = config.baseEndPoint + "/personas/find?value=" + data;

                        self.getPersona(url).then((resolve, reject) => {
                            utils.confirmar('Persona encontrada', `¿Selecciona a ${data} - ${resolve.nombreCompleto} como - ${self.tipoPersonaSeleccionada()}?`)
                                .then((confirmacion) => {
                                    if (confirmacion) {
                                        if (this.tipoPersonaSeleccionada() == 'Usuario') {
                                            self.solicitudUsuario(resolve);
                                        }

                                        if (this.tipoPersonaSeleccionada() == 'Invitado') {
                                            self.solicitudInvitado(resolve);
                                        }
                                    }
                                })
                                .catch((errors) => {
                                    swal('Persona', JSON.stringify(errors), 'error');
                                });
                        }).catch((errors) => {
                            console.log(errors);
                        });
                    });

                });

                /** REST */
                self.getSolicitudes = (() => {
                    const url  = self.urlBase + '/solicitud';
                    self.solicitudes([]);

                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            self.solicitudes(response.data);
                        }
                    });
                });

                self.getAsistencias = () => {
                    const url = self.urlBase + '/asistencias/findBySolicitudId/' + self.solicitudId();
                    self.asistencias([]);

                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            self.asistencias(response.data);
                           
                        }
                    })
                };

                self.getMaterias = (() => {
                    const url = config.baseEndPoint + '/materias';

                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            self.materias(response.data);
                        }
                    });
                });

                self.getInstituciones = (() => {
                    const url = config.baseEndPoint + '/instituciones/activas'
                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            let instituciones_temp = []
                            instituciones_temp.push({ value: '', label: 'Sin asignación' })
                            response.data.forEach(element => {
                                instituciones_temp.push({ value: element.id, label: element.nombre });
                            });
                            self.instituciones(instituciones_temp);
                        }
                    })
                })

                self.getMediadores = (() => {
                    const url = config.baseEndPoint + '/mediacion/mediadores/activos'
                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            let mediadores_temp = [];

                            mediadores_temp.push({ value: '', label: 'No aplica' });

                            response.data.forEach(element => {
                                mediadores_temp.push({ value: element.id, label: element.usuario.nombreCompleto });
                            });
                            self.mediadores(mediadores_temp);
                        }
                    })
                })

                self.getFormatos = (() => {
                    const url = config.baseEndPoint + '/formatos'
                    console.log("urllllllllllll",url)
                    return utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            let formatos_temp = [];

                            self.formatos(response.data);
                            response.data.forEach(element => {
                                formatos_temp.push({ value: element.id, label: element.descripcion })
                            });
                            console.log(formatos_temp);
                            
                            self.formatos_selected(formatos_temp)


                            console.log(self.formatos_selected());
                            
                        }
                    })
                })


                self.getJSONTemp = (() => {
                    const url = self.urlBase + '/solicitud/template';

                    utils.getData(url, {}).then((response) => {
                        if (response.success) {
                            self.solicitudSeleccionada(response);
                            self.parseSolicitud(response.data);
                        }
                    })
                });

                self.postSolicitud = (() => {
                    const url = self.urlBase + '/solicitud/add';
                    const data = self.fromSolicitud();


                    utils.confirmar('Solicitud').then((confirmacion) => {

                        if (confirmacion) {
                            utils.postData(url, data).then((response) => {
                                if (response.success) {
                                    const folio = response.data.folio;

                                    self.getSolicitudes();
                                    self.solicitudSeleccionada(response);
                                    self.parseSolicitud(response.data);

                                    swal("Solicitud Registrada", "Folio: " + folio, "success");

                                    return true;
                                }

                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");
                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                    });
                });

                self.putSolicitud = (() => {

                    var data = {
                        id: self.solicitudId(),
                        folio: self.solicitudFolio(),
                        esMediable: self.solicitudMediable(),
                        canalizado: self.solicitudCanalizada(),
                        canalizacion: {
                            id: self.id_canalizacion(),
                            descripcion: self.descripcionNoMediable(),
                            solicitud_id: self.solicitudId(),
                            estatus: self.solicitudCanalizada() ? 1 : 0,
                            institucion: self.institucion_seleccionada() ? { id: self.institucion_seleccionada() } : null
                        },
                        usuarioPersona: self.solicitudUsuario(),
                        invitadoPersona: self.solicitudInvitado(),
                        materia: self.solicitudMateria(),
                        descripcionConflicto: self.solicitudDescripcion(),
                        estatus: self.solicitudEstatus(),
                        tipoApertura: self.solicitudTipoApertura(),
                        fechaSesion: self.solicitudFechaSesion() ? self.dateConverter(self.solicitudFechaSesion()) : null
                    }

                    console.log("data",data) 


                    if (data.canalizado && data.canalizacion.institucion == null) {
                        swal('Institución No seleccionada', 'Es necesario seleccionar una institución a la cual sera canalizada esta solicitud.', 'warning');
                        return false;
                    }

                    if (!data.estatus) {
                        swal('Seguimiento No seleccionado', 'Es necesario seleccionar quien le esta dando el seguimiento a la solicitud.', 'warning');
                        return false;
                    }

                    const url = self.urlBase + '/solicitud/save/' + self.solicitudId();
                    
                    utils.confirmar('Solicitud').then((confirmacion) => {

                        if (confirmacion) {
                            utils.postData(url, data).then((response) => {

                                if (response.success) {
                                    self.solicitudSeleccionada(response);
                                    self.parseSolicitud(response.data);
                                    self.getSolicitudes();

                                    swal("Solicitud actualiza", "Se han actualizado los datos de la solicitud", "success");

                                    return true;
                                }

                                const errores = JSON.stringify(response.errors);
                                swal(response.message, errores, "error");
                            }).catch((response) => {
                                const errores = JSON.stringify(response);

                                swal("Error al procesar la petición", errores, "error");
                            });
                        }
                    });
                });

                self.getReporte = (async (solicitud, reporte) => {
                    const params = {
                        "p_solicitud_id": solicitud.id,
                        "p_acuse": reporte.esAcuse
                    };


                    const url = config.baseEndPoint + '/reportes/mediacion/' + reporte.nombreReporte;

                    this.dataPDF(null);

                    return new Promise((resolve, reject) => {
                        utils.getReporte(url, params).then((response) => {

                            if (response.hasOwnProperty("error")) {
                                reject(response);
                            }

                            const reader = new FileReader();

                            reader.readAsArrayBuffer(response);
                            reader.onload = ((e) => {
                                const buffer = e.target.result;
                                const fileBlob = new Blob([new Uint8Array(buffer)], {
                                    type: "application/pdf"
                                })

                                resolve(window.URL.createObjectURL(fileBlob));
                            });

                        }).catch(errors => {
                            console.log(errors);
                            swal("Error", JSON.stringify(errors), "error")
                        });
                    });

                });

                self.getPersona = ((url) => {

                    if (url) {
                        utils.waiting();

                        return new Promise((resolve, reject) => {
                            utils.getData(url, {})
                                .then((response) => {
                                    utils.waiting(true);

                                    if (response.success) {
                                        resolve(response.data);
                                    } else {
                                        swal('Persona', JSON.stringify(response.message), 'error');
                                        reject(response.errors);
                                    }
                                })
                                .catch((errors) => {
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

                    if (solicitud.valid !== 'valid') {
                        solicitud.focusOn('@firstInvalidShown');
                    }

                    if (usuario.valid !== 'valid') {
                        usuario.focusOn('@firstInvalidShown');
                    }

                    if (invitado.valid !== 'valid') {
                        invitado.focusOn('@firstInvalidShown');
                    }
                    return false;
                }
            }
        }

        return MediacionViewModel;
    }
);