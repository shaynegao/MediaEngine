using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace ME.Web.Models
{
    public class CreateUserModel
    {
        [Required]
        public string UserName { get; set; }
        [Required(ErrorMessage="必须输入密码")]
        public string Password { get; set; }
        [Required]
        public string Email { get; set; }
    }
}