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
        private readonly IMediaRepository _mediaRepository;

        public HomeController(IMediaRepository mediaRepository)
        {
            this._mediaRepository = mediaRepository;
        }

        //
        // GET: /Home/
        [HttpGet]
        public ActionResult Index()
        {
            var msg = _mediaRepository.GetMessage();
            ViewBag.Message = msg;
            return View();
        }

    }
}
