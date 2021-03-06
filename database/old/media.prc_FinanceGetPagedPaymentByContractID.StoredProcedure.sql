IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentByContractID]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedPaymentByContractID]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedPaymentByContractID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
























-- =============================================
-- Author:  gaoweiwei
-- Create date: 2013-09-16
-- Description: 通过合同编号得到已付款分页记录
-- Return Value:

CREATE proc [media].[prc_FinanceGetPagedPaymentByContractID]
    
    @FilterContractID     bigint,
    @PageSize             int,
    @PageIndex            int,
    @TotalCount           int output



as
begin
   set nocount on

   create table #T
   (
     rn  int identity(1,1),
     PayBillID   BIGINT,
     --计划支付时间
     ExpectDate date,
     --实际付款日期
     ActualPayDate   date,
     --实际付款金额
     ActualPayAmount decimal(10,2),
     
     ActualPayeeBankName VARCHAR(100),
     ActualPayeeName VARCHAR(100),
     ActualPayeeAccountNumber VARCHAR(44),
     ActualPayMethod VARCHAR(50),
     
     PayCompanyId int,
     PayCompanyName VARCHAR(100),
     --费用类别
     FeeType varchar(20),
     -- 未开票金额
     UnInvoiceAmount  decimal(10,2),

     --付费开始时间
     PayPeriodBegin date,
     --付费截止时间
     PayPeriodEnd date,
     --支付主体
     VendorName varchar(100)
   )


   INSERT INTO #t
           (PayBillID, ExpectDate, ActualPayDate,
             ActualPayAmount, ActualPayeeBankName, ActualPayeeName, ActualPayeeAccountNumber, ActualPayMethod, 
             FeeType, PayPeriodBegin, PayPeriodEnd, VendorName, UnInvoiceAmount, PayCompanyId, PayCompanyName)
   select
       PB.PayBillID 
       , PP.PlanPayDate
       , PB.PayDate
       , PB.PayAmount
       , PA.AccountBank
       , PA.AccountName
       , PA.AccountNumber
       , PB.PayKind
       , PP.FeeType
       , PP.FeeBeginDate
       , PP.FeeEndDate
       , V.VendorName
       , (PB.PayAmount - PB.ReturnAmount - PB.CloseAmount)
       , C.PayCompanyId
	   , PC.PayCompanyName
   From media.tbb_paybill PB
   join media.tbb_PayPlan PP on PB.PlanPayID = PP.PlanPayID
   JOIN media.tbb_Contract C ON PP.ContractID = C.ContractID
   left join media.tbb_Vendor V on PP.VendorID = V.VendorID
   LEFT JOIN media.tbi_PayAccount PA ON PB.PayBillID = PA.PayBillID
   LEFT JOIN basic.tbb_PayCompany PC ON PC.PayCompanyID = C.PayCompanyId
   where  PP.ContractID = @FilterContractID
     and PB.ValidStatus = 0
   ORDER BY PB.PayDate, PB.PayBillID


   select @TotalCount = COUNT(*) from #T

   SELECT *
   FROM   #t T
   WHERE  T.rn > ( @PageIndex - 1 ) * @PageSize
          AND T.rn <= @PageSize * @PageIndex
   ORDER BY T.rn

   drop table #T

   set nocount off

end



























' 
END
GO
