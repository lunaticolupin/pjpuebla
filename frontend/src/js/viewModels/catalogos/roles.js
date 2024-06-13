define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals', 'text!models/persona.json',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element'], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, PersonaModel ) {
    class RolesViewModel {
        constructor() {
            var self = this;

            self.roles = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/roles';
            self.rolSeleccionado = ko.observable();

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.roles, {keyAttributes: 'id'});
            this.userInfoSignal = new signals.Signal();
            this.userInfoSignal1 = new signals.Signal();

            self.permisosArray = []

            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Roles";
                self.getRoles(self.baseUrl); 
            };

            this.disconnected = () => {
                self.permisosArray = []
            };

            this.transitionCompleted = () => {
                // Implement if needed
            };

            self.getRoles = (url, params = {}) => {
                url = self.baseUrl+'/activos'
                utils.getData(url, params).then((response)=>{
                    if (response.success){
                        self.roles(response.data);
                    }
                    
                }).catch(error => alert(error));         
            }
            
            //Función para mandar a roldetalle
            this.detalleRol = (event, data) =>{
                if(data.item.data){
                    self.rolSeleccionado(data.item.data);
                    this.openModalAgregar()
                }
            };

            this.setRol = (event,data) => {
                if(data.item.data) {
                    self.rolSeleccionado(data.item.data)
                    this.openModalAsignar()
                }
            }

            //Función para mandar a rolmodulopermiso


            this.eliminar = (event,data) => {
                let url = self.baseUrl+"/delete/"+data.row.id
                utils.postData(url).then((response)=>{
                    if (response.success){
                        swal(response.message);
                    }
                    
                }).catch(error => alert(error));    
            }       
            ko.computed(()=>{
                this.userInfoSignal.dispatch(self.rolSeleccionado());
            });
            ko.computed(()=>{
                this.userInfoSignal1.dispatch(self.rolSeleccionado());
            });
        }
        openModalAgregar(event) {
            document.getElementById("modalAgregar").open();
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }

        openModalAsignar(event) {
            document.getElementById("modalAsignar").open();
        }
    }
    return RolesViewModel;
});