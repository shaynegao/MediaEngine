using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Infrastructure;
using Microsoft.Practices.Unity;
using Microsoft.Practices.Unity.Configuration;
using System.Configuration;
using System.Collections.ObjectModel;

namespace ME.Infrastructure.Unity
{
    public class UnityDependencyResolver : DisposableResource, IDependencyResolver
    {

        private readonly IUnityContainer _container;

        public UnityDependencyResolver() : this(new UnityContainer())
        {
            try
            {
                UnityConfigurationSection configuration = (UnityConfigurationSection)ConfigurationManager.GetSection("unity");
                //configuration.Containers.Default.Configure(_container);
                configuration.Configure(_container);
            }
            catch (Exception ex)
            {
                
                throw ex;
            }

        }

        public UnityDependencyResolver(IUnityContainer container)
        {
            _container = container;
        }

        #region IDependencyResolver 成员

        public void Register<T>(T instance)
        {
            // 把现有的一个实例注册为singleton
            _container.RegisterInstance<T>(instance);
        }

        public void Inject<T>(T existing)
        {
            // 把现有实例中的成员构造起来？
            _container.BuildUp<T>(existing);
        }

        public T Resolve<T>(Type type)
        {
            return (T) _container.Resolve(type);
        }

        public T Resolve<T>(Type type, string name)
        {
            return (T)_container.Resolve(type, name);
        }

        public T Resolve<T>()
        {
            return _container.Resolve<T>();
        }

        public T Resolve<T>(string name)
        {
            return _container.Resolve<T>(name);
        }

        public IEnumerable<T> ResolveAll<T>()
        {
            IEnumerable<T> namedInstances = _container.ResolveAll<T>();
            T unnamedInstance = default(T);

            try
            {
                unnamedInstance = _container.Resolve<T>();
            }
            catch (ResolutionFailedException)
            {
            }

            if (Equals(unnamedInstance, default(T)))
            {
                return namedInstances;
            }

            return new ReadOnlyCollection<T>(new List<T>(namedInstances) { unnamedInstance});
        }

        #endregion

        protected override void Dispose(bool isDisposing)
        {
            if (isDisposing)
                _container.Dispose();

            base.Dispose(isDisposing);
        }
    }
}
