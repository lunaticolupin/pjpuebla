define(['../../accUtils', 'webConfig', 'utils',  'knockout', 'ojs/ojarraydataprovider', 'ojs/ojmodule-element-utils', 'signals',"ojs/ojvalidation-base",
"ojs/ojknockout", "oj-c/input-date-text", "oj-c/button", 'ojs/ojtable', 'ojs/ojmodule-element','ojs/ojdialog',"oj-c/input-text"], 
    function() {
        class MateriaDetalleViewModel {
            constructor(params) {
                const userInfoSignal = params.userInfoSignal;

                var self = this;

                this.serviceURL = config.baseEndPoint + '/materias';

                self.id = ko.observable();
                self.clave = ko.observable();
                self.descripcion = ko.observable();
                
                self.disableEliminar = ko.computed(() =>{
                    if (self.id()){
                        return false;
                    }

                    return true;
                });

                this.guardar = (()=>{
                    let url = this.serviceURL+"/save";

                    let data = self.parseMateriaSave();

                    utils.postData(url, data).then((response)=>{
                        console.log(response);
                        if (response.success){
                            alert(response.message);
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

                userInfoSignal.add((materia) => {
                    this.parseMateria(materia);
                }, this);
        }
    }
    return MateriaDetalleViewModel;
});
