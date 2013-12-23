using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.DomainObjects;

namespace ME.Repository
{
    public interface IUserRepository : IRepository<IUser>
    {

        IUser FindByUserName(string userName);

        IUser FindByEmail(string email);
    }
}
