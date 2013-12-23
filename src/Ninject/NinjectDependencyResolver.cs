using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
//using ME.Infrastructure;
using Ninject;
using Ninject.Syntax;

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
