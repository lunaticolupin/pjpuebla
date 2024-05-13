define(['../accUtils','webConfig','utils','knockout','ojs/ojarraydataprovider', 'ojs/ojbufferingdataprovider', 'ojs/ojkeyset', 'ojs/ojconverter-datetime',
    'ojs/ojknockout', 'oj-c/button', 'ojs/ojtable', 'oj-c/form-layout', 'oj-c/input-text', 'ojs/ojdatetimepicker','oj-c/select-single', 'oj-c/checkbox', 'sweetalert',
    'oj-c/text-area'
],
 function(accUtils, config, utils, ko, ArrayDataProvider, BufferingDataProvider, ojkeyset_1, ojconverter_datetime_1) {
    class MediacionViewModel {
         constructor() {
            var self = this;

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
            self.solicitudNueva = ko.observable(false);
            self.usuarioPM = ko.observable(false);
            self.invitadoPM = ko.observable(false);

            /** Catalogos */
            self.materias = ko.observableArray();
            self.tipoAperturas = ko.observableArray(
                [
                    {id: 1, clave: 'P', descripcion: 'Presencial', activo: true},
                    {id: 2, clave: 'L', descripcion: 'En Línea', activo: true}
                ]
            );

            /** Data Providers */
            self.dataProvider = new BufferingDataProvider(new ArrayDataProvider(self.solicitudes, {keyAttributes: 'id'}));
            this.materiasDP = new ArrayDataProvider(self.materias, {keyAttributes:'id'});
            this.tipoAperturaDP = new ArrayDataProvider(self.tipoAperturas, {keyAttributes: 'id'});
            

            self.mostrarForm = ko.computed(()=>{
                if (self.solicitudSeleccionada() || self.solicitudNueva())
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
                        case 'usuarioPM': self.usuarioPM(itemContext.value); break;
                        case 'invitadoPM': self.invitadoPM(itemContext.value); break;
                    }
                }
            }

            this.connected = () => {
                accUtils.announce('Mediacion page loaded.', 'assertive');
                document.title = "Mediación";

                self.getMaterias();
                self.getSolicitudes();
                // Implement further logic if needed
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

            self.detalleSolicitud = ((event, context)=>{
                this.editRow({ rowKey: context.key });
            });

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

            self.nuevaSolicitud = ((event)=>{
                self.solicitudNueva(true);
                self.getJSONTemp();
            });

            self.guardarSolicitud = ((event)=>{
                self.postSolicitud();
            })

            /** REST */
            self.getSolicitudes = (()=>{
                const url = self.urlBase + '/solicitud';
                self.solicitudes([]);

                utils.getData(url, {}).then((response) => {
                    if (response.success){
                        self.solicitudes(response.data);
                    }
                });
            });

            self.getMaterias = (()=>{
                const url = config.baseEndPoint + '/materias';
                
                utils.getData(url, {}).then((response)=>{
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

                utils.postData(url, data).then((response)=>{                    
                    if (response.success){
                        const folio = response.data.folio;

                        self.getSolicitudes();
                        swal("Solicitud Registrada","Folio: " + folio, "success");
                        
                        return true;
                    }

                    const errores = JSON.stringify(response.errors);
                    swal(response.message, errores, "error");
                }).catch((response)=>{
                    const errores = JSON.stringify(response);
                    
                    swal("Error al procesar la petición", errores, "error");
                });
            });
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