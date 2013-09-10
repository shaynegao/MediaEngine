using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.Core.Repository
{
    public interface IMembershipRepository
    {
        void CreateUser(string userName, string password, string email);

        bool ValidateUser(string userName, string password);
    }
}
