using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.DomainObjects;

namespace ME.EF.DomainObjects
{
    public class User : IUser
    {

        #region IUser 成员

        public string UserName
        {
            get;
            set;
        }

        public string Password
        {
            get;
            set;
        }

        public string EmployeeNumber
        {
            get;
            set;
        }

        public string Email
        {
            get;
            set;
        }

        #endregion
    }
}
