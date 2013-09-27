using System.Web.Mvc;
using ME.Core.Helper;

namespace ME.Web.Controllers
{
    
    public class HomeController : Controller
    {
        public HomeController()
        {
        }

        //
        // GET: /Home/
        [MEAuthorize]
        [HttpGet]
        public ActionResult Index()
        {
            ViewBag.Message = "Hello World!";
            return View();
        }

        [MEAuthorize]
        [HttpGet]
        public ActionResult Index2()
        {
            ViewBag.Message = "blah blah!";
            return View();
        }

        [HttpGet]
        public ActionResult NoAccess()
        {
            return View();
        }
    }
}
