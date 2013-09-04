using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.Core.Repository
{
    public interface IMembershipRepository
    {





        bool ValidateUser(string userName, string password);
    }
}
