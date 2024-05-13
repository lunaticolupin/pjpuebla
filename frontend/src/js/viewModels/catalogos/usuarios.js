define(['accUtils', 'webConfig', 'utils', 'knockout', 'ojs/ojarraydataprovider',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable'], 
function (accUtils, config, utils, ko, ArrayDataProvider) {
    class UsuarioViewModel {
         constructor() {
            var self = this;

            self.usuarios = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/usuarios';
            self.usuarioSeleccionado = ko.observable();

            self.estatusUsuario = [
                {value:0, label:"INACTIVO"},
                {value:1, label:"ACTIVO"},
                {value:2, label:"BLOQUEADO"}
            ];

            this.dataProvider = new ArrayDataProvider(self.usuarios, {keyAttributes: 'id'});
            
            self.detalleUsuario = ((event, data)=>{
                console.log(data.item);
            });


            self.getUsuarios = ((url, params = {}) => {
                utils.getData(url, params).then((response)=>{

                    if (response.success){
                        self.usuarios(response.data);
                    }
                    
                }).catch(error => console.log(error));         
            });

            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Usuarios";
                //self.getUsuarios();
                // Implement further logic if needed
                self.getUsuarios(self.baseUrl); 
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

           

         }
    }

    return UsuarioViewModel;
});