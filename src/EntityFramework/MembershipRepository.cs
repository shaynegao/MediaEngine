using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using EntityFramework;
using System.Data.Entity;

namespace ME.Infrastructure.EF
{
    public class MembershipRepository
    {

        public bool ValidateUser(string userName, string password)
        {
            using (var db = new MediaEngineEntities())
            {
           //     Database.SetInitializer<MediaEngineEntities>(null);

                var n = db.users.Count(t => t.name == userName && t.password == password);

                if (n == 0) 
                    return false;
                else
                    return true;
            }
        }


        public void Add()
        {
            using (var db = new MediaEngineEntities())
            {
                var user = new user();
                user.name = "高卫卫";
                user.password = "111";
                user.created = DateTime.Now;

                db.users.Add(user);
                db.SaveChanges();
            }
        }

    }
}
