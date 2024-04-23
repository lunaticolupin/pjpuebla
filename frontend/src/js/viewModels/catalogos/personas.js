define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element'], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals ) {
    class PersonalViewModel {
         constructor() {
            var self = this;

            self.personas = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/personas';
            self.personaSeleccionada = ko.observable();

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.personas, {keyAttributes: 'id'});
            this.userInfoSignal = new signals.Signal();

            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Personas";

                self.getPersonas(self.baseUrl); 
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

            self.getPersonas = (url, params = {}) => {
                utils.getData(url, params).then((data)=>{
                    self.personas(data);
                })         
            }

            this.detallePersona = (event, data) =>{
                console.log(data);
                if(data.item.data){
                    self.personaSeleccionada(data.item.data);
                }
            };

            ko.computed(()=>{
                this.userInfoSignal.dispatch(self.personaSeleccionada());
            })

         }
    }

    return PersonalViewModel;
});