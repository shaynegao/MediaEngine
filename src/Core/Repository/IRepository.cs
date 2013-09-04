using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.Repository
{
    public interface IRepository<TEntity>
    {
        void Add(TEntity entity);

        void Remove(TEntity entity);
    }
}
