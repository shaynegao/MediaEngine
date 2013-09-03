using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ME.Web.Models;
using System.Web.Security;

namespace ME.Web.Controllers
{
    public class AccountController : Controller
    {
        [HttpGet]
        public ActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Login(LoginModel model, string returnUrl)
        {
            //       return RedirectToAction("Index");
            // RedirectToAction 会调用Index方法，并会产生 HTTP 302
            // return View(), 不会调用Index方法，具体的Model需要指定

            if (ModelState.IsValid)
            {
                if (Membership.ValidateUser(model.UserName, model.Password))
                {
                    return RedirectToAction("Index", "Home");
                }
                else 
                {
                    ModelState.AddModelError("", "The user name or password provided is incorrect.");
                }

                return Redirect(returnUrl);
            }


            return View(model);
            
        }


    }
}
