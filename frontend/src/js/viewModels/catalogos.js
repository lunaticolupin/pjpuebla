define(['../accUtils', 'require', 'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 
'ojs/ojknockout', 'ojs/ojnavigationlist','ojs/ojmodule-element'],
 function(accUtils, require, ko, ArrayDataProvider, ModuleElementUtils) {
    class CatalogosViewModel {
         constructor() {

            var self = this;
            var rootViewModel = ko.dataFor(document.getElementById('globalBody'));

            let data = [
                { name: "Personas", id: "personas", icons: "oj-ux-ico-home" },
                { name: "Usuarios", id: "usuarios", icons: "oj-ux-ico-book" },
            ];

            self.catalogos = ko.observableArray(data);

            this.dataProvider = new ArrayDataProvider(self.catalogos, {
                keyAttributes: "id",
            });

            this.ModuleElementUtils = ModuleElementUtils;
            
            this.selectedItem = ko.observable("personas");

            rootViewModel.validaSesion();

             this.connected = () => {
                 accUtils.announce('Catalogos page loaded.', 'assertive');
                 document.title = "Catálogos";
             };

             this.disconnected = () => {
                 // Implement if needed
             };

             this.transitionCompleted = () => {
                 // Implement if needed
             };
         }
     }

    return CatalogosViewModel;
  }
);
