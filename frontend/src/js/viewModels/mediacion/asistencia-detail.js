define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider', 'ojs/ojasyncvalidator-regexp', 'ojs/ojconverter-datetime', 'sweetalert',
    "ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single",
    "oj-c/form-layout", "oj-c/input-number"],
    function (ko, config, utils, ArrayDataProvider, AsyncRegExpValidator, ojconverter_datetime_1) {
        class asistenciaDetalleViewModel {
            constructor(params) {
                const asistenciaInfoSignal = params.asistenciaInfoSignal;
                
                var self = this;

                this.serviceURL = config.baseEndPoint + '/mediacion/asistencias';

                self.asistencia = ko.observable({fecha_asistecia: ''});
                this.maxFecha = new Date().toISOString();
                this.groupValid = ko.observable();
                self.solicitud_id = ko.observable();
                self.asistencia_array_options = [
                    { value: true, label: "SI" },
                    { value: false, label: "NO" },

                ];

                this.dateTimeConverterInput = ko.observable(new ojconverter_datetime_1.IntlDateTimeConverter({
                    timeZone: 'America/Mexico_City',
                    pattern: 'dd/MM/yyyy HH:mm'
                }));

                this.asistenciaDP = new ArrayDataProvider(self.asistencia_array_options,
                    { keyAttributes: 'value' });

                self.isToday = ko.computed(() => {
    
                    const today = new Date().toISOString().split('T')[0]; // Obtener solo la fecha en formato YYYY-MM-DD
                    const selectedDate = self.asistencia().fecha_asistencia ?
                        new Date(self.asistencia().fecha_asistencia).toISOString().split('T')[0] :
                        ""; // Extraer solo la fecha de la propiedad

                    return today >= selectedDate;
                });

                function formatear_fecha(p_fecha) {

                    // Crear un objeto Date a partir de la cadena
                    let date = new Date(p_fecha);

                    // Obtener la hora local en la zona horaria de Ciudad de México
                    let options = {
                        timeZone: 'America/Mexico_City',
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                        hour12: false
                    };

                    let formatter = new Intl.DateTimeFormat('en-GB', options);
                    let parts = formatter.formatToParts(date);

                    // Formatear la fecha al estilo deseado yyyy-MM-dd HH:mm:ss
                    let formattedDate = `${parts.find(p => p.type === 'year').value}-${parts.find(p => p.type === 'month').value}-${parts.find(p => p.type === 'day').value} ${parts.find(p => p.type === 'hour').value}:${parts.find(p => p.type === 'minute').value}:${parts.find(p => p.type === 'second').value}`;

                    return formattedDate;
                }

                this.guardar = (() => {

                    const valid = this._checkValidationGroup();
                    const url = this.serviceURL + '/save/' + self.asistencia().id;
                    const data = self.asistencia();

                    self.asistencia().fecha_asistencia = formatear_fecha(self.asistencia().fecha_asistencia)
                    self.asistencia().solicitud = { id: self.solicitud_id() };

                    if (!valid) {
                        return false;
                    }



                    utils.confirmar('Invitación').then((confirmacion) => {

                        if (confirmacion) {


                            utils.postData(url, data).then((response) => {

                                if (response.success) {
                                    swal('Invitación', response.message, 'success');

                                } else {
                                    swal(response.message, JSON.stringify(response.errors), 'error');
                                }
                            }).catch((error) => {
                                console.log(error);

                            })
                        }
                    })
                });

                asistenciaInfoSignal.add((p_asistencia, p_solicitud_id) => {

                    if ((Array.isArray(p_asistencia) && p_asistencia.length > 0) ||
                        (p_asistencia && typeof p_asistencia === 'object' && Object.keys(p_asistencia).length > 0)) {
                        p_asistencia.fecha_asistencia = new Date(p_asistencia.fecha_asistencia).toISOString();
                        this.asistencia(p_asistencia);
                    }

                    self.solicitud_id(p_solicitud_id);

                }, this);


            }

            _checkValidationGroup() {
                const asistencia = document.getElementById('trackerAsistencia');

                if (asistencia.valid === 'valid') {
                    return true;
                }
                else {
                    asistencia.showMessages();

                    if (asistencia.valid !== 'valid') {
                        asistencia.focusOn('@firstInvalidShown');
                    }


                    return false;
                }
            }
        }
        return asistenciaDetalleViewModel;
    }
);
