using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ME.Core.Helper
{
    public class RandomImage : IDisposable
    {
        private bool _isDisposed = false;
 

        #region IDisposable 成员

        void IDisposable.Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        #endregion

        protected virtual void Dispose(bool disposing)
        {
            if (!_isDisposed)
            {
                if (disposing)
                { 
                    // Release Managed resources
                
                }


                // Release UnManaged Resources
                _isDisposed = true;
            }
            
        
        }

    }
}
