﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ME.Core.Repository;
using ME.EF;

namespace ME.Infrastructure.EF
{
    public class MembershipRepository : IMembershipRepository
    {
        public bool ValidateUser(string userName, string password)
        {
            using (var db = new MediaEngineEntities())
            {
                string encrpted = password.Trim().Hash();

                var n = db.users.Count(t => t.email == userName && t.password == encrpted);

                if (n == 0) 
                    return false;
                else
                    return true;
            }
        }


        public void CreateUser(string userName, string employeeNumber, string password, string email)
        {
            using (var db = new MediaEngineEntities())
            {
                var user = new ME.EF.user();
                user.name = userName;
                user.password = password.Trim().Hash();
                user.email = email;
                user.created = DateTime.Now;

                db.users.Add(user);
                db.SaveChanges();
            }
        }

    }
}
