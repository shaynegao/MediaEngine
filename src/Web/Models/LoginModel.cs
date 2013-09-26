using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace ME.Web.Models
{
    public class LoginModel
    {
        [Required]
        [Display(Name = "UserName")]
        public string UserName { get; set; }
        [Required]
        [Display(Name = "Password")]
        public string Password { get; set; }
    }
}