using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Infrastructure;
//using Ninject.Modules;

namespace ME.Infrastructure.Ninject
{
    //http://msdn.microsoft.com/en-us/library/ff648449.aspx
    //http://www.ladislavmrnka.com/2011/03/unity-build-in-lifetime-managers/
    //http://www.cnblogs.com/jinzhao/archive/2011/08/11/2134582.html

    public class NinjectDependencyResolver : IDependencyResolver
    {
   //     private readonly NinjectModule _module;

        //public NinjectDependencyResolver(NinjectModule module)
        //{
        //    _module = module;
        //}

        //public NinjectDependencyResolver() : this(new NinjectModule())
        //{

        //}

        #region IDependencyResolver 成员

        public void Register<T>(T instance)
        {
            throw new NotImplementedException();
        }

        public void Inject<T>(T existing)
        {
            throw new NotImplementedException();
        }

        public T Resolve<T>(Type type)
        {
            throw new NotImplementedException();
        }

        public T Resolve<T>(Type type, string name)
        {
            throw new NotImplementedException();
        }

        public T Resolve<T>()
        {
            throw new NotImplementedException();
        }

        public T Resolve<T>(string name)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<T> ResolveAll<T>()
        {
            throw new NotImplementedException();
        }

        #endregion

        #region IDisposable 成员

        public void Dispose()
        {
            throw new NotImplementedException();
        }

        #endregion
    }

}
