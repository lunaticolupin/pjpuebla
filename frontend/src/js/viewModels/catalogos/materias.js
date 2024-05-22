define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',"ojs/ojvalidation-base",
"ojs/ojknockout", "oj-c/input-date-text", "oj-c/button", 'ojs/ojtable', 'ojs/ojmodule-element','ojs/ojdialog','ojs/ojbootstrap',"oj-c/input-text"], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals, Bootstrap) {
    class MateriaViewModel {
        constructor(params) {
            // const userInfoSignal = params.userInfoSignal;
            var self = this;    

            self.materias = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/materias';
            self.materiaSeleccionada = ko.observable();

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.materias, {keyAttributes: 'id'});
            // this.userInfoSignal = new signals.Signal();
            this.serviceURL = config.baseEndPoint + '/materias;'

            self.id = ko.observable();
            self.clave = ko.observable();
            self.descripcion = ko.observable();

            self.disableEliminar = ko.computed(() =>{
                if (self.id()){
                    return false;
                }

                return true;
            });


            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Materias";

                self.getMaterias(self.baseUrl); 
            };
            self.getMaterias = (url, params = {}) => {
                utils.getData(url, params).then((response)=>{

                    if (response.success){
                        console.log(response);
                        self.materias(response.data);
                    }
                    
                }).catch(error => console.log(error));         
            }

            this.detalleMateria = (event, data) =>{
                if(data.item.data){
                    self.materiaSeleccionada(data.item.data);
                }
            };

            // ko.computed(()=>{
            //     this.userInfoSignal.dispatch(self.materiaSeleccionada());
            // });

            this.guardar = (()=>{
                let url = this.serviceURL+"/save";

                let data = self.parseMateriaSave();

                utils.postData(url, data).then((response)=>{
                    console.log(response);
                    if (response.success){
                        alert(response.message);
                        // window.location.reload()
                    }else{
                        alert(JSON.stringify(response.errors));
                    }

                }).catch(error => console.log(error));
            });
            this.eliminar = (()=>{
                let id = self.id();
                if (id==undefined || id==null){
                    return false;
                }

                let url = this.serviceURL+"/delete/"+id;
            

                utils.postData(url,{}).then((response)=>{
                    console.log(response);
                    
                    alert(response.message);
                    this.dataprovider.resetAllUnsubmittedItems();
                    window.location.reload();
                }).catch(error => console.log(error));
            });
            this.parseMateria = ((data)=>{

                if (data){
                    self.id(data.id);
                    self.clave(data.clave);
                    self.descripcion(data.descripcion);
                }
            });

            this.parseMateriaSave = (()=>{
                return {
                    id: self.id(),
                    clave: self.clave(),
                    descripcion: self.descripcion()
                }
            });

            // userInfoSignal.add((materia) => {
            //     this.parseMateria(materia);
            // }, this);
            
        }
        open(event) {
            document.getElementById("modalDialog1").open();
        }
        close(event) {
            document.getElementById("modalDialog1").close();
        }
    }
    // Bootstrap.whenDocumentReady().then(() => {
    //     ko.applyBindings(new MateriaViewModel(), document.getElementById("dialogWrapper"));
    // });

    return MateriaViewModel;
});