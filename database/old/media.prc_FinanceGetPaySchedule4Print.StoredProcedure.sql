IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaySchedule4Print]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPaySchedule4Print]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPaySchedule4Print]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPaySchedule4Print] (
 	@PaymentScheduleId BIGINT
 ) as
SELECT 
		C.DeptName
		, C.OperatorName AS ApplyUserName
		, V.VendorName AS VendorName
		, PR1.ResourceName AS FeeType
		, PR2.ResourceName AS PayMethod
		, C.PayCompanyName AS PayCompanyName
		, ISNULL(PA.AccountNumber, '''') AS ActualPayeeAccountNumber
		, ISNULL(PA.AccountBank, '''') AS ActualPayeeBankName
		, ISNULL(PA.AccountName, '''') AS ActualPayeeName
	
	
		, PP.PlanPayDate AS ExpectDate
		, PP.FeeBeginDate AS PayPeriodBegin
		, PP.FeeEndDate AS PayPeriodEnd
		, C.ItemID AS BuildingID
		, C.ItemName AS BuildingName
		, C.ContractCode AS ContractCode
		, PB.PayAmount AS PayAmount
		, GC.SignedLocationCount
		, ISNULL(GC.InstalledCnt, 0) AS InstalledCnt
		

	 FROM media.tbb_PayBill PB
	INNER JOIN media.tbb_PayPlan PP ON PB.PlanPayID = PP.PlanPayID
	INNER JOIN media.tbb_Contract C ON pp.ContractID = C.ContractID
	LEFT OUTER JOIN media.tbi_PayAccount PA ON PB.PayBillID = PA.PayBillID
	LEFT OUTER JOIN media.tbb_Vendor V ON PP.VendorID = V.VendorID
	LEFT OUTER JOIN basic.tbd_PubResource PR1 ON PR1.ResourceTypeCode = ''EA040'' AND PR1.ResourceCode = PP.FeeType 
	LEFT OUTER JOIN basic.tbd_PubResource PR2 ON PR2.ResourceTypeCode = ''BM004'' AND PR2.ResourceCode = PB.PayKind
	LEFT OUTER JOIN (
	
		SELECT C.ContractID, C.SignedLocationCount,  (C.SignedLocationCount  - C.PresentUsingCount 
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
	
	) GC ON GC.ContractID = C.ContractID	
	
	--WHERE PB.PayBillID = 6225
	WHERE PB.PayBillID = @PaymentScheduleId
' 
END
GO
