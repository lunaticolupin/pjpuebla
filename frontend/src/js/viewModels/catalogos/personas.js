define(['../../accUtils', 'jquery', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals', 'text!models/persona.json',
"ojs/ojknockout", "oj-c/button", "oj-c/checkbox",  'ojs/ojtable', 'ojs/ojmodule-element'], 
function (accUtils, $, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, PersonaModel ) {
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
                this.muestraDetalle(false);
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
                utils.waiting();

                utils.getData(url, params).then((response)=>{

                    if (response.success){
                        self.personas(response.data);
                    }

                    utils.waiting(stop=true);
                    
                }).catch(error => {
                    utils.waiting(stop=true);
                    console.log(error)
                });         
            }

            this.detallePersona = (event, data) =>{
                if(data.item.data){

                    document.getElementById("clave").val(data.item.data.clave)
                    getEleme
                    self.personaSeleccionada(data.item.data);
                    //this.muestraDetalle();
                }
            };

            this.agregarPersona = () =>{
                let newPersona = JSON.parse(PersonaModel);
                self.personaSeleccionada(newPersona);
            };

            this.muestraDetalle = (verDetalle=true) =>{

                if (verDetalle){
                    $("#personas").hide();
                    $("#form-persona").show();
                    return verDetalle;
                }

                $("#personas").show();
                $("#form-persona").hide();
                self.personaSeleccionada(null);
            };

            this.moduleDetallePersona = ModuleElementUtils.createConfig(
                {name: 'catalogos/persona-detalle', 
                params: {
                    userInfoSignal: this.userInfoSignal, 
                    getPersonas: this.getPersonas,
                    muestraDetalle: this.muestraDetalle
                }
            });

            self.personaSeleccionada.subscribe((data)=>{
                if(data){
                    this.muestraDetalle();
                }
            })

            ko.computed(()=>{
                this.userInfoSignal.dispatch(self.personaSeleccionada(),"catalogoPersona");
            });

            
         }
    }

    return PersonalViewModel;
});