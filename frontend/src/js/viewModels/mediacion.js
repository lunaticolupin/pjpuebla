define(['../accUtils', 'jquery', 'webConfig', 'utils', 'knockout', 'ojs/ojarraydataprovider', 'ojs/ojkeyset', 'ojs/ojconverter-datetime',
    'ojs/ojmodule-element-utils', 'ojs/ojasyncvalidator-regexp', 'ojs/ojvalidator-required', 'signals', 'ojs/ojlistdataproviderview', 'ojs/ojdataprovider', 'text!models/mediacion.json',
    'ojs/ojknockout', 'oj-c/button', 'ojs/ojtable', 'oj-c/form-layout', 'oj-c/input-text', 'ojs/ojdatetimepicker', 'oj-c/select-single', 'ojs/ojvalidationgroup', 'sweetalert',
    'oj-c/text-area', 'ojs/ojtoolbar', 'oj-c/radioset', 'ojs/ojradioset', 'ojs/ojtoolbar', "oj-c/list-item-layout", "oj-c/list-view", "ojs/ojswitch", "ojs/ojoption", "ojs/ojmodule-element"
],
    function (accUtils, $, config, utils, ko, ArrayDataProvider, ojkeyset_1, ojconverter_datetime_1, ModuleElementUtils, AsyncRegExpValidator, RequiredValidator,
        signals, ListDataProviderView, ojdataprovider_1, catalogos_json) {
        class MediacionViewModel {
            constructor() {
                var self = this;
                var rootViewModel = ko.dataFor(document.getElementById('globalBody'));

                self.catalogos = JSON.parse(catalogos_json);

                rootViewModel.validaSesion();

                self.urlBase = config.baseEndPoint + '/mediacion';
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

                /* Funciones flecha para mostrar o ocultar formularios  */
                self.mostrarForm = ko.computed(() => self.solicitudSeleccionada() || self.solicitudDetalle());
                self.mostrarDocMed = ko.computed(() => !self.solicitudMediable());
                self.mostrarDocNoMed = ko.computed(() => self.solicitudMediable() == 0 || self.solicitudMediable());

                /** Catalogos */
                self.materias = ko.observableArray();
                self.instituciones = ko.observableArray();
                self.mediadores = ko.observableArray();
                self.tipoAperturas = self.catalogos.aperturas
                self.estadoSolicitud = ko.observableArray(self.catalogos.estadosSolicitudes);
                self.esMediableArray = self.catalogos.esMediable;
                self.protocoloViolencia = self.catalogos.protocolosViolencia;
                self.documentos = ko.observableArray([
                    { value: 1, label: "Solicitud", disabled: ko.observable(false), filename: ko.observable(), printEnabled: ko.observable(true) },
                    { value: 2, label: "1ra Invitación", disabled: self.mostrarDocMed, filename: ko.observable(), printEnabled: ko.observable() },
                    { value: 3, label: "Acuse 1ra Invitación", disabled: self.mostrarDocMed, filename: ko.observable(), printEnabled: ko.observable() },
                    { value: 4, label: "Constancia de Asunto no Mediable", disabled: self.mostrarDocNoMed, filename: ko.observable(), printEnabled: ko.observable() },
                    { value: 5, label: "Acuse Constancia de Asunto no Mediable", disabled: self.mostrarDocNoMed, filename: ko.observable(), printEnabled: ko.observable() },
                    { value: 6, label: "Canalización", disabled: self.mostrarDocNoMed, filename: ko.observable(), printEnabled: ko.observable() }
                ]);


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


                this.documentosDP = ko.computed(() => {
                    let documentosEnabled = self.documentos().filter((item) => item.disabled() == false);

                    return new ArrayDataProvider(documentosEnabled, { keyAttributes: 'value' });
                });

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

                    self.solicitudProtocoloViolencia(null);
                    self.estadoSolicitud.removeAll();

                    switch (value) {
                        case 0:

                            self.estadoSolicitud([
                                { value: 0, label: 'En Recepción' },
                                { value: 1, label: 'En Dirección' }
                            ]);
                            self.estatusSolicitudDisabled(false);

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
                            break;

                        case 2:
                            self.estadoSolicitud([
                                { value: 3, label: "No Mediable" }
                            ]);
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
                        self.getMediadores()
                    ]).finally(() => {
                        utils.waiting(true);
                    });
                };

                self.parseSolicitud = ((solicitud) => {
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
                    self.solicitudTipoAperturaId(solicitud.tipoApertura.id);

                    //definiendo variables de canalización:
                    if (solicitud.canalizacion) {
                        self.id_canalizacion(solicitud.canalizacion.id);
                        self.descripcionNoMediable(solicitud.canalizacion.descripcion);
                        self.institucion_seleccionada(solicitud.canalizacion.institucion ? solicitud.canalizacion.institucion.id : '');
                    }

                    if (solicitud.fechaSesion) {
                        self.solicitudFechaSesion(new Date(solicitud.fechaSesion).toISOString());
                    } else { self.solicitudFechaSesion("") }

                    if (self.solicitudFechaSesion()) {
                        let doc = this.documentos().find((element) => element.value == 2);

                        doc.printEnabled(true);
                    }

                    self.getAsistencias();

                });

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
                            utils.crear_cita('Invitación').then((confirmacion) => {
                                template = response.data;
                                template.solicitud = { id: self.solicitudId() };
                                utils.postData(url_add, template).then((response) => {
                                    if (response.success) {
                                        swal("Invitación generada", "Se han generado una nueva invitación", "success");
                                        self.getAsistencias();
                                        return true;
                                    }
                                    const errores = JSON.stringify(response.errors);
                                    swal(response.message, errores, "error");
                                }).catch((response) => {
                                    const errores = JSON.stringify(response);
    
                                    swal("Error al procesar la petición", errores, "error");
                                });

                            })

                        }
                    })
                }

                self.isToday = ko.computed(() => {
    
                    const today = new Date().toISOString().split('T')[0]; // Obtener solo la fecha en formato YYYY-MM-DD
                    const selectedDate = self.solicitudFechaSesion() ?
                        new Date(self.solicitudFechaSesion()).toISOString().split('T')[0] :
                        "";
                    console.log(today);
                    console.log(selectedDate);
                    console.log( today <= selectedDate);
                    
                    
                    
                    return today <= selectedDate;
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

                    self.solicitudDetalle(true);
                    self.solicitudSeleccionada({ key: detail.item.key, data: detail.item.data });
                    self.parseSolicitud(detail.item.data);

                    const element = document.getElementById('solicitudes');
                    const seleccion = {
                        row: new ojkeyset_1.KeySetImpl([detail.key]),
                        column: new ojkeyset_1.KeySetImpl([detail.columnIndex])
                    };

                    element.selected = seleccion;
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

                    if (element == "btnImprimir") {
                        solicitud = self.solicitudSeleccionada().data;
                    } else {
                        solicitud = detail.item.data;
                    }

                    self.getReporte(solicitud).then(response => {
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
                    const url = self.urlBase + '/solicitud';
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

                self.getReporte = ((data) => {
                    const params = {
                        "p_solicitud_id": data.id
                    };

                    const url = config.baseEndPoint + '/reportes/mediacion/Solicitud';

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


                            //resolve(true);

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

                console.log(solicitud.valid === 'valid' && usuario.valid === 'valid' && invitado.valid === 'valid');

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