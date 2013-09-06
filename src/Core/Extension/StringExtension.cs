using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;
using System.Web.Security;

namespace ME
{
    public static class StringExtension
    {
        public static string Hash(this string target)
        {

            string password = FormsAuthentication.HashPasswordForStoringInConfigFile(target, "MD5");
            return password;

            //using (MD5 md5 = MD5.Create())
            //{
            //    byte[] data = Encoding.Unicode.GetBytes(target);
            //    byte[] hash = md5.ComputeHash(data);

            //    return Convert.ToBase64String(hash);
            //}
        }
    }
}
