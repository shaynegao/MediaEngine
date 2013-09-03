using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME
{
    public class DisposableResource : IDisposable
    {
        ~DisposableResource()
        {
            Dispose(false); 
        }


        #region IDisposable 成员

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        #endregion

        protected virtual void Dispose(bool isDisposing)
        { 
        
        }
    }
}
