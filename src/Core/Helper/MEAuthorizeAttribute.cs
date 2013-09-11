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

            // 1.current visit page  ==> can view roles

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

            return false;
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
