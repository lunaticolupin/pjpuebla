define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',
'ojs/ojknockout',"oj-c/button",'ojs/ojtable', 'ojs/ojmodule-element','ojs/ojdialog','oj-c/input-text','sweetalert'], 
function (accUtils, config, utils, ko, ArrayDataProvider, ModuleElementUtils, signals) {
    class MateriaViewModel {
        constructor(params) {
            var self = this;    

            self.materias = ko.observableArray();
            self.baseUrl = config.baseEndPoint + '/materias';
            self.materiaSeleccionada = ko.observable();

            this.ModuleElementUtils = ModuleElementUtils;
            this.dataProvider = new ArrayDataProvider(self.materias, {keyAttributes: 'id'});
            this.userInfoSignal = new signals.Signal();
            this.serviceURL = config.baseEndPoint + '/materias;'
            
            // self.id = ko.observable();
            // self.clave = ko.observable();
            // self.descripcion = ko.observable();

            this.connected = () => {
                accUtils.announce('Catalogos page loaded.', 'assertive');
                document.title = "Catálogos / Materias";

                self.getMaterias(self.baseUrl); 
            };

            self.getMaterias = (url, params = {}) => {
                utils.getData(url, params).then((response)=>{
                    if (response.success){
                        console.log(response);
                        // document.getElementById("clave").val(data.item.data.clave);
                        self.materias(response.data);
                    }
                }).catch(error => console.log(error));         
            }

            this.detalleMateria = (event, data) =>{
                if(data.item.data){
                    self.materiaSeleccionada(data.item.data);
                }
            };

            // this.parseMateriaSave = (()=>{
            //     return {
            //         id: self.id(),
            //         clave: self.clave(),
            //         descripcion: self.descripcion()
            //     }
            // });

            // this.parseMateria = ((data)=>{
            //     if (data){
            //         self.id(data.id);
            //         self.clave(data.clave);
            //         self.descripcion(data.descripcion);
            //     }
            // });

            // this.guardar = (()=>{
            //     let url = this.serviceURL+"/save";

            //     console.log("url",url)
            //     let data = self.parseMateriaSave();

            //     utils.postData(url, data).then((response)=>{
            //         if (response.success){
            //             // alert(response.message);
            //             swal("Materia registrada","success");

            //         }else{
            //             const errores = JSON.stringify(response.errors);
            //             swal(response.message, errores, "error")
            //         }
            //     }).catch((response)=>{
            //         const errores = JSON.stringify(response);

            //         swal("Error al procesar el registro", errores, "error");
            //     });
            // });
        }

        openModalAgregar(event) {
            document.getElementById("modalAgregar").open();
        }
        openModalEditar(event) {
            document.getElementById("modalEditar").open();
        }
        closeModalAgregar(event) {
            document.getElementById("modalAgregar").close();
        }
        closeModalEditar(event){
            document.getElementById("modalEditar").close();
        }
    }
    // Bootstrap.whenDocumentReady().then(() => {
    //     ko.applyBindings(new MateriaViewModel(), document.getElementById("dialogWrapper"));
    // });

    return MateriaViewModel;
});