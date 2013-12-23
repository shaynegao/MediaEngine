using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.DomainObjects
{
    public interface IUser
    {
        string UserName { get; }

        string Password { get; }

        string EmployeeNumber { get; }

        string Email { get; }

    }
}
