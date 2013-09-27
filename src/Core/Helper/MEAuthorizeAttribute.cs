using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.Mvc;
using System.Security.Principal;

namespace ME.Core.Helper
{
    public class MEAuthorizeAttribute : AuthorizeAttribute
    {
        // must be thread-safe
        protected override bool AuthorizeCore(System.Web.HttpContextBase httpContext)
        {
            if (httpContext == null)
            {
                throw new ArgumentNullException("httpContext");
            }

            IPrincipal user = httpContext.User;
            if (!user.Identity.IsAuthenticated)
            {
                return false;
            }

            var controllerType = httpContext.Session["ControllerType"] != null ? httpContext.Session["ControllerType"].ToString() : "";
            var actionName = httpContext.Session["ActionName"] != null ? httpContext.Session["ActionName"].ToString() : "";


            if (string.IsNullOrEmpty(controllerType) ||
                string.IsNullOrEmpty(actionName))
            {
                return false;
            }

            //string controller = requestContext.RouteData.GetRequiredString("controller");
            //string action = requestContext.RouteData.GetRequiredString("action");

            //var urlHelper = new UrlHelper(requestContext);
            //var url = urlHelper.Action(action, controller, requestContext.RouteData.Values);


            // 2.user's role

            // 3.check

            //if (_usersSplit.Length > 0 && !_usersSplit.Contains(user.Identity.Name, StringComparer.OrdinalIgnoreCase))
            //{
            //    return false;
            //}

            //if (_rolesSplit.Length > 0 && !_rolesSplit.Any(user.IsInRole))
            //{
            //    return false;
            //}

            return true;
        }

        public override void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext.HttpContext.User.Identity.IsAuthenticated)
            {
                var actionDescriptor = filterContext.ActionDescriptor;
                string controllerType = actionDescriptor.ControllerDescriptor.ControllerType.ToString();
                string actionName = actionDescriptor.ActionName;

                filterContext.HttpContext.Session["ControllerType"] = controllerType;
                filterContext.HttpContext.Session["actionName"] = actionName;

            }

            base.OnAuthorization(filterContext);
            
        }


        protected override void HandleUnauthorizedRequest(AuthorizationContext filterContext)
        {
            if (filterContext.HttpContext.User.Identity.IsAuthenticated)
                filterContext.Result = new RedirectResult(@"~\Home\NoAccess");
            else
                base.HandleUnauthorizedRequest(filterContext);
        }

    }
}
