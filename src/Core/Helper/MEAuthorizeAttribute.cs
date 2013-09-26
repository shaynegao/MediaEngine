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
            if (user == null || !user.Identity.IsAuthenticated)
            {
                return false;
            }

            // 1.current visit page  ==> can view roles

            var x = httpContext.Handler.GetType();


            var requestContext = httpContext.Request.RequestContext;
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

        protected override void HandleUnauthorizedRequest(AuthorizationContext filterContext)
        {
            //if (!filterContext.HttpContext.User.Identity.IsAuthenticated)
            //{ 
            //    filterContext.Result = 
            //}


            base.HandleUnauthorizedRequest(filterContext);
        }

    }
}
