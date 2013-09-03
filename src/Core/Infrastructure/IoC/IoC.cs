using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.Infrastructure
{
    public static class IoC
    {
        private static IDependencyResolver _resolver;

        public static void InitializeWith(IDependencyResolverFactory factory)
        {
            _resolver = factory.CreateInstance();
        }

        public static T Resolve<T>(Type type)
        {
            return _resolver.Resolve<T>(type);
        }

        public static void Reset()
        {
            if (_resolver != null)
                _resolver.Dispose();
        }
    }
}
