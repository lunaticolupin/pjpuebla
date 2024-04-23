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
            self.personaMoral = ko.observable(true);
            self.hablanteLenguaDistinta = ko.observable(false);

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

            self.aplicaDato = ko.computed(() =>{
                return false;
            });

            this.dataProviderEC = new ArrayDataProvider(self.estadoCivilArray,
            {keyAttributes:'value'});

            this.guardar = (()=>{
                console.log(self.parsePersonaSave());
                let url = this.serviceURL+"/save";

                let data = self.parsePersonaSave();

                utils.postData(url, data).then((result)=>{
                    console.log(result);
                    alert(result);
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
                    //self.personaMoral(data.personaMoral);
                    self.hablanteLenguaDistinta(data.hablanteLenguaDistinta);
                }

            });

            this.parsePersonaSave = (()=>{
                console.log(self.personaMoral());
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
                    hablanteLenguaDistinta: self.personaMoral()
                }
            });


            this.dataProviderSexo = new ArrayDataProvider(self.sexoArray,
                {keyAttributes:'value'});

            userInfoSignal.add((persona) => {
                this.parsePersona(persona);
            }, this);
           
         }
     }

    return PersonaDetalleViewModel;
  }
);
