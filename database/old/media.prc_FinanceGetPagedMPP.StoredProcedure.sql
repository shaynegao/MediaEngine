IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedMPP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedMPP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedMPP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
 
CREATE PROCEDURE [media].[prc_FinanceGetPagedMPP]
(
	@FilterMPPID		  BIGINT = null,
	@FilterPayCompany     INT = null,
	@FilterDeptID		  INT = null,
 	@FilterMonth 		  VARCHAR(6) = null ,   			-- yyyyMM
    @UserID               BIGINT,
    @PageSize             int,
    @PageIndex            int,
    @TotalCount           int output
)
AS

	CREATE TABLE #dept (DeptID  INT)
	
	INSERT INTO #dept (DeptID)
    SELECT DISTINCT DeptID FROM  basic.VW_UserDept WHERE UserID = @UserID

    IF ISNULL(@FilterDeptID, 0) <> 0
    BEGIN
    
        DELETE D
        FROM #dept D
        WHERE D.DeptID NOT IN (
            SELECT D2.DeptID FROM basic.tbb_Department D1
            JOIN basic.tbb_Department D2 ON D2.DeptNo LIKE D1.DeptNo + ''%''
            WHERE D1.DeptID = @FilterDeptID
        )
    END

    CREATE TABLE #T
    (
        rn INT IDENTITY(1,1),
        [ApplyBatchID] [bigint],
        [ApplyUserID] [bigint] ,
        [ApplyUserName] [varchar] (50) ,
        [PayCompanyID] [int] ,
        [PayCompanyName] [varchar] (100),
        [DeptID] [int] ,
        [DeptName] [varchar] (50),
        [ApplyYear] [int] ,
        [ApplyMonth] [int] ,
        [ValidStatus] [int] ,
        [ApplyAmount] [decimal] (10, 2) 
    )


    INSERT INTO #T
            ( ApplyBatchID ,
              ApplyUserID ,
              ApplyUserName ,
              PayCompanyID ,
              PayCompanyName ,
              DeptID ,
              DeptName ,
              ApplyYear ,
              ApplyMonth ,
              ValidStatus ,
              ApplyAmount
            )   
    SELECT  ApplyBatchID ,
            ApplyUserID ,
            ApplyUserName ,
            PayCompanyID ,
            PayCompanyName ,
            DeptID ,
            DeptName ,
            ApplyYear ,
            ApplyMonth ,
            ValidStatus ,
            ApplyAmount  FROM media.tbb_ApplyBatch AB
    WHERE  AB.DeptID IN ( SELECT DeptID FROM #dept)
    AND ISNULL(@FilterPayCompany, PayCompanyID) = PayCompanyID
    and (ISNULL(@FilterMonth, '''') = '''' OR convert(varchar(6), ApplyYear * 100 + ApplyMonth) = @FilterMonth)
	AND ISNULL(@FilterMPPID, AB.ApplyBatchID) = AB.ApplyBatchID	 				
    ORDER BY ApplyBatchID DESC
    
    select @TotalCount = COUNT(*) from #T

    SELECT *
    FROM   #t T
    WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
           AND T.rn <= @PageSize * @PageIndex
    order by rn






' 
END
GO
