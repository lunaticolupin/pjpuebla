define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element','sweetalert'], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals,  ) {
    class PermisosViewModel {
        constructor() {
            var self = this;

            self.permisos = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/permisos';
            self.permisoSeleccionado = ko.observable();
            self.permisoPadreArray = []

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.permisos, {keyAttributes: 'id'});
            this.userInfoSignal = new signals.Signal();

            this.connected = () => {
                accUtils.announce('Catálogos page loaded.', 'assertive');
                document.title = 'Catálogos / módulos'
                self.getpermisos(self.baseUrl);  
            };


            self.getpermisos = (url,params = {}) => {
                utils.getData(url,params).then((response)=>{
                    if(response.data) {
                        self.permisos(response.data)                    
                    }
                }).catch(error => swal(error))
            }
            this.detallePermiso = (event, data) => {
                if(data.item.data) {
                    self.permisoSeleccionado(data.item.data)
                    this.openModalAgregar()
                }
            }

            this.eliminar = (event, data) => {
                let url = self.baseUrl+"/delete/"+data.row.id

                utils.postData(url).then((response) => {
                    if(response.success) {
                        swal(response.message)
                        // this.getpermisos(baseUrl)
                    }
                }).catch(error => swal(error))
            }

            ko.computed(()=>{
                this.userInfoSignal.dispatch(self.permisoSeleccionado());
            });
        }
        openModalAgregar(event) {
            document.getElementById("modalAgregar").open();
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
    }
    return PermisosViewModel;
});
