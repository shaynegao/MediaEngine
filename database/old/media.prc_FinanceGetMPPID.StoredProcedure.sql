IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetMPPID]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetMPPID]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetMPPID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'




CREATE PROCEDURE [media].[prc_FinanceGetMPPID]
(
    @PayCompanyID   INT,
    @DeptID         INT,
    @Year           INT,
    @Month          INT,
    @OperatorId     INT
)
AS

    INSERT INTO media.tbb_ApplyBatch
            ( ApplyUserID ,
              ApplyUserName ,
              PayCompanyID ,
              PayCompanyName ,
              DeptID ,
              DeptName ,
              ApplyYear ,
              ApplyMonth ,
              ValidStatus ,
              ApplyAmount ,
              CreateTime ,
              LastUpdateTime
            )
    SELECT @OperatorId , -- ApplyUserID - bigint
              (SELECT  UserName FROM basic.tbb_User WHERE UserID = @OperatorId)  , -- ApplyUserName - varchar(50)
              @PayCompanyID , -- PayCompanyID - int
              (SELECT PayCompanyName FROM basic.tbb_PayCompany WHERE PayCompanyID = @PayCompanyID) , -- PayCompanyName - varchar(100)
              @DeptID , -- DeptID - int
              (SELECT DeptName FROM basic.tbb_Department WHERE DeptID = @DeptID) , -- DeptName - varchar(50)
              @Year , -- ApplyYear - int
              @Month , -- ApplyMonth - int
              0 , -- ValidStatus - int
              0 , -- ApplyAmount - decimal
              getdate(), -- CreateTime - datetime
              getdate()  -- LastUpdateTime - datetime
              
              
    SELECT @@identity AS ID


' 
END
GO
