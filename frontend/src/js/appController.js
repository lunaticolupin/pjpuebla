/**
 * @license
 * Copyright (c) 2014, 2024, Oracle and/or its affiliates.
 * Licensed under The Universal Permissive License (UPL), Version 1.0
 * as shown at https://oss.oracle.com/licenses/upl/
 * @ignore
 */
/*
 * Your application specific code will go here
 */
define(['knockout', 'ojs/ojcontext', 'ojs/ojmodule-element-utils', 'ojs/ojknockouttemplateutils', 'ojs/ojcorerouter', 'ojs/ojmodulerouter-adapter', 'ojs/ojknockoutrouteradapter', 'ojs/ojurlparamadapter', 'ojs/ojresponsiveutils', 'ojs/ojresponsiveknockoututils', 'ojs/ojarraydataprovider','sesion',
        'ojs/ojdrawerpopup', 'ojs/ojmodule-element', 'ojs/ojknockout','ojs/ojactioncard'],
  function(ko, Context, moduleUtils, KnockoutTemplateUtils, CoreRouter, ModuleRouterAdapter, KnockoutRouterAdapter, UrlParamAdapter, ResponsiveUtils, ResponsiveKnockoutUtils, ArrayDataProvider, Sesion) {

     function ControllerViewModel() {

      this.KnockoutTemplateUtils = KnockoutTemplateUtils;

      // Handle announcements sent when pages change, for Accessibility.
      this.manner = ko.observable('polite');
      this.message = ko.observable();
      announcementHandler = (event) => {
          this.message(event.detail.message);
          this.manner(event.detail.manner);
      };

      document.getElementById('globalBody').addEventListener('announce', announcementHandler, false);


      // Media queries for responsive layouts
      const smQuery = ResponsiveUtils.getFrameworkQuery(ResponsiveUtils.FRAMEWORK_QUERY_KEY.SM_ONLY);
      this.smScreen = ResponsiveKnockoutUtils.createMediaQueryObservable(smQuery);
      const mdQuery = ResponsiveUtils.getFrameworkQuery(ResponsiveUtils.FRAMEWORK_QUERY_KEY.MD_UP);
      this.mdScreen = ResponsiveKnockoutUtils.createMediaQueryObservable(mdQuery);

      let navData = [
        { path: '', redirect: 'login' },
        { path: 'login' },
        { path: 'logout' },
        { path: 'dashboard', detail: { label: 'Dashboard', iconClass: 'oj-ux-ico-bar-chart' } },
        { path: 'catalogos', detail: { label: 'Catálogos', iconClass: 'oj-ux-ico-documents' } },
        { path: 'mediacion', detail: { label: 'Mediación', iconClass: 'oj-ux-ico-child-solid' } },
        
        /*{ path: 'incidents', detail: { label: 'Incidents', iconClass: 'oj-ux-ico-fire' } },
        { path: 'customers', detail: { label: 'Customers', iconClass: 'oj-ux-ico-contact-group' } },
        { path: 'about', detail: { label: 'About', iconClass: 'oj-ux-ico-information-s' } }*/
      ];

      // Router setup
      this.router = new CoreRouter(navData, {
        urlAdapter: new UrlParamAdapter()
      });
      
      this.router.sync();

      this.moduleAdapter = new ModuleRouterAdapter(this.router);

      this.selection = new KnockoutRouterAdapter(this.router);

      // Setup the navDataProvider with the routes, excluding the first redirected
      // route.
      this.navDataProvider = new ArrayDataProvider(navData.slice(3), {keyAttributes: "path"});

      // Drawer
      self.sideDrawerOn = ko.observable(false);
      self.sideDrawerOnApps = ko.observable(false);

      // Close drawer on medium and larger screens
      this.mdScreen.subscribe(() => { self.sideDrawerOn(false) });

      // Called by navigation drawer toggle button and after selection of nav drawer item
      this.toggleDrawer = () => {
        self.sideDrawerOn(!self.sideDrawerOn());
      }

      this.toggleDrawerApps = () => {
        self.sideDrawerOnApps(!self.sideDrawerOnApps());
      }

      // Header
      // Application Name used in Branding Area
      this.appName = ko.observable("PJPuebla");
      // User Info used in Global Navigation area
      this.userLogin = ko.observable(false);
      this.userName = ko.observable();

      // Footer
      this.footerLinks = [
        {name: 'Acerca de', linkId: 'aboutPJPuebla', linkTarget:'http://www.pjpuebla.gob.mx'},
        /*{ name: "Contact Us", id: "contactUs", linkTarget: "http://www.oracle.com/us/corporate/contact/index.html" },
        { name: "Legal Notices", id: "legalNotices", linkTarget: "http://www.oracle.com/us/legal/index.html" },
        { name: "Terms Of Use", id: "termsOfUse", linkTarget: "http://www.oracle.com/us/legal/terms/index.html" },
        { name: "Your Privacy Rights", id: "yourPrivacyRights", linkTarget: "http://www.oracle.com/us/legal/privacy/index.html" },*/
      ];

      this.menuUsuario = ((event)=>{
        if(event.detail.selectedValue=='out'){
          Sesion.init();
          this.validaSesion();
        }
      });

      this.validaSesion = (()=>{
        Sesion.valida();

        if (!Sesion.estaActiva()){
          this.router.go({path: 'login'});
        }

      });

      this.startToggle = () => this.startOpened(!this.startOpened());

     }
     // release the application bootstrap busy state
     Context.getPageContext().getBusyContext().applicationBootstrapComplete();

     return new ControllerViewModel();
  }
);
