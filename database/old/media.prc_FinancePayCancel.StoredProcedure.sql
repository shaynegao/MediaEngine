IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePayCancel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinancePayCancel]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePayCancel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinancePayCancel] @PayBillID	bigint,
 	@OperatorId bigint as
begin

	declare @Result varchar(120)
	declare @PlanPayID bigint
	declare @ValidStatus int
	declare @payBillCount int
	declare @PlanPayAmount decimal(10,2), @PlanPaidAmount decimal(10,2)
	declare @PayAmount  decimal(10,2)
	declare @ReturnAmount decimal (10, 2)
	declare @PayDate datetime
	
	declare @currentBegin datetime 
	exec [media].[prc_FinanceCurrentPeriod] @currentBegin = @currentBegin output

	
	-- 是否发票关联
	 
	-- 1. 检查付款是否存在
	if not exists (select 1 from [media].[tbb_PayBill] where PayBillID = @PayBillID)
		select @Result = ''未找到对应的付款记录''
	else
	begin
		select @PayAmount = PayAmount, @PlanPayID = PlanPayID, @ValidStatus = ValidStatus, @ReturnAmount = ReturnAmount, @PayDate = PayDate from [media].[tbb_PayBill] where PayBillID = @PayBillID
		select @PlanPayAmount = PayAmount, @PlanPaidAmount = PaidAmount from media.tbb_PayPlan where PlanPayID = @PlanPayID and ValidStatus = 1

		if @PlanPayID is null
			select @Result = ''未找到对应的应付款记录''
		else
		if @ValidStatus <> 0
			select @Result = ''付款单不是有效状态''
		else
		if @ReturnAmount > 0
			-- 是否已经有退款
			select @Result = ''请撤销退款后，再撤销付款''
		else
		if @PayDate < @currentBegin
			-- 是否过账期
			select @Result = ''已过账期''
		else	
			begin
				begin try
					BEGIN TRAN
						-- 更新付款表
						update [media].[tbb_PayBill]
						set ValidStatus = -1
							,[LastUpdateTime] = GETDATE()
						where PayBillID = @PayBillID

						update media.tbb_PayPlan
						set PaidAmount = PaidAmount - @PayAmount
						, LastUpdateTime = getdate()
						where PlanPayID = @PlanPayID
						
						-- 删除付款账户表记录 TODO
						
					COMMIT TRAN
					select @Result = ''OK''
				end try
					
				begin catch
					rollback tran
					select @Result = ''更新时发生异常''
				end catch;
			end
	end
	

    select @Result as ''Result''


end
' 
END
GO
