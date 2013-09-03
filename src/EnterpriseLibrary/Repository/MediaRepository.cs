using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Repository;

namespace ME.EnterpriseLibrary.Repository
{
    public class MediaRepository : IMediaRepository
    {

        #region IMediaRepository 成员

        public string GetMessage()
        {
            return "hello world!";
        }

        #endregion
    }
}
