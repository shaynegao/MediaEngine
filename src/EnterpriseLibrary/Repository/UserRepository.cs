using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Repository;
using ME.DomainObjects;

namespace ME.Infrastructure.EnterpriseLibrary.Repository
{
    public class UserRepository : IUserRepository
    {
        #region IRepository<IUser> 成员

        public void Add(IUser entity)
        {
            throw new NotImplementedException();
        }

        public void Remove(IUser entity)
        {
            throw new NotImplementedException();
        }

        #endregion

        #region IUserRepository 成员

        public IUser GetUserByUserName(string userName)
        {
            throw new NotImplementedException();
        }

        public IUser GetUserByEmail(string email)
        {
            throw new NotImplementedException();
        }

        #endregion
    }
}
