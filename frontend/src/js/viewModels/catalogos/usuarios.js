define(['../../accUtils', 'webConfig', 'utils', 'knockout', 'ojs/ojarraydataprovider'], 
function (accUtils, config, utils, ko, ArrayDataProvider) {
    class UsuarioViewModel {
         constructor() {
            var self = this;

            self.dataSource = ko.observableArray();
            self.baseUrl = config.baseEndpoint;

            self.getUsuarios = (()=>{
                const url = self.baseUrl+'/usuarios';
                utils.getData(url,{}).then((response)=>{
                    console.log(response);
                });
            });

            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Usuarios";
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


         }
    }

    return UsuarioViewModel;
});