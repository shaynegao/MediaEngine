IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetContract]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetContract]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetContract]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'









-- =============================================
-- Author:  gaoweiwei
-- Create date: 2013-04-23
-- Description: 财务有效合同查询
--   SearchMode  my 我的合同   myDept 部门查询  finance 财务查询  all 所有合同
-- Return Value:
-- Example:
CREATE proc [media].[prc_FinanceGetContract]
(
    @FilterDeveloperID      bigint = null,
    @FilterOperatorID       bigint = null,
    @FilterDeveloperName    VARCHAR(30) = null,
    @FilterOperatorName     VARCHAR(30) = null,
    @FilterDisplayType      varchar(50) = null,
    @FilterContractCode     varchar(50) = ''%'',
    @FilterBuildingID       bigint = null,
    @FilterDeptID           int = null,
    @FilterPayCompanyID     int = null,
    @UserID                 bigint,
    @SearchMode             varchar(20),
    @Debug                  char = ''N''
)
as
begin
    set nocount on

    if @FilterDisplayType = ''''
		set @FilterDisplayType = null
	if 	@FilterContractCode is null or @FilterContractCode = ''''
		set @FilterContractCode = ''%''
		
	CREATE TABLE #dept (DeptID  INT)
    
    if LOWER(@SearchMode) = ''my''
		BEGIN
			set @FilterOperatorID = @UserID

			INSERT INTO #dept (DeptID)
			SELECT U.DeptID
			FROM basic.tbb_User U 
			WHERE U.UserID = @UserID			
		END 
    else    
    IF LOWER(@SearchMode) = ''mydept''
		BEGIN
			INSERT INTO #dept (DeptID)
			SELECT DISTINCT D1.DeptID FROM basic.tbb_Department D 
				JOIN basic.tbb_User U ON D.DeptID = U.DeptID
				JOIN basic.tbb_Department D1 ON D1.DeptNo LIKE D.DeptNo + ''%''
			WHERE U.UserID = @UserID
		END
    else
    IF LOWER(@SearchMode) = ''finance''
   		BEGIN
			INSERT INTO #dept (DeptID)
			SELECT DISTINCT DeptID FROM  basic.VW_UserDept WHERE UserID = @UserID
		END 

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
	
	

  --  if @Debug = ''Y''
  --  begin
		--print ''@FilterDeveloperID '' + str(@FilterDeveloperID)
		--print ''@FilterOperatorID '' + str(@FilterOperatorID)
		--print ''@FilterDisplayType '' + @FilterDisplayType
		--print ''@FilterContractCode '' + @FilterContractCode
		--print ''@FilterBuildingID '' + str(@FilterBuildingID)
		--print ''@FilterDeptID '' + str(@FilterDeptID)
		--print ''@FilterPayCompanyID '' + str(@FilterPayCompanyID)
		--print ''@UserID '' + str(@UserID)
		--print ''@SearchMode '' + @SearchMode
  --  end
    

    select C.ContractID
    , C.ContractCode
    , C.ItemName as BuildingName
    , C.OperatorName
    , C.DeveloperName
    , D.DeptName as DeptName
    , C.PayCompanyID
    , C.DealStatus
    , C.DisplayType
    from media.tbb_Contract C
		LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
    where (C.DealStatus = 3 OR C.DealStatus = 10) -- 执行中或续签
        AND C.IsSignFinished = 1
        and isnull(@FilterDeveloperID, C.DeveloperID) = C.DeveloperID
        and isnull(@FilterOperatorID, C.OperatorID) = C.OperatorID
        AND (ISNULL(@FilterDeveloperName, '''') = '''' OR C.DeveloperName LIKE ''%'' +  @FilterDeveloperName  + ''%'')
        AND (ISNULL(@FilterOperatorName, '''') = '''' OR C.OperatorName LIKE ''%'' +  @FilterOperatorName  + ''%'')
        AND (@FilterDisplayType is null or C.DisplayType = @FilterDisplayType )
        AND (@FilterContractCode = ''%'' or C.ContractCode like @FilterContractCode)
     
        and isnull(@FilterBuildingID, C.ItemID) = C.ItemID
        and isnull(@FilterPayCompanyID, C.PayCompanyID) = C.PayCompanyID
        AND (LOWER(@SearchMode) = ''my'' OR LOWER(@SearchMode) = ''all'' 
			OR ((LOWER(@SearchMode) = ''mydept'' OR LOWER(@SearchMode) = ''finance'') AND 
				C.DeptID IN (SELECT DeptID FROM #dept))
        )

	DROP TABLE #dept
end












' 
END
GO
