define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element','sweetalert'], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals,  ) {
    class ModulosViewModel {
        constructor() {
            var self = this;

            self.modulos = ko.observableArray();
            // self.modulosPadres = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/modulos';
            self.moduloSeleccionado = ko.observable();
            self.moduloPadreArray = []

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.modulos, {keyAttributes: 'id'});
            this.userInfoSignal = new signals.Signal();

            this.connected = () => {
                accUtils.announce('Catálogos page loaded.', 'assertive');
                document.title = 'Catálogos / módulos'
                self.getModulos(self.baseUrl);
            };



            //Funcion para obtener el total de modulos y seleccionar el modulo padre
            self.getModulos = (url,params = {}) => {
                utils.getData(url,params).then((response)=>{
                    if(response.data) {
                        self.modulos(response.data)
                        let modulosPadres
                        modulosPadres = response.data
                        let moduloAux = {
                            id: '',
                            label: '',
                        }
                        modulosPadres.forEach(element => {
                            moduloAux.id = element.id
                            moduloAux.label = element.descripcion

                            self.moduloPadreArray.push(moduloAux)
                        });                                      
                    }
                }).catch(error => swal(error))
            }
            this.detalleModulo = (event, data) => {
                if(data.item.data) {
                    self.moduloSeleccionado(data.item.data)
                    this.openModalAgregar()
                }
            }

            this.eliminar = (event, data) => {
                let url = self.baseUrl+"/delete/"+data.row.id

                utils.postData(url).then((response) => {
                    if(response.success) {
                        swal(response.message)
                        // this.getModulos(baseUrl)
                    }
                }).catch(error => swal(error))
            }

            ko.computed(()=>{
                this.userInfoSignal.dispatch(self.moduloSeleccionado());
            });
        }
        openModalAgregar(event) {
            document.getElementById("modalAgregar").open();
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
    }
    return ModulosViewModel;
});
