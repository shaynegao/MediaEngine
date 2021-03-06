IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPayableDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceGetPayableDetail]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceGetPayableDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceGetPayableDetail] @PlanPayID      bigint = null as
begin
    set nocount on

    select
    PP.PlanPayID
    -- 合同编号
    , C.ContractID
    , C.ContractCode
    -- 项目
    , C.ItemName as BuildingName
    , C.DisplayType
    -- 维护人员
    , C.DeveloperName
    , C.OperatorName
    -- 部门
    , D.DeptName as DeptName
    -- 付费主体
    , C.PayCompanyId
    -- 支付主体
	, PP.VendorID
    , V.VendorName
    -- 费用类别
    , PP.FeeType
    -- 支付金额
    , PP.PayAmount
    , PP.PaidAmount
    -- 计划支付日期
    , PP.PlanPayDate as ExpectDate
    -- 付费开始日期
    , PP.FeeBeginDate as PayPeriodBegin
    -- 付费结束日期
    , PP.FeeEndDate as PayPeriodEnd
    -- 合同状态
    , C.DealStatus as ContractStatus
    , AX.AccountID AS VendorAccountID
    -- 开户行
    , AX.AccountBank AS PayeeBankName
    -- 用户名
    , AX.AccountName AS PayeeName
    -- 账号
    , AX.AccountNumber AS PayeeAccountNumber
    -- 备注
    , PP.Memo
    , (SELECT MAX(PayBillID) FROM media.tbb_PayApply WHERE PlanPayID = @PlanPayID) as RecentScheduleID
    , PP.PayKind as PayMethod
    , PP.PayWay as PayFrequency
    , PP.CloseAmount AS CloseAmount
     from media.tbb_PayPlan PP
    join media.tbb_Contract C on PP.ContractID = C.ContractID
    LEFT JOIN basic.tbb_Department D ON C.DeptID = D.DeptID
    join media.tbb_Vendor V on V.VendorID  = PP.VendorID
    left join (
         select PPA.PlanPayID, VA.AccountID, VA.AccountBank, VA.AccountName, VA.AccountNumber
         from media.tbb_VendorAccount VA join media.tbi_PlanPayAccount PPA
            on VA.AccountID = PPA.AccountID
        ) AX on AX.PlanPayID = PP.PlanPayID

    where PP.PlanPayID = @PlanPayID
    
end
' 
END
GO
