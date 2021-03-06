IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceRefundCancel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceRefundCancel]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceRefundCancel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'





-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-05-24   
-- Description: 退款撤销
-- Return Value:
--				OK
CREATE proc [media].[prc_FinanceRefundCancel]
	@RefundID	bigint,
	@Memo       VARCHAR(200),
	@OperatorId bigint
as
begin

	declare @Result varchar(120)
	declare @PlanPayID bigint
	declare @PayBillID bigint
	declare @AuditStatus int
	declare @payBillCount int
	declare @PlanPayAmount decimal(10,2), @PlanPaidAmount decimal(10,2)
	declare @PayAmount  decimal(10,2)
	declare @ReturnAmount decimal (10, 2)
	declare @ReturnDate datetime
	
	declare @currentBegin datetime 
	exec [media].[prc_FinanceCurrentPeriod] @currentBegin = @currentBegin output

	
	-- 是否发票关联
	 
	-- 1. 检查付款是否存在
	if not exists (select 1 from [media].[tbb_ReturnBill] where ReturnBillID = @RefundID)
		select @Result = ''未找到对应的退款记录''
	else
	begin
	
		select @PayBillID = PayBillID, @ReturnAmount = ReturnAmount, @ReturnDate = ReturnDate from [media].[tbb_ReturnBill] where ReturnBillID = @RefundID
		select @PlanPayID = PlanPayID, @AuditStatus = ValidStatus from [media].[tbb_PayBill] where PayBillID = @PayBillID
		select @PlanPayAmount = PayAmount, @PlanPaidAmount = PaidAmount from media.tbb_PayPlan where PlanPayID = @PlanPayID and ValidStatus = 1

		if @PayBillID is null
			select @Result = ''未找到对应的付款记录''
		else
		if @PlanPayID is null
			select @Result = ''未找到对应的应付款记录''
		else
		if @AuditStatus <> 0
			select @Result = ''付款单不是已付款状态''
		else
		if @ReturnAmount > 0
			-- 是否已经有退款
			select @Result = ''请撤销退款后，再撤销付款''
		else
		if @ReturnDate < @currentBegin
			-- 是否过账期
			select @Result = ''已过账期''
		else	
			begin
				begin try
					BEGIN TRAN
						-- 1. 更新退款表(逻辑删除)
						update [media].[tbb_ReturnBill]
						set ValidStatus = -1
							,[LastUpdateTime] = GETDATE()
						where ReturnBillID = @RefundID

		            -- 2. 更新付款单
				    UPDATE [media].[tbb_PayBill]
					SET [ReturnAmount] = [ReturnAmount] - @ReturnAmount
				      ,[LastUpdateTime] = getdate()
					WHERE PayBillID = @PayBillID
					
					-- 3. 更新应付单
						update media.tbb_PayPlan
						set PaidAmount = PaidAmount + @ReturnAmount
						, LastUpdateTime = getdate()
						where PlanPayID = @PlanPayID
						
						-- 删除退款账户表记录 TODO
						
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
