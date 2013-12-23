using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ME.Infrastructure;
using System.Web.Routing;

namespace ME.Web.Controllers
{
    public class ControllerFactory : DefaultControllerFactory
    {
        protected override IController GetControllerInstance(RequestContext requestContext, Type controllerType)
        {
            
            return controllerType == null
                ? base.GetControllerInstance(requestContext, controllerType)
                : IoC.Resolve<IController>(controllerType);
        }
    }
}