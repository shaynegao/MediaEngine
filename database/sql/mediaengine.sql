
if OBJECT_ID('dbo.users') is not null
    drop table [dbo].[users]
if OBJECT_ID('dbo.roles') is not null
    drop table [dbo].[roles]




CREATE TABLE [users]
(
    [uid] INT IDENTITY(1,1) PRIMARY KEY,
    [name] VARCHAR(60) NOT NULL,
    [password]  varchar(100) not null,
    [email]     varchar(100) null,
    [job_number]     varchar(100) null,  -- 工号
    [created] datetime not null,
    [access]  datetime  null,
    [login]   datetime  null,
    [status]  tinyint not null   -- 0 : 锁定  1 : 激活
 )






create unique nonclustered index idx_users_job_number on dbo.users(job_number)
where job_number is not null;

