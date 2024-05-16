define(['accUtils', 'webConfig', 'utils', 'knockout', 'sesion','sweetalert',
    'oj-c/form-layout', 'oj-c/input-text', 'oj-c/button', 'oj-c/input-password', ], 
(accUtils, config, utils, ko, Sesion) =>{
    class LoginViewModel{
        constructor (params){
            var self = this;
            var rootViewModel = ko.dataFor(document.getElementById('globalBody'));
            var router = params.router;

            self.userName = ko.observable();
            self.passwd = ko.observable();
            

            self.login = ((loginData)=>{
                const url = config.baseEndPoint + '/session/login';

                Sesion.init();

                utils.postData(url, loginData).then((response)=>{
                    let mensaje = response.message;
                    const evento = response.success?'success':'warning';

                    if (response.success){
                        Sesion.setData('credenciales', response.data);
                    }

                    if (mensaje==undefined||mensaje==null){
                        if(response.error){
                            mensaje=response.error;
                        }
                    }

                    if (response.errors){
                        mensaje += '. ' + response.errors
                    }

                    swal('Inicio de sesión', mensaje, evento);

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
            })

            this.iniciarSesion = ((event)=>{
                const loginData = {
                    username: self.userName(),
                    password: self.passwd()
                }

                self.login(loginData);
            });

            this.connected  = (()=>{
                accUtils.announce('Login page loaded.', 'assertive');
                document.title = "Inicio de Sesión";

                this.validaSesion();
            })
        }
    }

    return LoginViewModel;
});