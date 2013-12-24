using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Repository;
using ME.DomainObjects;

namespace ME.EF.Repository
{
    public class UserRepository : IUserRepository
    {

        #region IUserRepository 成员

        public IUser FindByUserName(string userName)
        {
            throw new NotImplementedException();
        }

        public IUser FindByEmail(string email)
        {
            throw new NotImplementedException();
        }

        #endregion

        #region IRepository<IUser> 成员

        public void Add(IUser entity)
        {
            //using (var db = new MediaEngineEntities())
            //{
            //    db.users.Add(entity);
            //    db.SaveChanges();
            //}
        }   

        public void Remove(IUser entity)
        {
            throw new NotImplementedException();
        }

        #endregion
    }
}
