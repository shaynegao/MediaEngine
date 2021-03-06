IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedRefundByContractID]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPagedRefundByContractID]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPagedRefundByContractID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPagedRefundByContractID] @FilterContractID   bigint,
     @PageSize             int,
     @PageIndex            int,
     @TotalCount           int output as
begin
    set nocount on
 
   create table #T
   (
     rn  int identity(1,1),
     RefundID   BIGINT,
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
     CloseAmount decimal(10,2),
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
           (RefundID, ExpectDate, ActualPayDate,
             ActualPayAmount, ActualPayeeBankName, ActualPayeeName, ActualPayeeAccountNumber, ActualPayMethod, 
             CloseAmount, FeeType, PayPeriodBegin, PayPeriodEnd, VendorName, UnInvoiceAmount, PayCompanyId, PayCompanyName)
   select
       RB.ReturnBillID
       , PP.PlanPayDate
       , RB.ReturnDate
       , RB.ReturnAmount * -1
       , RA.AccountBank
       , RA.AccountName
       , RA.AccountNumber
       , RB.ReturnKind
       , RB.CloseAmount
       , PP.FeeType
       , PP.FeeBeginDate
       , PP.FeeEndDate
       , V.VendorName
       ,(RB.ReturnAmount - RB.CloseAmount)
       , C.PayCompanyId
	   , PC.PayCompanyName
   From media.tbb_ReturnBill RB
   join media.tbb_paybill PB on RB.PayBillID = PB.PayBillID
   join media.tbb_PayPlan PP on PB.PlanPayID = PP.PlanPayID
   join media.tbb_Contract C on PP.ContractID = C.ContractID
   left join media.tbb_Vendor V on PP.VendorID = V.VendorID
   LEFT JOIN media.tbi_ReturnAccount RA ON RA.ReturnBillID = RB.ReturnBillID
   LEFT JOIN basic.tbb_PayCompany PC ON PC.PayCompanyID = C.PayCompanyId
   where PP.ContractID = @FilterContractID
     and PB.ValidStatus = 1
     AND RB.ValidStatus = 1
   ORDER BY RB.ReturnDate, RB.ReturnBillID          

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
