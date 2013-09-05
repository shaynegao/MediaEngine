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
        protected override bool AuthorizeCore(System.Web.HttpContextBase httpContext)
        {
            if (httpContext == null)
                throw new ArgumentNullException("httpContext");

            IPrincipal user = httpContext.User;
            if (!user.Identity.IsAuthenticated)
                return false;

            // this.Roles.

            return true;
            //return base.AuthorizeCore(httpContext);
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
