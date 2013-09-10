﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
//using ME.Infrastructure;
using Ninject;

namespace ME.Infrastructure.Ninject
{
    //http://msdn.microsoft.com/en-us/library/ff648449.aspx
    //http://www.ladislavmrnka.com/2011/03/unity-build-in-lifetime-managers/
    //http://www.cnblogs.com/jinzhao/archive/2011/08/11/2134582.html

    public class NinjectDependencyResolver : System.Web.Mvc.IDependencyResolver
    {
        private readonly IKernel _kernel;

        public NinjectDependencyResolver(IKernel kernel)
        {
            _kernel = kernel;
        }

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
            //kernel.Bind<T>().ToConstant<T>(instance);
            _kernel.Bind<T>().ToMethod(context => instance).InSingletonScope();
        }

        public void Inject<T>(T existing)
        {
            _kernel.Inject(existing);
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

        #region IDependencyResolver 成员

        public object GetService(Type serviceType)
        {
            return _kernel.TryGet(serviceType);
        }

        public IEnumerable<object> GetServices(Type serviceType)
        {
            try
            {
                return _kernel.GetAll(serviceType);
            }
            catch (Exception)
            {
                return new List<object>();
            }
        }

        #endregion
    }

}
