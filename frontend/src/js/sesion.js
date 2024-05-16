define(['knockout', 'ojs/ojcorerouter'],(ko)=>{
    var pjStorage = JSON.parse(window.localStorage.getItem('pjpuebla'));

    getItem = ((item)=>{

        if (pjStorage){
            for (const [key, value] of Object.entries(pjStorage)){
                if (key == item){
                    return value;
                }
            }
        }

        return null;
    });

    setItem = ((item, data)=>{

        if (pjStorage!=undefined && pjStorage!=null){

            if (item==='credenciales'){
                for (const [key, value] of Object.entries(data)){
                    pjStorage[key]=value;
                }
            }else{
                pjStorage[item]=data;
            }

            window.localStorage.setItem('pjpuebla', JSON.stringify(pjStorage));
        }

        
    });

    init = (()=>{
        window.localStorage.removeItem('pjpuebla');

        window.localStorage.setItem('pjpuebla', '{}');

    });

    parseJwt = ((token) => {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));

        return JSON.parse(jsonPayload);
    });

    estaActiva = (()=>{
        if (pjStorage!=undefined && pjStorage!=null){
            try{
                const token = getItem("token");
                const payload = parseJwt(token);
                const currentTime = Math.floor(Date.now()/1000);

                return currentTime < payload.exp;
            }catch(error){
                return false;
            }
            
        }

        return false;
    });

    validaSesion = (()=>{
        const email = getItem('email');
        var rootViewModel = ko.dataFor(document.getElementById('globalBody'));
        
        rootViewModel.userLogin(estaActiva());        

        rootViewModel.userName(email);
        
    });

    headerApi = (()=>{
        let token = getItem("token");

        if (token){
            return {
                'Authorization: Bearer ': token
            };
        }

        return null;
    })
    
    return {
        getData: getItem,
        setData: setItem,
        init: init,
        estaActiva: estaActiva,
        valida: validaSesion,
        headerApi: headerApi
    }
});