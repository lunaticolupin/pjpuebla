define(['../../accUtils', 'require',  'knockout', 'ojs/ojarraydataprovider',  "ojs/ojdatagridprovider",
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", "oj-c/form-layout"], 
function (accUtils, require, ko, ArrayDataProvider, DataGridProvider) {
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