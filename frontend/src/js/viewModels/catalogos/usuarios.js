define(['../../accUtils', 'knockout', 'ojs/ojarraydataprovider'], 
function (accUtils, ko, ArrayDataProvider) {
    class UsuarioViewModel {
         constructor() {
            var self = this;

            self.dataSource = ko.observableArray();

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