define(['accUtils', 'webConfig', 'utils', 'knockout', 'sesion','sweetalert',
    'oj-c/form-layout', 'oj-c/input-text', 'oj-c/button', 'oj-c/input-password', 'ojs/ojvalidationgroup' ], 
(accUtils, config, utils, ko, Sesion) =>{
    class LoginViewModel{
        constructor (params){
            var self = this;
            var rootViewModel = ko.dataFor(document.getElementById('globalBody'));
            var router = params.router;

            self.userName = ko.observable();
            self.passwd = ko.observable();
            this.groupValid = ko.observable();           

            self.login = ((loginData)=>{
                const url = config.baseEndPoint + '/session/login';

                Sesion.init();

                utils.postData(url, loginData).then((response)=>{
                    let mensaje = response.message;
                    const evento = response.success?'success':'warning';
                    const errores = response.success?'':JSON.stringify(response.errors);

                    if (response.success){
                        Sesion.setData('credenciales', response.data);
                    }

                    if (mensaje==undefined||mensaje==null){
                        if(response.error){
                            mensaje=response.error;
                        }
                    }

                    swal(mensaje, errores, evento);

                    this.validaSesion();
                }).catch((error)=>{
                    const errores = JSON.stringify(error);
                    swal('Inicio de sesion', errores, 'error');
                });
            });

            this.validaSesion = (()=>{
                if (Sesion.estaActiva()){
                    const email = Sesion.getData('email');

                    rootViewModel.userName(email);
                    router.go({path: 'dashboard'});
                }

                document.getElementById('trackerLogin').focusOn('nombreUsuario');
            })

            this.iniciarSesion = ((event)=>{
                const valid = utils.checkValidationGroup('trackerLogin');

                const loginData = {
                    username: self.userName(),
                    password: self.passwd()
                }

                if (valid){
                    self.login(loginData);
                }                
            });

            this.connected  = (()=>{
                accUtils.announce('Login page loaded.', 'assertive');
                document.title = "Inicio de Sesión";

                this.validaSesion();
            });

            this.keyPress = ((event)=>{
                if (event.charCode == 13){
                    this.iniciarSesion();
                }
            });
        }
    }

    return LoginViewModel;
});