
if OBJECT_ID('dbo.users') is not null
    drop table [dbo].[users]
if OBJECT_ID('dbo.roles') is not null
    drop table [dbo].[roles]


if OBJECT_ID('dbo.menu_links') is not null
    drop table [dbo].[menu_links]


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

    [password_reset_token] UNIQUEIDENTIFIER,
    [password_reset_expiration] datetime,

    [status]  tinyint not null   -- 0 : 锁定  1 : 激活
 )

create unique nonclustered index idx_users_job_number on dbo.users(job_number)
where job_number is not null;


CREATE TABLE menu_links 
(
    mlid INT IDENTITY(1,1) PRIMARY KEY,
    plid INT,
    link_path VARCHAR(255) NOT NULL,
    link_title VARCHAR(255) NOT NULL,
    hidden TINYINT NOT NULL ,
    has_children TINYINT NOT NULL ,
    weight INT NOT NULL , -- 默认0， 越大越后面
    depth TINYINT NOT NULL,
    p1 INT ,
    p2 INT ,
    p3 INT ,
    p4 INT ,
    p5 INT ,
    p6 INT ,
    p7 INT ,
    p8 INT ,
    p9 INT 
)




