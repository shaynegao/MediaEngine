using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Infrastructure;

namespace ME.Infrastructure
{
    public interface IDependencyResolverFactory
    {
        IDependencyResolver CreateInstance();
    }
}
