using System.Web.Mvc;
using ME.Core.Helper;

namespace ME.Web.Controllers
{
    [MEAuthorize]
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
