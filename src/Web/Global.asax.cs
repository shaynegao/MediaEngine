using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using ME.Infrastructure;
using ME.Web.Controllers;
using Ninject;
using ME.Infrastructure.Ninject;
using ME.Core.Repository;


namespace ME.Web
{
    // Note: For instructions on enabling IIS6 or IIS7 classic mode, 
    // visit http://go.microsoft.com/?LinkId=9394801

    public class MvcApplication : System.Web.HttpApplication
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
        }

        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

            routes.MapRoute(
                "Login",
                "login",
                 new { controller = "Account", action = "Login" }
            );

            routes.MapRoute(
                "Logout",
                "logout",
                 new { controller = "Account", action = "Logout" }
            );

            routes.MapRoute(
                "Default", // Route name
                "{controller}/{action}/{id}", // URL with parameters
                new { controller = "Home", action = "Index", id = UrlParameter.Optional } // Parameter defaults
            );

        }

        protected void Application_Start()
        {
     //       IoC.InitializeWith(new DependencyResolverFactory());

            SetupDependencyInjection();

            AreaRegistration.RegisterAllAreas();

            RegisterGlobalFilters(GlobalFilters.Filters);
            RegisterRoutes(RouteTable.Routes);

            //var factory = new ControllerFactory();
            //ControllerBuilder.Current.SetControllerFactory(factory);
        }

        public void SetupDependencyInjection()
        {
            IKernel kernel = new StandardKernel();
     //       kernel.Bind<IMembershipRepository>().To<MembershipRepository>();
            DependencyResolver.SetResolver(new NinjectDependencyResolver(kernel));
        }

    }
}