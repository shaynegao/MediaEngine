using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ME.Web.Models;
using System.Web.Security;
using ME.Infrastructure.EF;

namespace ME.Web.Controllers
{
    public class AccountController : Controller
    {
        private MembershipRepository _repository;

        public AccountController(MembershipRepository membershipRepository)
        {
            _repository = membershipRepository;
        }

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
                if (_repository.ValidateUser(model.UserName, model.Password))
                {
                    FormsAuthentication.SetAuthCookie(model.UserName, false);  
              
                    if (string.IsNullOrWhiteSpace(returnUrl))
                        return RedirectToAction("Index", "Home");
                    else
                        return Redirect(returnUrl);
                }
                else 
                {
                    ModelState.AddModelError("", "The user name or password provided is incorrect.");
                }
            }

            return View(model);
            
        }

        [HttpGet]
        public ActionResult CreateUser()
        {
            return View();
        }

        [HttpPost]
        public ActionResult CreateUser(CreateUserModel model)
        {
            if (ModelState.IsValid)
            {
                _repository.CreateUser(model.UserName, model.Password, model.Email);
                return RedirectToAction("Index", "Home");
            }

            return View(model);
        }


        [ChildActionOnly]
        public ActionResult Menu()
        {
            return PartialView("_Menu");
        }



    }
}
