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
define(['ojs/ojcontext', 'ojs/ojresponsiveutils', 'ojs/ojresponsiveknockoututils', 'knockout', 'ojs/ojmodule-element-utils', 'ojs/ojknockout',  'ojs/ojmodule-element'],
  (Context, ResponsiveUtils, ResponsiveKnockoutUtils, ko, ModuleElementUtils) => {

     class ControllerViewModel {
      constructor() {

        // Media queries for responsive layouts
        const smQuery = ResponsiveUtils.getFrameworkQuery(ResponsiveUtils.FRAMEWORK_QUERY_KEY.SM_ONLY);
        this.smScreen = ResponsiveKnockoutUtils.createMediaQueryObservable(smQuery);

        // Header
        // Application Name used in Branding Area
        this.appName = ko.observable("Consulta Ciudadana");
        // User Info used in Global Navigation area
        this.userLogin = ko.observable("");

        this.consultaModule = ModuleElementUtils.createConfig({
          name: 'consulta'
        })

        // Footer
        this.footerLinks = [
          { name: 'PJPuebla', linkId: 'aboutPJPuebla', linkTarget: 'https://www.pjpuebla.gob.mx' },
          /*{ name: "Contact Us", id: "contactUs", linkTarget: "http://www.oracle.com/us/corporate/contact/index.html" },
          { name: "Legal Notices", id: "legalNotices", linkTarget: "http://www.oracle.com/us/legal/index.html" },
          { name: "Terms Of Use", id: "termsOfUse", linkTarget: "http://www.oracle.com/us/legal/terms/index.html" },
          { name: "Your Privacy Rights", id: "yourPrivacyRights", linkTarget: "http://www.oracle.com/us/legal/privacy/index.html" },*/
        ];
      }
    }

     // release the application bootstrap busy state
     Context.getPageContext().getBusyContext().applicationBootstrapComplete();

     return new ControllerViewModel();
  }
);