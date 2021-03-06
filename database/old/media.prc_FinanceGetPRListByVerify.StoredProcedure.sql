IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPRListByVerify]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPRListByVerify]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPRListByVerify]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'




























 

-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-06-18   
-- Description: 根据关联ID得到对应的付款、退款列表（不分页）
-- Return Value:
-- Example: 

CREATE proc [media].[prc_FinanceGetPRListByVerify]
    @VerifyID   BIGINT
as
begin
    set nocount on

SELECT * FROM 
(
SELECT
--付款ID
(''P'' + CAST(BI.BillID AS VARCHAR(29))) AS CombinedID
--合同号
, C.ContractCode
--项目名称
, C.ItemName AS BuildingName
--支付主体
, V.VendorName
--付款开始时间
, PP.FeeBeginDate AS PayPeriodBegin
--付费截止时间
, PP.FeeEndDate AS PayPeriodEnd
--实际支付日期
, PB.PayDate AS ActualPayDate
--付款金额
, PB.PayAmount AS ActualPayAmount
--未开票金额
, (PB.PayAmount - PB.CloseAmount) AS UnInvoiceAmount
--本次开发金额
, BI.CloseAmount AS InvoiceAmount
 FROM  media.tbb_Bill_Invoice BI
	JOIN media.tbb_PayBill PB ON BI.BillID = PB.PayBillID
	JOIN media.tbb_PayPlan PP ON PB.PlanPayID = PP.PlanPayID
	JOIN media.tbb_Contract C ON PP.ContractID = C.ContractID
	LEFT JOIN media.tbb_Vendor V ON PP.VendorID = V.VendorID
	WHERE BI.VerifyID = @VerifyID
	AND BI.BillType = 0

UNION

SELECT
--付款ID
(''R'' + CAST(BI.BillID AS VARCHAR(29))) AS CombinedID
--合同号
, C.ContractCode
--项目名称
, C.ItemName AS BuildingName
--支付主体
, V.VendorName
--付款开始时间
, PP.FeeBeginDate AS PayPeriodBegin
--付费截止时间
, PP.FeeEndDate AS PayPeriodEnd
--实际支付日期
, RB.ReturnDate AS ActualPayDate
--付款金额
, RB.ReturnAmount AS ActualPayAmount
--未开票金额
, (RB.ReturnAmount - PB.CloseAmount) AS UnInvoiceAmount
--本次开发金额
, BI.CloseAmount AS InvoiceAmount
 FROM  media.tbb_Bill_Invoice BI
	JOIN media.tbb_ReturnBill RB ON BI.BillID = RB.ReturnBillID
	JOIN media.tbb_PayBill PB ON PB.PayBillID = RB.PayBillID
	JOIN media.tbb_PayPlan PP ON PB.PlanPayID = PP.PlanPayID
	JOIN media.tbb_Contract C ON PP.ContractID = C.ContractID
	LEFT JOIN media.tbb_Vendor V ON PP.VendorID = V.VendorID
	WHERE BI.VerifyID = @VerifyID
	AND BI.BillType = 1
) X
ORDER BY X.ActualPayDate, X.CombinedID
  
end


































' 
END
GO
