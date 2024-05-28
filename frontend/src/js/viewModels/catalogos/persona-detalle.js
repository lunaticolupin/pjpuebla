define(['knockout', 'webConfig', 'utils', 'ojs/ojarraydataprovider',
"ojs/ojvalidation-base", "oj-c/input-date-text", "ojs/ojknockout", "oj-c/button", "oj-c/input-text", "oj-c/radioset", "oj-c/checkbox", "oj-c/checkboxset", "oj-c/select-single", 
"oj-c/form-layout"],
 function(ko, config, utils, ArrayDataProvider) {
    class PersonaDetalleViewModel {
         constructor(params) {
            const userInfoSignal = params.userInfoSignal;

            var self = this;

            this.serviceURL = config.baseEndPoint + '/personas';

            self.id = ko.observable();
            self.nombre = ko.observable();
            self.apellidoPaterno = ko.observable();
            self.apellidoMaterno = ko.observable();
            self.curp = ko.observable();
            self.rfc = ko.observable();
            self.email = ko.observable();
            self.telefono = ko.observable();
            self.celular = ko.observable();
            self.calle = ko.observable();
            self.colonia = ko.observable();
            self.cp = ko.observable();
            self.sexo = ko.observable();
            self.estadoCivil = ko.observable();
            self.personaMoral = ko.observable(false);
            self.hablanteLenguaDistinta = ko.observable(false);
            self.usuarioCreo = ko.observable("INFOR");

            self.estadoCivilArray = [
                {value:"S", label:"Soltero"},
                {value:"C", label:"Casado"},
                {value:"D", label:"Divorciado"},
                {value:"U", label:"Unión Libre"},
                {value:"", label:"No aplica"}
            ];

            self.sexoArray = [
                {value:"H", label:"Hombre"},
                {value:"M", label:"Mujer"},
                {value:"", label:"No aplica"}
            ];

            self.disableEliminar = ko.computed(() =>{
                if (self.id()){
                    return false;
                }

                return true;
            });

            this.moduloOrigen = ko.observable(null);

            this.dataProviderEC = new ArrayDataProvider(self.estadoCivilArray,
            {keyAttributes:'value'});

            this.guardar = (()=>{
                let url = this.serviceURL+"/save";

                let data = self.parsePersonaSave();

                utils.confirmar('Persona').then((confirmacion)=>{
                    if(confirmacion){
                        utils.postData(url, data).then((response)=>{
                            if (response.success){
                                swal('Persona',response.message, 'success');

                                if (this.moduloOrigen()=='catalogoPersona'){
                                    this.getPersonas(this.serviceURL);
                                }
                                
                            }else{
                                swal(response.message, JSON.stringify(response.errors), 'error');
                            }
                        }).catch(errors => {
                            swal(response.message, JSON.stringify(errors), 'warning');
                        });
                    }
                });
            });

            this.eliminar = (()=>{
                let id = self.id();
                if (id==undefined || id==null){
                    return false;
                }

                let url = this.serviceURL+"/delete/"+id;
            
                utils.confirmar('Persona','¿Desea eliminar el registro?').then((confirmacion)=>{
                    if(confirmacion){
                        utils.postData(url,{}).then((response)=>{
                            if(response.success){
                                swal('Persona','El registro fue eliminado','success');
                                if (this.moduloOrigen()=='catalogoPersona'){
                                    this.getPersonas(this.serviceURL);
                                }
                            }else{
                                swal(response.message, JSON.stringify(response.errors), 'error');
                            }
                        }).catch(errors => {
                            console.log(errors);
                            swal('Persona', JSON.stringify(errors), 'warning');
                        });
                    }
                })
                
            });

            this.parsePersona = ((data)=>{

                if (data){
                    self.id(data.id);
                    self.nombre(data.nombre);
                    self.apellidoMaterno(data.apellidoMaterno);
                    self.apellidoPaterno(data.apellidoPaterno);
                    self.curp(data.curp);
                    self.rfc(data.rfc);
                    self.sexo(data.sexo);
                    self.email(data.email);
                    self.cp(data.cp);
                    self.estadoCivil(data.estadoCivil);
                    self.personaMoral(data.personaMoral);
                    self.hablanteLenguaDistinta(data.hablanteLenguaDistinta);
                    self.usuarioCreo(data.usuarioCreo);
                    self.telefono(data.telefono);
                    self.calle(data.calle);
                }

            });

            this.parsePersonaSave = (()=>{
                return {
                    id: self.id(),
                    nombre: self.nombre(),
                    apellidoPaterno: self.apellidoPaterno(),
                    apellidoMaterno: self.apellidoMaterno(),
                    curp: self.curp(),
                    rfc: self.rfc(),
                    sexo: self.sexo(),
                    email: self.email(),
                    telefono: self.telefono(),
                    calle: self.calle(),
                    cp: self.cp(),
                    estadoCivil: self.estadoCivil(),
                    personaMoral: self.personaMoral(),
                    hablanteLenguaDistinta: self.personaMoral(),
                    usuarioCreo: self.usuarioCreo(),
                }
            });


            this.dataProviderSexo = new ArrayDataProvider(self.sexoArray,
                {keyAttributes:'value'});

            userInfoSignal.add((persona, moduloOrigen) => {
                this.parsePersona(persona);

                if (moduloOrigen){
                    this.moduloOrigen(moduloOrigen);
                }
            }, this);

            this.getPersonas = params.getPersonas;
           
         }
     }

    return PersonaDetalleViewModel;
  }
);
