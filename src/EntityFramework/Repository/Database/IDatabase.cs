using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.EF.DomainObjects;

namespace ME.EF.Repository
{
    public interface IDatabase : IDisposable
    {
        IQueryable<User> UserDataSource
        {
            get;
        }
    }
}
