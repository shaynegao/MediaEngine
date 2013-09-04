using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ME.Repository;

namespace ME.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
  
        public HomeController()
        {
        }

        //
        // GET: /Home/
        [HttpGet]
        public ActionResult Index()
        {
            ViewBag.Message = "Hello World!";
            return View();
        }

    }
}
