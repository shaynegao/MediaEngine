IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetContractMediaInfo]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetContractMediaInfo]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetContractMediaInfo]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

































-- =============================================
-- Author:  gaoweiwei
-- Create date: 2013-05-17
-- Description: 获取合同内媒体位信息
-- Return Value:
-- Example:
CREATE proc [media].[prc_FinanceGetContractMediaInfo]
(
    @ContractID      bigint = null
)
as
begin
    set nocount on

   		SELECT C.ContractID, (C.SignedLocationCount  - C.PresentUsingCount 
		 - C.PresentOwnsCount ) AS UsableCnt, Install.InstalledCnt, Install.TempUninstallCnt
		FROM media.tbb_Contract C
		LEFT JOIN (
			SELECT CML.ContractID,
			SUM(CASE WHEN MB.InstallStatus = 1 THEN 1 ELSE 0 END) AS InstalledCnt,
			SUM(CASE WHEN MB.InstallStatus = 2 THEN 1 ELSE 0 END) AS TempUninstallCnt
			FROM media.tbr_Contract_MediaLocation  CML 
			JOIN media.tbb_MediaLocation ML ON CML.LocationID = ML.LocationID
			JOIN assemble.tbb_MediaDevice MB ON ML.LocationID = MB.LocationID
			GROUP BY CML.ContractID )
		 Install ON C.ContractID = Install.ContractID
		WHERE C.ContractID = @ContractID
    
end




















' 
END
GO
