define(['../accUtils', 'require', 'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 
'ojs/ojknockout', 'ojs/ojnavigationlist','ojs/ojmodule-element'],
 function(accUtils, require, ko, ArrayDataProvider, ModuleElementUtils) {
    class DashboardViewModel {
         constructor() {

            var self = this;

            let data = [
                { name: "Personas", id: "personas", icons: "oj-ux-ico-home" },
                { name: "Usuarios", id: "usuarios", icons: "oj-ux-ico-book" },
            ];

            self.catalogos = ko.observableArray(data);
             // Below are a set of the ViewModel methods invoked by the oj-module component.
             // Please reference the oj-module jsDoc for additional information.
             /**
              * Optional ViewModel method invoked after the View is inserted into the
              * document DOM.  The application can put logic that requires the DOM being
              * attached here.
              * This method might be called multiple times - after the View is created
              * and inserted into the DOM and after the View is reconnected
              * after being disconnected.
              */

            this.dataProvider = new ArrayDataProvider(self.catalogos, {
                keyAttributes: "id",
            });

            this.ModuleElementUtils = ModuleElementUtils;
            
            this.selectedItem = ko.observable("personas");

             this.connected = () => {
                 accUtils.announce('Catalogos page loaded.', 'assertive');
                 document.title = "Catálogos";
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

    /*
     * Returns an instance of the ViewModel providing one instance of the ViewModel. If needed,
     * return a constructor for the ViewModel so that the ViewModel is constructed
     * each time the view is displayed.
     */
    return DashboardViewModel;
  }
);
